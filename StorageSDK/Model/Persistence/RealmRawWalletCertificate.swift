// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RealmRawWalletCertificate.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 17/03/2021 - for the TousAntiCovid project.
//

import Foundation
import RealmSwift

final class RealmRawWalletCertificate: Object {
    
    @objc dynamic var id: String!
    @objc dynamic var certificateValue: String!
    @objc dynamic var expiryDate: Date? // Used only in storage to allow us to sort certificates without having to parse them all.
    @objc dynamic var parentId: String?
    @objc dynamic var didGenerateAllActivityCertificates: Bool = false
    @objc dynamic var didAlreadyGenerateActivityCertificates: Bool = false
    
    convenience init(id: String = UUID().uuidString, certificateValue: String, expiryDate: Date?, parentId: String?, didGenerateAllActivityCertificates: Bool, didAlreadyGenerateActivityCertificates: Bool) {
        self.init()
        self.id = id
        self.certificateValue = certificateValue
        self.expiryDate = expiryDate
        self.parentId = parentId
        self.didGenerateAllActivityCertificates = didGenerateAllActivityCertificates
        self.didAlreadyGenerateActivityCertificates = didAlreadyGenerateActivityCertificates
    }
    
    static func from(rawCertificate: RawWalletCertificate) -> RealmRawWalletCertificate {
        RealmRawWalletCertificate(id: rawCertificate.id, certificateValue: rawCertificate.value, expiryDate: rawCertificate.expiryDate, parentId: rawCertificate.parentId, didGenerateAllActivityCertificates: rawCertificate.didGenerateAllActivityCertificates, didAlreadyGenerateActivityCertificates: rawCertificate.didAlreadyGenerateActivityCertificates)
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override class func indexedProperties() -> [String] {
        return ["id"]
    }
    
    func toRawWalletCertificate() -> RawWalletCertificate {
        RawWalletCertificate(id: id, value: certificateValue, expiryDate: expiryDate, parentId: parentId, didGenerateAllActivityCertificates: didGenerateAllActivityCertificates, didAlreadyGenerateActivityCertificates: didAlreadyGenerateActivityCertificates)
    }
    
}
