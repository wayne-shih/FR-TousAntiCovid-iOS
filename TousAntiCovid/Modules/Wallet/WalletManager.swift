// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 17/03/2021 - for the TousAntiCovid project.
//

import UIKit
import StorageSDK
import ServerSDK

protocol WalletChangesObserver: AnyObject {
    
    func walletCertificatesDidUpdate()
    func walletFavoriteCertificateDidUpdate()
    func walletActivityCertificateDidUpdate()
    func walletSmartStateDidUpdate()

}

final class WalletObserverWrapper: NSObject {
    
    weak var observer: WalletChangesObserver?
    
    init(observer: WalletChangesObserver) {
        self.observer = observer
    }

}

final class WalletManager {

    static let shared: WalletManager = WalletManager()
    var walletCertificates: [WalletCertificate] {
        get {
            let dbCertificatesCount: Int = storageManager.walletCertificates().count
            if _walletCertificates.count != dbCertificatesCount { reloadCertificates() }

            if _walletCertificates.isEmpty && dbCertificatesCount > 0 {
                StackLogger.log(symbols: Thread.callStackSymbolsString, message: "Displaying 0 certificates but having \(dbCertificatesCount) certificates in db.")
            }

            return _walletCertificates
        }
        set { _walletCertificates = newValue }
    }
    
    var lastRelevantCertificates: [EuropeanCertificate]? {
        didSet {
            // WalletState could have changed
            notifyWalletSmartState()
        }
    }
    var areThereCertificatesToLoad: Bool { _walletCertificates.count != storageManager.walletCertificates().count }
    var recentWalletCertificates: [WalletCertificate] { walletCertificates.filter { !$0.isOld } }
    var oldWalletCertificates: [WalletCertificate] { walletCertificates.filter { $0.isOld || (shouldUseSmartWallet && isPassExpired(for: $0 as? EuropeanCertificate)) } }
    var areThereCertificatesNeedingAttention: Bool {
        !walletCertificates.first {
            if let europeCertificate = $0 as? EuropeanCertificate {
                return (europeCertificate.isTestNegative == false && europeCertificate.type == .sanitaryEurope) || DccBlacklistManager.shared.isBlacklisted(certificate: europeCertificate)
            } else if $0.is2dDoc {
                return Blacklist2dDocManager.shared.isBlacklisted(certificate: $0)
            } else {
                return false
            }
        }.isNil
    }

    var isWalletActivated: Bool {
        return ParametersManager.shared.displaySanitaryCertificatesWallet
        
    }
    
    var isActivityPassActivated: Bool {
        return ParametersManager.shared.displayActivityPass
        
    }
    
    @UserDefault(key: .activityPassAutoRenewalActivated)
    var activityPassAutoRenewalActivated: Bool = false
    
    @UserDefault(key: .smartWalletActivated)
    var smartWalletActivated: Bool = true {
        didSet {
            if smartWalletActivated {
                updateLastRelevantCertificates()
            } else {
                lastRelevantCertificates = nil
            }
        }
    }
    
    // Notifications
    @UserDefault(key: .smartWalletSentNotificationsIds)
    var smartWalletSentNotificationsIds: [String] = []
    @UserDefault(key: .smartWalletLastNotificationTimestamp)
    var smartWalletLastNotificationTimestamp: Double = Date.distantPast.timeIntervalSince1970
    @UserDefault(key: .smartWalletLastNotificationCalculationTimestamp)
    var smartWalletLastNotificationCalculationTimestamp: Double = Date.distantPast.timeIntervalSince1970

    var favoriteCertificate: WalletCertificate? { _walletCertificates.filter { $0.id == favoriteDccId }.first ?? loadCertificate(for: favoriteDccId) }
    
    private(set) var isGeneratingActivityPasses: Bool = false

    @UserDefault(key: .favoriteDccId)
    private(set) var favoriteDccId: String? {
        didSet { notifyFavoriteCertificate() }
    }
    
    private var _walletCertificates: [WalletCertificate] = []
    private var observers: [WalletObserverWrapper] = []
    private var storageManager: StorageManager!
    
    func start(storageManager: StorageManager) {
        self.storageManager = storageManager
        addObservers()
        HCert.publicKeyStorageDelegate = self
        reloadCertificates()
    }
    
    func setFavorite(certificate: WalletCertificate) {
        favoriteDccId = certificate.id
    }
    
