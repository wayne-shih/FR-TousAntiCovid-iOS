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
    
    var isWalletActivated: Bool { ParametersManager.shared.displaySanitaryCertificatesWallet }

    private var _walletCertificates: [WalletCertificate] = []
    private var observers: [WalletObserverWrapper] = []
    private var storageManager: StorageManager!
    
    func start(storageManager: StorageManager) {
        self.storageManager = storageManager
        addObservers()
        HCert.publicKeyStorageDelegate = self
    }

    func saveCertificate(_ certificate: WalletCertificate) {
        storageManager.saveWalletCertificate(RawWalletCertificate(id: certificate.id, value: certificate.value))
        AnalyticsManager.shared.reportAppEvent(.e13)
    }
    
    func deleteCertificate(id: String) {
        storageManager.deleteWalletCertificate(id: id)
    }
    
    func clearAllData() {
        storageManager.deleteWalletCertificates()
    }

    func deeplinkForCode(_ code: String) -> String {
        if URL(string: code) != nil {
            return code
        } else {
            // In this case it means we scanned a raw DCC certificate.
            let encodedCode: String = code.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? ""
            return "https://bonjour.tousanticovid.gouv.fr\(WalletConstant.URLPath.walletDCC.rawValue)#" + encodedCode
        }
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
        notifyObservers()
    }
    
    private func checkCertificateSignature(_ certificate: WalletCertificate) -> Bool {
        guard let publicKey = certificate.publicKey?.cleaningPEMStrings() else { return false }
        guard let publicKeyData = Data(base64Encoded: publicKey) else { return false }
        guard let messageData = certificate.message else { return false }
        guard let rawSignatureData = certificate.signature else { return false }
        do {
            let publicSecKey: SecKey = try SecKey.publicKeyfromDer(data: publicKeyData)
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

    func processUrl(_ url: URL) throws {
        switch url.path {
        case WalletConstant.URLPath.wallet.rawValue:
            try processWalletUrl(url)
        case WalletConstant.URLPath.wallet2D.rawValue:
            try processWallet2DUrl(url)
        case WalletConstant.URLPath.walletDCC.rawValue:
            try processWalletDCCUrl(url)
        default:
            break
        }
    }

    func processWalletUrl(_ url: URL) throws {
        let certificate: WalletCertificate = try extractCertificateFrom(url: url)
        saveCertificate(certificate)
    }

    func processWallet2DUrl(_ url: URL) throws {
        let certificate: WalletCertificate = try extractCertificateFrom(url: url)
        saveCertificate(certificate)
    }

    func processWalletDCCUrl(_ url: URL) throws {
        let certificate: WalletCertificate = try extractEuropeanCertificateFrom(url: url)
        saveCertificate(certificate)
    }

}

extension WalletManager {

    static func certificateType(doc: String) -> WalletConstant.CertificateType? {
        WalletConstant.CertificateType.allCases.first { doc ~= $0.validationRegex }
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
            return WalletConstant.CertificateType.allCases.first { completeMessage ~= $0.headerDetectionRegex }
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

    func extractEuropeanCertificateFrom(doc: String) throws -> WalletCertificate {
        let errors: HCert.ParseErrors = HCert.ParseErrors()
        guard let hCert = HCert(from: doc, errors: errors) else { throw WalletError.parsing.error }
        guard errors.errors.isEmpty else { throw WalletError.parsing.error }
        guard hCert.cryptographicallyValid else { throw WalletError.signature.error }
        let certificateType: WalletConstant.CertificateType = WalletManager.certificateType(hCert: hCert)
        return EuropeanCertificate(value: doc, type: certificateType, hCert: hCert)
    }

}

extension WalletManager: PublicKeyStorageDelegate {

    func getEncodedPublicKeys(for kidStr: String) -> [String] {
        DccCertificatesManager.shared.certificates(for: kidStr)
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
    
    private func notifyObservers() {
        observers.forEach { $0.observer?.walletCertificatesDidUpdate() }
    }
    
}
