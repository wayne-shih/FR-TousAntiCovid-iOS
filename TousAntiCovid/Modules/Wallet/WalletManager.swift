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
            if _walletCertificates.isEmpty { reloadCertificates() }
            return _walletCertificates
        }
        set { _walletCertificates = newValue }
    }
    
    var areThereLoadedCertificates: Bool { !_walletCertificates.isEmpty }
    var recentWalletCertificates: [WalletCertificate] { walletCertificates.filter { !$0.isOld } }
    var oldWalletCertificates: [WalletCertificate] { walletCertificates.filter { $0.isOld } }
    var areThereCertificatesNeedingAttention: Bool {
        !walletCertificates.compactMap { $0 as? EuropeanCertificate }
            .first { ($0.isTestNegative == false && $0.type == .sanitaryEurope) || DccBlacklistManager.shared.isBlacklisted(certificate: $0) }
            .isNil
    }
    
    var isWalletActivated: Bool { ParametersManager.shared.displaySanitaryCertificatesWallet }
    
    var favoriteCertificate: WalletCertificate? { _walletCertificates.filter { $0.id == favoriteDccId }.first ?? loadCertificate(for: favoriteDccId) }
    
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
    }
    
    func setFavorite(certificate: WalletCertificate) {
        favoriteDccId = certificate.id
    }
    
    func removeFavorite() {
        favoriteDccId = nil
    }
    
    func saveCertificate(_ certificate: WalletCertificate) {
        storageManager.saveWalletCertificate(RawWalletCertificate(id: certificate.id, value: certificate.value))
    }
    
    func deleteCertificate(id: String) {
        storageManager.deleteWalletCertificate(id: id)
        if favoriteDccId == id { favoriteDccId = nil }
    }
    
    func clearAllData() {
        storageManager.deleteWalletCertificates()
        favoriteDccId = nil
    }
    
    func isDuplicatedCertificate(_ certificate: WalletCertificate)  -> Bool {
        (walletCertificates.first { $0.value == certificate.value } != nil)
    }
    
    private func loadCertificate(for id: String?) -> WalletCertificate? {
        storageManager.walletCertificates().filter { $0.id == id }.first.flatMap { WalletCertificate.from(rawCertificate: $0) }
    }
    
    private func reloadCertificates() {
        let loadedCertificatesDict: [String: [WalletCertificate]] = [String: [WalletCertificate]](grouping: _walletCertificates) { $0.id }
        _walletCertificates = storageManager.walletCertificates().compactMap {
            loadedCertificatesDict[$0.id]?.first ?? WalletCertificate.from(rawCertificate: $0)
        }
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(walletCertificateDataDidUpdate), name: .walletCertificateDataDidChange, object: nil)
    }
    
    @objc private func walletCertificateDataDidUpdate() {
        reloadCertificates()
        notify()
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
            return false
        }
    }
    
}

extension WalletManager {
    
    func getWalletCertificate(from url: URL) throws -> WalletCertificate {
        var certificate: WalletCertificate
        switch url.path {
        case WalletConstant.URLPath.wallet.rawValue:
            certificate = try extractCertificateFrom(url: url)
        case WalletConstant.URLPath.wallet2D.rawValue:
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
        WalletConstant.CertificateType.allCases.first { doc ~> $0.validationRegex }
    }
    
    static func certificateType(hCert: HCert) -> WalletConstant.CertificateType {
        switch hCert.type {
        case .test:
            return .sanitaryEurope
        case .vaccine:
            return .vaccinationEurope
        case .recovery:
            return .recoveryEurope
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
        guard errors.errors.isEmpty else { throw WalletError.parsing.error }
        guard let hCert = HCert(from: doc, errors: errors) else { throw WalletError.parsing.error }
        let certificateType: WalletConstant.CertificateType = WalletManager.certificateType(hCert: hCert)
        let certificate: EuropeanCertificate = EuropeanCertificate(id: id, value: doc, type: certificateType, hCert: hCert)
        guard certificate.isForeignCertificate || hCert.cryptographicallyValid else { throw WalletError.signature.error }
        return certificate
    }

}

extension WalletManager: PublicKeyStorageDelegate {

    func getEncodedPublicKeys(for kidStr: String) -> [String] {
        return DccCertificatesManager.shared.certificates(for: kidStr)
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
        InGroupeServer.shared.convertCertificate(encodedCertificate: encodedCertificate, fromFormat: certificate.type.format.rawValue, toFormat: WalletConstant.CertificateType.Format.walletDCC.rawValue) { result in
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
            InGroupeServer.shared.convertCertificateV2(encodedCertificate: encryptedCertificate.base64EncodedString(), fromFormat: certificate.type.format.rawValue, toFormat: WalletConstant.CertificateType.Format.walletDCC.rawValue, keyId: remotePublicKey.key, key: keyPair.publicKeyData.base64EncodedString()) { result in
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
    
}