    func removeFavorite() {
        favoriteDccId = nil
    }
    
    func saveCertificate(_ certificate: WalletCertificate) {
        StackLogger.log(symbols: Thread.callStackSymbolsString, message: "Saving a certificate.")
        storageManager.saveWalletCertificate(certificate.toRawCertificate())
    }

    func deleteCertificate(id: String) {
        StackLogger.log(symbols: Thread.callStackSymbolsString, message: "Deleting a certificate.")
        storageManager.deleteWalletCertificate(id: id)
        if favoriteDccId == id { favoriteDccId = nil }
        deleteActivityCertificates(parentId: id)
    }
    
    func clearAllData() {
        StackLogger.log(symbols: Thread.callStackSymbolsString, message: "Deleting all certificates.")
        storageManager.deleteWalletCertificates()
        favoriteDccId = nil
    }

    func isDuplicatedCertificate(_ certificate: WalletCertificate)  -> Bool {
        walletCertificates.first { $0.uniqueHash == certificate.uniqueHash } != nil
    }

    func activityCertificateFor(certificate: EuropeanCertificate?) -> ActivityCertificate? {
        guard let certificate = certificate else { return nil }
        guard let rawActivityCertificate = getSortedRawActivityCertificatesFor(certificate: certificate).first else { return nil }
        return WalletCertificate.from(rawCertificate: rawActivityCertificate) as? ActivityCertificate
    }

    func activityCertificateIdFor(certificate: EuropeanCertificate?) -> String? {
        guard let certificate = certificate else { return nil }
        return getSortedRawActivityCertificatesFor(certificate: certificate).first?.id
    }

    func deleteActivityCertificates(parentId: String, notify: Bool = true) {
        let activityCertificatesIds: [String] = storageManager.walletCertificates().filter { $0.parentId == parentId }.map { $0.id }
        storageManager.deleteWalletCertificates(ids: activityCertificatesIds)
        if notify { notifyActivityCertificate() }
    }

    func updateLastRelevantCertificates() {
        lastRelevantCertificates = getLastRelevantCertificates()
    }

    private func getSortedRawActivityCertificatesFor(certificate: EuropeanCertificate) -> [RawWalletCertificate] {
        let now: Date = Date()
        return storageManager.walletCertificates().filter({ $0.parentId == certificate.id && $0.expiryDate ?? .distantPast > now }).sorted { $0.expiryDate ?? .distantPast < $1.expiryDate ?? .distantPast }
    }

    private func loadCertificate(for id: String?) -> WalletCertificate? {
        guard let certificate = storageManager.walletCertificates().filter({ $0.id == id }).first.flatMap({ WalletCertificate.from(rawCertificate: $0) }) else { return nil }
        _walletCertificates.append(certificate)
        return certificate
    }

    private func reloadCertificates(forceReloadFor forcedIds: [String] = []) {
        let loadedCertificatesDict: [String: [WalletCertificate]] = [String: [WalletCertificate]](grouping: _walletCertificates) { $0.id }
        _walletCertificates = storageManager.walletCertificates().compactMap {
            guard $0.parentId == nil else { return nil }
            // Only ActivityCertificates will have a parentId and we want to ignore them when loading the certificates for the wallet (optimization due to the cost of a DCC parsing). Activity certificates will be loaded when we need to display them.
            if forcedIds.contains($0.id) {
                return WalletCertificate.from(rawCertificate: $0)
            } else {
                return loadedCertificatesDict[$0.id]?.first ?? WalletCertificate.from(rawCertificate: $0)
            }
        }
        updateLastRelevantCertificates()
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(walletCertificateDataDidUpdate), name: .walletCertificateDataDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func walletCertificateDataDidUpdate() {
        reloadCertificates()
        notify()
    }

    @objc private func appDidBecomeActive() {
        processActivityCertificatesUpdatesAndCleaning()
    }
    
    private func checkCertificateSignature(_ certificate: WalletCertificate) -> Bool {
        guard let publicKey = certificate.publicKey?.cleaningPEMStrings() else { return false }
        guard let publicKeyData = Data(base64Encoded: publicKey) else { return false }
        guard let messageData = certificate.message else { return false }
        guard let rawSignatureData = certificate.signature else { return false }
        do {
            let publicSecKey: SecKey = try SecKey.publicKeyfromDerData(publicKeyData)
            let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256
            let canVerify: Bool = SecKeyIsAlgorithmSupported(publicSecKey, .verify, algorithm)
            guard canVerify else { return false }
            
            let encodedSignatureData: Data = certificate.isSignatureAlreadyEncoded ? rawSignatureData : try rawSignatureData.derEncodedSignature()
            
            var error: Unmanaged<CFError>?
            let isSignatureValid: Bool = SecKeyVerifySignature(publicSecKey,
                                                               algorithm,
                                                               messageData as CFData,
                                                               encodedSignatureData as CFData,
                                                               &error)
            return isSignatureValid
        } catch {
            print(error)
            return false
        }
    }

}

extension WalletManager {
    
