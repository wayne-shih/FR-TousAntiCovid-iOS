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
    var title: String? { fatalError("Must be overriden") }
    var shortDescription: String? { fatalError("Must be overriden") }
    var shortDescriptionForList: String? { shortDescription }
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

    var publicKey: String? {
        guard let authority = authority else { return nil }
        guard let certificateId = certificateId else { return nil }
        return ParametersManager.shared.walletPublicKey(authority: authority, certificateId: certificateId)
    }
    
    var additionalInfo: [AdditionalInfo] { getAdditionalInfo() }
    
    init(id: String = UUID().uuidString, value: String, type: WalletConstant.CertificateType) {
        self.id = id
        self.value = value
        self.type = type
    }

    func toRawCertificate() -> RawWalletCertificate {
        RawWalletCertificate(id: id, value: value, expiryDate: nil, parentId: parentId, didGenerateAllActivityCertificates: false)
    }

    func validityString(forceEnglish: Bool) -> String {
        let walletTestCertificateValidityThresholds: [Int] = ParametersManager.shared.walletTestCertificateValidityThresholds
        let maxValidityInHours: Int = walletTestCertificateValidityThresholds.max() ?? 0
        let timeSinceCreation: Double = Date().timeIntervalSince1970 - timestamp
        let validityThresholdInHours: Int? = walletTestCertificateValidityThresholds.filter { Double($0 * 3600) > timeSinceCreation } .min()
        if forceEnglish {
            return String(format: ( validityThresholdInHours == nil ? "wallet.proof.englishDescription.moreThanSpecificHours" : "wallet.proof.englishDescription.lessThanSpecificHours").localized, validityThresholdInHours ?? maxValidityInHours)
        } else {
            return String(format: ( validityThresholdInHours == nil ? "wallet.proof.moreThanSpecificHours" : "wallet.proof.lessThanSpecificHours").localized, validityThresholdInHours ?? maxValidityInHours)
        }
    }
    
    func getAdditionalInfo() -> [AdditionalInfo] {
        if DccBlacklistManager.shared.isBlacklisted(certificate: self) || Blacklist2dDocManager.shared.isBlacklisted(certificate: self) {
            return [AdditionalInfo(category: .warning, fullDescription: "wallet.blacklist.warning".localized)]
        } else {
            return []
        }
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
            if hCert.prefix == WalletConstant.DccPrefix.activityCertificate.rawValue {
                return ActivityCertificate(id: rawCertificate.id,
                                           value: rawCertificate.value,
                                           hCert: hCert,
                                           parentId: rawCertificate.parentId)
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

extension Array where Element == AdditionalInfo {
    var warnings: [Element] { filter { $0.category == .warning } }
    var info: [Element] { filter { $0.category == .info } }
    var errors: [Element] { filter { $0.category == .error } }
}
