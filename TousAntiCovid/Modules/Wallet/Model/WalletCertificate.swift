// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletCertificate.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/03/2021 - for the TousAntiCovid project.
//

import Foundation
import ServerSDK
import StorageSDK

class WalletCertificate {
    
    let id: String
    let value: String
    let type: WalletConstant.CertificateType
    
    var header: String = ""
    var fields: [String: String] = [:]
    
    var authority: String?
    var certificateId: String?
    var message: Data? { fatalError("Must be overriden") }
    var signature: Data? { fatalError("Must be overriden") }
    
    var pillTitle: String { fatalError("Must be overriden") }
    var shortDescription: String { fatalError("Must be overriden") }
    var fullDescription: String { fatalError("Must be overriden") }
    
    var timestamp: Double { fatalError("Must be overriden") }
    var isOld: Bool {
        Date().timeIntervalSince1970 - timestamp >= Double(ParametersManager.shared.walletOldCertificateThresholdInDays(certificateType: type.rawValue)) * 86400.0
    }
    var isStillValid: Bool {
        Date().timeIntervalSince1970 - timestamp < Double(ParametersManager.shared.walletTestCertificateValidityThresholdInHours) * 3600.0
    }
    var validityString: String {
        String(format: (isStillValid ? "wallet.proof.lessThanSpecificHours" : "wallet.proof.moreThanSpecificHours").localized, ParametersManager.shared.walletTestCertificateValidityThresholdInHours)
    }
    var publicKey: String? {
        guard let authority = authority else { return nil }
        guard let certificateId = certificateId else { return nil }
        return ParametersManager.shared.walletPublicKey(authority: authority, certificateId: certificateId)
    }
    
    init(id: String = UUID().uuidString, value: String, type: WalletConstant.CertificateType, needParsing: Bool = false) {
        self.id = id
        self.value = value
        self.type = type
        guard needParsing else { return }
        self.fields = parse(value)
    }
    
    func parse(_ value: String) -> [String: String] { fatalError("Must be overriden") }
    
}

extension WalletCertificate {
    
    static func from(rawCertificate: RawWalletCertificate) -> WalletCertificate? {
        guard let certificateType = WalletManager.certificateType(value: rawCertificate.value) else { return nil }
        switch certificateType {
        case .sanitary:
            return SanitaryCertificate(id: rawCertificate.id, value: rawCertificate.value, type: certificateType, needParsing: true)
        }
    }
    
    static func from(doc: String) -> WalletCertificate? {
        guard let certificateType = WalletManager.certificateType(value: doc) else { return nil }
        switch certificateType {
        case .sanitary:
            return SanitaryCertificate(value: doc, type: certificateType, needParsing: true)
        }
    }
    
    func toRawCertificate() -> RawWalletCertificate {
        RawWalletCertificate(id: id, value: value)
    }
    
}