    func getWalletCertificate(from url: URL) throws -> WalletCertificate {
        var certificate: WalletCertificate
        switch url.path {
        case WalletConstant.URLPath.wallet.rawValue,
             WalletConstant.URLPath.wallet2D.rawValue:
            certificate = try extractCertificateFrom(url: url)
        case WalletConstant.URLPath.walletDCC.rawValue:
            if DeepLinkingManager.shared.isComboDeeplink(url),
               let certificatStringUrl = url.absoluteString.components(separatedBy: WalletConstant.Separator.declareCode.rawValue).first,
               let certificatUrl = URL(string: certificatStringUrl) {
                certificate = try extractEuropeanCertificateFrom(url: certificatUrl)
            } else {
                certificate = try extractEuropeanCertificateFrom(url: url)
            }
        default:
            throw WalletError.parsing.error
        }
        return certificate
    }
}

extension WalletManager {
    
    static func certificateType(doc: String) -> WalletConstant.CertificateType? {
        [WalletConstant.CertificateType.sanitary, WalletConstant.CertificateType.vaccination].first { doc ~> $0.validationRegex }
    }
    
    static func certificateType(hCert: HCert) -> WalletConstant.CertificateType {
        switch hCert.type {
        case .test:
            return .sanitaryEurope
        case .vaccine:
            return .vaccinationEurope
        case .recovery:
            return .recoveryEurope
        case .exemption:
            return .exemptionEurope
        case .unknown:
            return .unknown
        }
    }
    
    static func certificateTypeFromHeaderInUrl(_ url: URL) -> WalletConstant.CertificateType? {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        guard let completeMessage = urlComponents.queryItems?.first(where: { $0.name == "v" })?.value ?? urlComponents.fragment else { return nil }
        switch urlComponents.path {
        case WalletConstant.URLPath.wallet.rawValue, WalletConstant.URLPath.wallet2D.rawValue:
            return WalletConstant.CertificateType.allCases.first { completeMessage ~> $0.headerDetectionRegex }
        case WalletConstant.URLPath.walletDCC.rawValue:
            guard let hCert = HCert(from: completeMessage) else { return nil }
            return certificateType(hCert: hCert)
        default:
            return nil
        }
    }

}

extension WalletManager {

    @discardableResult
    func extractCertificateFrom(url: URL) throws -> WalletCertificate {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw WalletError.parsing.error }
        guard let completeMessage = urlComponents.queryItems?.first(where: { $0.name == "v" })?.value ?? urlComponents.fragment else { throw WalletError.parsing.error }
        return try extractCertificateFrom(doc: completeMessage)
    }

    func extractCertificateFrom(doc: String) throws -> WalletCertificate {
        guard let certificate = WalletCertificate.from(doc: doc) else { throw WalletError.parsing.error }
        guard checkCertificateSignature(certificate) else { throw WalletError.signature.error }
        return certificate
    }

