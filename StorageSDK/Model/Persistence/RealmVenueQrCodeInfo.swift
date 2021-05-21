// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RealmVenueQrCodeInfo.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 24/11/2020 - for the TousAntiCovid project.
//


import UIKit
import RealmSwift
import RobertSDK

final class RealmVenueQrCodeInfo: Object {

    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var ltid: String!
    @objc dynamic var ntpTimestamp: Int = Int()
    @objc dynamic var base64: String!
    @objc dynamic var version: Int = Int()

    static func from(venueQrCodeInfo: VenueQrCodeInfo) -> RealmVenueQrCodeInfo {
        RealmVenueQrCodeInfo(id: venueQrCodeInfo.id,
                         ltid: venueQrCodeInfo.ltid,
                         ntpTimestamp: venueQrCodeInfo.ntpTimestamp,
                         base64: venueQrCodeInfo.base64,
                         version: venueQrCodeInfo.version)
    }

    convenience init(id: String, ltid: String, ntpTimestamp: Int, base64: String, version: Int) {
        self.init()
        self.id = id
        self.ltid = ltid
        self.ntpTimestamp = ntpTimestamp
        self.base64 = base64
        self.version = version
    }

    override class func primaryKey() -> String? {
        "id"
    }

    override class func indexedProperties() -> [String] {
        ["id"]
    }

    func toVenueQrCodeInfo() -> VenueQrCodeInfo {
        VenueQrCodeInfo(id: id,
                    ltid: ltid,
                    ntpTimestamp: ntpTimestamp,
                    base64: base64,
                    version: version)
    }
}
