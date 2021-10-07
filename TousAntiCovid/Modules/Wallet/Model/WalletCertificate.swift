// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletCertificate.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/03/2021 - for the TousAntiCovid project.
//

import ServerSDK
import StorageSDK
import UIKit

class WalletCertificate {
    
    let id: String
    let value: String
    let type: WalletConstant.CertificateType
    
    var fields: [String: String] = [:]
    
    var authority: String?
    var certificateId: String?
    var parentId: String?
    var message: Data? { fatalError("Must be overriden") }
    var signature: Data? { fatalError("Must be overriden") }
    var isSignatureAlreadyEncoded: Bool { fatalError("Must be overriden") }

    var pillTitles: [(text: String, backgroundColor: UIColor)] { fatalError("Must be overriden") }
    var shortDescription: String? { fatalError("Must be overriden") }
    var fullDescription: String? { fatalError("Must be overriden") }
    var fullDescriptionForFullscreen: String? { fatalError("Must be overriden") }
    
    var timestamp: Double { fatalError("Must be overriden") }

    var is2dDoc: Bool { type.format == .wallet2DDoc }

    var codeImageTitle: String? {
        switch type.format {
        case .wallet2DDoc:
            return "2D-DOC"
        case .walletDCC, .walletDCCACT:
            return nil
        }
    }

    var codeImage: UIImage? {
        switch type.format {
        case .wallet2DDoc:
            return value.dataMatrix()
        case .walletDCC, .walletDCCACT:
            return value.qrCode()
        }
    }

    var uniqueHash: String? { message?.sha256() }

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
    
    init(id: String = UUID().uuidString, value: String, type: WalletConstant.CertificateType) {
        self.id = id
        self.value = value
        self.type = type
    }

    func toRawCertificate() -> RawWalletCertificate {
        RawWalletCertificate(id: id, value: value, expiryDate: nil, parentId: parentId, didGenerateAllActivityCertificates: false)
    }
    
}

extension WalletCertificate {

    static func from(rawCertificate: RawWalletCertificate) -> WalletCertificate? {
        if let certificateType = WalletManager.certificateType(doc: rawCertificate.value) {
            switch certificateType {
            case .sanitary:
                return SanitaryCertificate(id: rawCertificate.id, value: rawCertificate.value, type: certificateType)
            case .vaccination:
                return VaccinationCertificate(id: rawCertificate.id, value: rawCertificate.value, type: certificateType)
            default:
                return nil
            }
        } else if let hCert = HCert(from: rawCertificate.value) {
            if let parentId = rawCertificate.parentId {
                return ActivityCertificate(id: rawCertificate.id,
                                           value: rawCertificate.value,
                                           hCert: hCert,
                                           parentId: parentId)
            } else {
                return EuropeanCertificate(id: rawCertificate.id,
                                           value: rawCertificate.value,
                                           type: WalletManager.certificateType(hCert: hCert),
                                           hCert: hCert,
                                           didGenerateAllActivityCertificates: rawCertificate.didGenerateAllActivityCertificates,
                                           didAlreadyGenerateActivityCertificates: rawCertificate.didAlreadyGenerateActivityCertificates)
            }
        } else {
            return nil
        }
    }

    static func from(doc: String) -> WalletCertificate? {
        guard let certificateType = WalletManager.certificateType(doc: doc) else { return nil }
        switch certificateType {
        case .sanitary:
            return SanitaryCertificate(value: doc, type: certificateType)
        case .vaccination:
            return VaccinationCertificate(value: doc, type: certificateType)
        default:
            return nil
        }
    }

}