    @discardableResult
    func extractEuropeanCertificateFrom(url: URL) throws -> WalletCertificate {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw WalletError.parsing.error }
        guard let completeMessage = urlComponents.fragment else { throw WalletError.parsing.error }
        return try extractEuropeanCertificateFrom(doc: completeMessage)
    }

    func extractEuropeanCertificateFrom(id: String = UUID().uuidString, doc: String) throws -> EuropeanCertificate {
        let errors: HCert.ParseErrors = HCert.ParseErrors()
        guard let hCert = HCert(from: doc, errors: errors) else { throw WalletError.parsing.error }
        let certificateType: WalletConstant.CertificateType = WalletManager.certificateType(hCert: hCert)
        guard certificateType != .unknown else { throw WalletError.parsing.error }
        let certificate: EuropeanCertificate = EuropeanCertificate(id: id, value: doc, type: certificateType, hCert: hCert, didGenerateAllActivityCertificates: false, didAlreadyGenerateActivityCertificates: false)
        guard certificate.isForeignCertificate || hCert.cryptographicallyValid else { throw WalletError.signature.error }
        return certificate
    }

    func extractActivityCertificateFrom(id: String = UUID().uuidString, doc: String, parentId: String) throws -> ActivityCertificate {
        let errors: HCert.ParseErrors = HCert.ParseErrors()
        guard let hCert = HCert(from: doc, errors: errors) else { throw WalletError.parsing.error }
        let certificate: ActivityCertificate = ActivityCertificate(id: id, value: doc, hCert: hCert, parentId: parentId)
        guard hCert.cryptographicallyValid else { throw WalletError.signature.error }
        return certificate
    }

}

extension WalletManager: PublicKeyStorageDelegate {

    func getEncodedPublicKeys(for kidStr: String) -> [String] {
        DccCertificatesManager.shared.certificates(for: kidStr).map {
            if $0.hasPrefix("-----BEGIN PUBLIC KEY-----") {
                return $0
            } else {
                return "-----BEGIN PUBLIC KEY-----" + $0 + "-----END PUBLIC KEY-----"
            }
        }
    }

}

extension WalletManager {

    func convertToEurope(certificate: WalletCertificate, completion: @escaping (_ result: Result<EuropeanCertificate, Error>) -> ()) {
        switch ParametersManager.shared.walletConversionApiVersion {
        case 2:
            convertToEuropeV2(certificate: certificate, completion: completion)
        default:
            convertToEuropeV1(certificate: certificate, completion: completion)
        }
    }

