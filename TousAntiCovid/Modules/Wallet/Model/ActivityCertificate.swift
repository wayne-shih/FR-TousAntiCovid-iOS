// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ActivityCertificate.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 16/08/2021 - for the TousAntiCovid project.
//

import UIKit
import StorageSDK

final class ActivityCertificate: WalletCertificate {

    override var shortDescription: String? { fullName }

    var startDate: Date { hCert.iat }
    var endDate: Date { hCert.exp }

    var isValid: Bool {
        let now: Date = Date()
        return startDate <= now && endDate > now
    }
    var kid: String { hCert.kidStr }
    var firstname: String? { hCert.get(.firstName).string ?? hCert.get(.firstNameStandardized).string }
    var lastname: String? { hCert.get(.lastName).string ?? hCert.get(.lastNameStandardized).string }
    var fullName: String { [firstname, lastname].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.joined(separator: " ") }
    
    override var isOld: Bool {
        let parentIsOld: Bool = super.isOld
        return parentIsOld || isExpired
    }
    override var uniqueHash: String { hCert.uvci.sha256() }
    override var timestamp: Double { startDate.timeIntervalSince1970 }
    override var title: String? {
        switch type {
        case .multiPass:
            return "wallet.proof.multiPass.title".localized
        default:
            return nil
        }
    }
    override var fullDescription: String? {
        switch type {
        case .multiPass:
            return "wallet.proof.multiPass.infos".localized.replacingOccurrences(of: "<TO_DATE>", with: endDate.dayShortMonthYearTimeFormatted())
        default:
            return nil
        }
    }
    override var fullDescriptionForFullscreen: String? {
        switch type {
        case .multiPass:
            return "multiPassCertificate.fullscreen".localized.replacingOccurrences(of: "<FULL_NAME>", with: fullName)
                                                              .replacingOccurrences(of: "<BIRTHDATE>", with: birthDateString(forceEnglishFormat: false) ?? "")
                                                              .replacingOccurrences(of: "<TO_DATE>", with: endDate.dayShortMonthYearTimeFormatted())
        default:
            return nil
        }
    }
    override var pillTitles: [(text: String, backgroundColor: UIColor)] {
        isExpired ? [("wallet.expired.pillTitle".localized, Asset.Colors.error.color)] : []
    }

    var isExpired: Bool {
        switch type {
        case .multiPass:
            return endDate.timeIntervalSince1970 < Date().timeIntervalSince1970
        default:
            return false
        }
    }
    private let hCert: HCert
    
    
    init(id: String, value: String, hCert: HCert, parentId: String?) {
        self.hCert = hCert
        super.init(id: id, value: value, type: parentId == nil ? .multiPass : .activityEurope)
        self.parentId = parentId
    }

    private func birthDateString(forceEnglishFormat: Bool) -> String? {
        Date(dateString: hCert.dateOfBirth)?.dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat)
    }

    override func toRawCertificate() -> RawWalletCertificate {
        RawWalletCertificate(id: id, value: value, expiryDate: endDate, parentId: parentId)
    }

}
