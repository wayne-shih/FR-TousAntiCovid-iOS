// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ActivityCertificate.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 16/08/2021 - for the TousAntiCovid project.
//

import Foundation
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
    
    private var fullName: String {
        let first: String? = hCert.get(.firstName).string
        let last: String? = hCert.get(.lastName).string
        return [first, last].compactMap { $0?.trimmingCharacters(in: .whitespaces) } .joined(separator: " ")
    }
    
    private let hCert: HCert
    
    init(id: String, value: String, hCert: HCert, parentId: String) {
        self.hCert = hCert
        super.init(id: id, value: value, type: .activityEurope)
        self.parentId = parentId
    }

    private func birthDateString(forceEnglishFormat: Bool) -> String? {
        Date(dateString: hCert.dateOfBirth)?.dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat)
    }

    override func toRawCertificate() -> RawWalletCertificate {
        RawWalletCertificate(id: id, value: value, expiryDate: endDate, parentId: parentId)
    }

}