    private func convertToEuropeV1(certificate: WalletCertificate, completion: @escaping (_ result: Result<EuropeanCertificate, Error>) -> ()) {
        let encodedCertificate: String = certificate.value.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? certificate.value
        ConversionServer.shared.convertCertificate(encodedCertificate: encodedCertificate, fromFormat: certificate.type.format.rawValue, toFormat: WalletConstant.CertificateType.Format.walletDCC.rawValue) { result in
            switch result {
            case let .success(doc):
                do {
                    let europeanCertificate: EuropeanCertificate = try self.extractEuropeanCertificateFrom(doc: doc)
                    self.saveCertificate(europeanCertificate)
                    self.deleteCertificate(id: certificate.id)
                    completion(.success(europeanCertificate))
                } catch {
                    completion(.failure(error))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func convertToEuropeV2(certificate: WalletCertificate, completion: @escaping (_ result: Result<EuropeanCertificate, Error>) -> ()) {
        do {
            guard let remotePublicKey = ParametersManager.shared.walletConversionPublicKey else {
                completion(.failure(NSError.localizedError(message: "Server public key not found", code: 0)))
                return
            }
            guard let remotePublicKeyData = Data(base64Encoded: remotePublicKey.value) else {
                completion(.failure(NSError.localizedError(message: "Server public key not properly formatted", code: 0)))
                return
            }
            let keyPair: CryptoKeyPair = try Crypto.generateKeys()
            let sharedSecret: Data = try Crypto.generateSecret(localPrivateKey: keyPair.privateKey, remotePublicKey: remotePublicKeyData)
            let encryptionKey: Data = try Crypto.generateConversionEncryptionKey(sharedSecret: sharedSecret)
            let encryptedCertificate: Data = try Crypto.encrypt(certificate.value, key: encryptionKey)
            ConversionServer.shared.convertCertificateV2(encodedCertificate: encryptedCertificate.base64EncodedString(), fromFormat: certificate.type.format.rawValue, toFormat: WalletConstant.CertificateType.Format.walletDCC.rawValue, keyId: remotePublicKey.key, key: keyPair.publicKeyData.base64EncodedString()) { result in
                switch result {
                case let .success(docBase64):
                    do {
                        let doc: String = try Crypto.decrypt(docBase64, key: encryptionKey)
                        let europeanCertificate: EuropeanCertificate = try self.extractEuropeanCertificateFrom(doc: doc)
                        self.saveCertificate(europeanCertificate)
                        self.deleteCertificate(id: certificate.id)
                        completion(.success(europeanCertificate))
                    } catch {
                        completion(.failure(error))
                    }
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
}

// MARK: - Activity certificate -
extension WalletManager {

    func generateActivityDccFrom(certificate: WalletCertificate, completion: ((_ error: Error?) -> ())?) {
        do {
            guard let remotePublicKey = ParametersManager.shared.activityPassGenerationServerPublicKey else {
                completion?(NSError.localizedError(message: "Server public key not found", code: 0))
                return
            }
            guard let remotePublicKeyData = Data(base64Encoded: remotePublicKey) else {
                completion?(NSError.localizedError(message: "Server public key not properly formatted", code: 0))
                return
            }
            let keyPair: CryptoKeyPair = try Crypto.generateKeys()
            let sharedSecret: Data = try Crypto.generateSecret(localPrivateKey: keyPair.privateKey, remotePublicKey: remotePublicKeyData)
            let encryptionKey: Data = try Crypto.generateConversionEncryptionKey(sharedSecret: sharedSecret)
            let encryptedCertificate: Data = try Crypto.encrypt(certificate.value, key: encryptionKey)
            isGeneratingActivityPasses = true
            ActivityCertificateServer.shared.generateLightDcc(encodedCertificate: encryptedCertificate.base64EncodedString(), publicKey: keyPair.publicKeyData.base64EncodedString()) { result in
                switch result {
                case let .success(base64EncryptedResponse):
                    do {
                        let responseJson: String = try Crypto.decrypt(base64EncryptedResponse, key: encryptionKey)
                        guard let responseData = responseJson.data(using: .utf8) else {
                            self.isGeneratingActivityPasses = false
                            completion?(NSError.localizedError(message: "Unable to parse server response", code: 0))
                            return
                        }
                        let response: TransformDocumentResponseContent = try JSONDecoder().decode(TransformDocumentResponseContent.self, from: responseData)
                        // Here we check if we can parse the first certificate and check its signature. If it is ok, the whole "batch" is ok.
                        _ = try response.lightCertificates.first.map { try self.extractActivityCertificateFrom(doc: $0.dcc, parentId: certificate.id) }
                        let rawCertificates: [RawWalletCertificate] = response.lightCertificates.map {
                            RawWalletCertificate(value: $0.dcc,
                                                 expiryDate: Date(timeIntervalSince1970: Double($0.exp)),
                                                 parentId: certificate.id)
                        }
                        self.deleteActivityCertificates(parentId: certificate.id, notify: false)
                        self.storageManager.saveWalletCertificates(rawCertificates)
                        if let certificate = certificate as? EuropeanCertificate {
                            var didUpdateCertificate: Bool = false
                            if !certificate.didAlreadyGenerateActivityCertificates {
                                certificate.didAlreadyGenerateActivityCertificates = true
                                didUpdateCertificate = true
                            }
                            if response.complete {
                                certificate.didGenerateAllActivityCertificates = true
                                didUpdateCertificate = true
                            }
                            if didUpdateCertificate {
                                self.storageManager.saveWalletCertificate(certificate.toRawCertificate())
                                self.reloadCertificates(forceReloadFor: [certificate.id])
                                self.notify()
                            }
                        }
                        self.notifyActivityCertificate()
                        self.isGeneratingActivityPasses = false
                        completion?(nil)
                    } catch {
                        self.isGeneratingActivityPasses = false
                        completion?(error)
                    }
                case let .failure(error):
                    AnalyticsManager.shared.reportError(serviceName: "dcclight", code: (error as NSError).code)
                    self.isGeneratingActivityPasses = false
                    completion?(error)
                }
            }
        } catch {
            completion?(error)
        }
    }

    private func processActivityCertificatesUpdatesAndCleaning() {
        clearBlackListedDccActivityCertificates()
        clearRevokedActivityCertificates {
            self.renewDccActivityCertificatesWhenNeeded {
                self.clearExpiredActivityCertificates()
                self.notifyActivityCertificate()
            }
        }
    }

    private func clearBlackListedDccActivityCertificates() {
        let blacklistedCertificates: [WalletCertificate] = walletCertificates.filter { DccBlacklistManager.shared.isBlacklisted(certificate: $0) }
        blacklistedCertificates.forEach { deleteActivityCertificates(parentId: $0.id, notify: false) }
    }

    private func clearExpiredActivityCertificates() {
        let now: Date = Date()
        let expiredActivityCertificates: [RawWalletCertificate] = storageManager.walletCertificates().filter {
            guard $0.parentId != nil else { return false }
            return $0.expiryDate ?? .distantPast <= now
        }
        storageManager.deleteWalletCertificates(ids: expiredActivityCertificates.map { $0.id })
    }

    private func renewDccActivityCertificatesWhenNeeded(_ completion: (() -> ())? = nil) {
        let dispatchGroup: DispatchGroup = DispatchGroup()
        walletCertificates
            .compactMap { $0 as? EuropeanCertificate }
            .filter {
                let isBlackListed: Bool = DccBlacklistManager.shared.isBlacklisted(certificate: $0)
                let isEligible: Bool = !$0.didGenerateAllActivityCertificates
                let remainingActivityCertificatesCount: Int = getSortedRawActivityCertificatesFor(certificate: $0).count
                let matchesRenewThreshold: Bool = remainingActivityCertificatesCount <= ParametersManager.shared.activityPassRenewThreshold
                let canAutoGenerate: Bool = ParametersManager.shared.activityPassAutoRenewable && activityPassAutoRenewalActivated
                return !isBlackListed && isEligible && matchesRenewThreshold && ($0.didAlreadyGenerateActivityCertificates || canAutoGenerate)
            }
            .forEach {
                dispatchGroup.enter()
                generateActivityDccFrom(certificate: $0) { _ in dispatchGroup.leave() }
            }
        dispatchGroup.notify(queue: .main) { completion?() }
    }

    private func clearRevokedActivityCertificates(_ completion: (() -> ())? = nil) {
        let dispatchGroup: DispatchGroup = DispatchGroup()
        let certificatesForActivityRevokation: [EuropeanCertificate] = walletCertificates
            .compactMap { $0 as? EuropeanCertificate }
            .filter { europeanCertificate in
                guard let rawActivityCertificate = storageManager.walletCertificates().filter({ $0.parentId == europeanCertificate.id }).first else { return false }
                guard let activityCertificate = WalletCertificate.from(rawCertificate: rawActivityCertificate) as? ActivityCertificate else { return false }
                return DccCertificatesManager.shared.certificates(for: activityCertificate.kid).isEmpty
            }
        certificatesForActivityRevokation.forEach {
            deleteActivityCertificates(parentId: $0.id, notify: false)
            dispatchGroup.enter()
            generateActivityDccFrom(certificate: $0) { _ in dispatchGroup.leave() }
        }
        dispatchGroup.notify(queue: .main) { completion?() }
    }

}

// MARK: - Smart wallet
extension WalletManager {
    func getLastRelevantCertificates() -> [EuropeanCertificate]? {
        // user only for EuropeanCertificates
        let europeanCertificates: [EuropeanCertificate] = _walletCertificates.filter { ($0 as? EuropeanCertificate)?.hasLunarBirthdate == false } as? [EuropeanCertificate] ?? []
        // group certificates by user (on firstname and birthdate only)
        let groupedCerts: [String: [EuropeanCertificate]] = Dictionary(grouping: europeanCertificates) { "\($0.firstname.uppercased())\($0.birthdate)" }
        // keep only the last relevant certificate: completed vaccine or recovery.
        return groupedCerts.compactMap {
            $0.value
                .filter { ($0.isLastDose == true || $0.type == .recoveryEurope || $0.isTestNegative == false) && !$0.isExpired }
                .sorted(by: { $0.alignedTimestamp > $1.alignedTimestamp })
                .first
        }
    }
}

extension WalletManager {

    func addObserver(_ observer: WalletChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(WalletObserverWrapper(observer: observer))
    }

    func removeObserver(_ observer: WalletChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }

    private func observerWrapper(for observer: WalletChangesObserver) -> WalletObserverWrapper? {
        observers.first { $0.observer === observer }
    }

    private func notify() {
        observers.forEach { $0.observer?.walletCertificatesDidUpdate() }
    }
    
    private func notifyFavoriteCertificate() {
        observers.forEach { $0.observer?.walletFavoriteCertificateDidUpdate() }
    }

    private func notifyActivityCertificate() {
        observers.forEach { $0.observer?.walletActivityCertificateDidUpdate() }
    }
    
    private func notifyWalletSmartState() {
        observers.forEach { $0.observer?.walletSmartStateDidUpdate() }
    }
}
