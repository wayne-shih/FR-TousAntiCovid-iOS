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

protocol WalletChangesObserver: class {
    
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
    var walletCertificates: [WalletCertificate] { storageManager.walletCertificates().compactMap { WalletCertificate.from(rawCertificate: $0) } }
    var walletCertificatesEmpty: Bool { storageManager.walletCertificates().isEmpty }
    
    var isWalletActivated: Bool {
        ParametersManager.shared.displaySanitaryCertificatesWallet
    }
    
    private var observers: [WalletObserverWrapper] = []
    private var storageManager: StorageManager!
    
    static func certificateType(value: String) -> WalletConstant.CertificateType? {
        var type: WalletConstant.CertificateType?
        WalletConstant.CertificateType.allCases.forEach {
            guard value ~= $0.validationRegex else { return }
            type = $0
        }
        return type
    }
    
    func start(storageManager: StorageManager) {
        self.storageManager = storageManager
        addObservers()
    }
    
    func deleteCertificate(id: String) {
        storageManager.deleteWalletCertificate(id: id)
    }
    
    func clearAllData() {
        storageManager.deleteWalletCertificates()
    }
    
    func isCertificateUrlValid(_ url: URL) -> Bool {
        do {
            try extractCertificateFrom(url: url)
            return true
        } catch {
            return false
        }
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(walletCertificateDataDidUpdate), name: .walletCertificateDataDidChange, object: nil)
    }
    
    @objc private func walletCertificateDataDidUpdate() {
        notifyObservers()
    }
    
    func processWalletUrl(_ url: URL) throws {
        let certificate: WalletCertificate = try extractCertificateFrom(url: url)
        saveCertificate(certificate)
    }
    
    func extractCertificateFrom(doc: String) throws -> WalletCertificate {
        guard let certificate = WalletCertificate.from(doc: doc) else { throw WalletError.parsing.error }
        guard checkCertificateSignature(certificate) else { throw WalletError.signature.error }
        return certificate
    }
    
    @discardableResult
    func extractCertificateFrom(url: URL) throws -> WalletCertificate {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw WalletError.parsing.error }
        guard let completeMessage = urlComponents.queryItems?.first(where: { $0.name == "v" })?.value else { throw WalletError.parsing.error }
        return try extractCertificateFrom(doc: completeMessage)
    }
    
    func saveCertificate(_ certificate: WalletCertificate) {
        storageManager.saveWalletCertificate(RawWalletCertificate(id: certificate.id, value: certificate.value))
        AnalyticsManager.shared.reportAppEvent(.e13)
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
            
            let encodedSignatureData: Data = try rawSignatureData.derEncodedSignature()
            
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
