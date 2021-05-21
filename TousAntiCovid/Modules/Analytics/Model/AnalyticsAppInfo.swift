// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AnalyticsAppInfo.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import ProximityNotification
import RealmSwift

final class AnalyticsAppInfo: Object, Encodable {
    
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic let type: Int = 0
    @objc dynamic var os: String = UIDevice.current.systemName
    @objc dynamic var deviceModel: String = UIDevice.current.modelName
    @objc dynamic var osVersion: String = UIDevice.current.systemVersion
    @objc dynamic var appVersion: String = UIApplication.shared.marketingVersion
    @objc dynamic var appBuild: Int = Int(UIApplication.shared.buildNumber) ?? 0
    @objc dynamic var receivedHelloMessagesCount: Int = 0
    @objc dynamic var placesCount: Int = 0
    @objc dynamic var formsCount: Int = 0
    @objc dynamic var certificatesCount: Int = 0
    @objc dynamic var statusSuccessCount: Int = 0
    @objc dynamic var userHasAZipcode: Bool = false

    enum CodingKeys: String, CodingKey {
        case type
        case os
        case deviceModel
        case osVersion
        case appVersion
        case appBuild
        case receivedHelloMessagesCount
        case placesCount
        case formsCount
        case certificatesCount
        case statusSuccessCount
        case userHasAZipcode
    }
    
    override class func primaryKey() -> String? { "id" }
    override class func indexedProperties() -> [String] { ["id"] }

    func toJson() -> JSON? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? JSON
    }

}
