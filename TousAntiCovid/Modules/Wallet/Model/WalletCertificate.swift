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
    
    var fields: [String: String] = [:]
    
    var authority: String?
    var certificateId: String?
    var message: Data? { fatalError("Must be overriden") }
    var signature: Data? { fatalError("Must be overriden") }
    var isSignatureAlreadyEncoded: Bool { fatalError("Must be overriden") }
    
    var pillTitles: [String] { fatalError("Must be overriden") }
    var shortDescription: String { fatalError("Must be overriden") }
    var fullDescription: String { fatalError("Must be overriden") }
    
    var timestamp: Double { fatalError("Must be overriden") }
    var isOld: Bool {
        guard let oldCertificateThreshold = ParametersManager.shared.walletOldCertificateThresholdInDays(certificateType: type.rawValue) else { return false }
        return Date().timeIntervalSince1970 - timestamp >= Double(oldCertificateThreshold) * 86400.0
    }

    var validityString: String {
        let walletTestCertificateValidityThresholds: [Int] = ParametersManager.shared.walletTestCertificateValidityThresholds
        let maxValidityInHours: Int = walletTestCertificateValidityThresholds.max() ?? 0
        let timeSinceCreation: Double = Date().timeIntervalSince1970 - timestamp
        let validityThresholdInHours: Int? = walletTestCertificateValidityThresholds.filter { Double($0 * 3600) > timeSinceCreation } .min()
        return String(format: ( validityThresholdInHours == nil ? "wallet.proof.moreThanSpecificHours" : "wallet.proof.lessThanSpecificHours").localized, validityThresholdInHours ?? maxValidityInHours)
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
        case .vaccination:
            return VaccinationCertificate(id: rawCertificate.id, value: rawCertificate.value, type: certificateType, needParsing: true)
        }
    }
    
    static func from(doc: String) -> WalletCertificate? {
        guard let certificateType = WalletManager.certificateType(value: doc) else { return nil }
        switch certificateType {
        case .sanitary:
            return SanitaryCertificate(value: doc, type: certificateType, needParsing: true)
        case .vaccination:
            return VaccinationCertificate(value: doc, type: certificateType, needParsing: true)
        }
    }
    
    func toRawCertificate() -> RawWalletCertificate {
        RawWalletCertificate(id: id, value: value)
    }
    
}
