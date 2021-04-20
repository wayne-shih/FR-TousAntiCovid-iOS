// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AnalyticsHealthInfo.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import ProximityNotification
import RealmSwift

final class AnalyticsHealthInfo: Object, Encodable {
    
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic let type: Int = 1
    @objc dynamic var os: String = UIDevice.current.systemName
    @objc dynamic var deviceModel: String = UIDevice.current.modelName
    @objc dynamic var osVersion: String = UIDevice.current.systemVersion
    @objc dynamic var appVersion: String = UIApplication.shared.marketingVersion
    @objc dynamic var appBuild: String = UIApplication.shared.buildNumber
    @objc dynamic var receivedHelloMessagesCount: Int = 0
    @objc dynamic var secondsTracingActivated: Int = 0
    @objc dynamic var placesCount: Int = 0
    @objc dynamic var riskLevel: Double = 0
    @objc dynamic var dateSample: String?
    @objc dynamic var dateFirstSymptoms: String?
    @objc dynamic var dateLastContactNotification: String?

    enum CodingKeys: String, CodingKey {
        case type
        case os
        case deviceModel
        case osVersion
        case appVersion
        case appBuild
        case receivedHelloMessagesCount
        case secondsTracingActivated
        case placesCount
        case riskLevel
        case dateSample
        case dateFirstSymptoms
        case dateLastContactNotification
    }

    override class func primaryKey() -> String? { "id" }
    override class func indexedProperties() -> [String] { ["id"] }
    
    func toJson() -> JSON? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? JSON
    }

}
