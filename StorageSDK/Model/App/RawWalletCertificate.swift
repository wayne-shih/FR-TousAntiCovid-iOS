// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RawWalletCertificate.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/03/2021 - for the TousAntiCovid project.
//

import Foundation

public struct RawWalletCertificate {

    public let id: String
    public let value: String
    public let expiryDate: Date?
    public let parentId: String?
    public let didGenerateAllActivityCertificates: Bool
    public let didAlreadyGenerateActivityCertificates: Bool

    public init(id: String = UUID().uuidString, value: String, expiryDate: Date?, parentId: String?, didGenerateAllActivityCertificates: Bool = false, didAlreadyGenerateActivityCertificates: Bool = false) {
        self.id = id
        self.value = value
        self.parentId = parentId
        self.expiryDate = expiryDate
        self.didGenerateAllActivityCertificates = didGenerateAllActivityCertificates
        self.didAlreadyGenerateActivityCertificates = didAlreadyGenerateActivityCertificates
    }

}
