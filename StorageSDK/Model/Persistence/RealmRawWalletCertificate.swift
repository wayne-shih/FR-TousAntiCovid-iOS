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
    
    convenience init(id: String = UUID().uuidString, certificateValue: String) {
        self.init()
        self.id = id
        self.certificateValue = certificateValue
    }
    
    static func from(rawCertificate: RawWalletCertificate) -> RealmRawWalletCertificate {
        RealmRawWalletCertificate(id: rawCertificate.id, certificateValue: rawCertificate.value)
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override class func indexedProperties() -> [String] {
        return ["id"]
    }
    
    func toRawWalletCertificate() -> RawWalletCertificate {
        RawWalletCertificate(id: id, value: certificateValue)
    }
    
}
