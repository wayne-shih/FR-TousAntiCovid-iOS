// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AnalyticsAppEvent.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import RealmSwift

final class AnalyticsAppEvent: Object, Encodable {

    @objc dynamic var name: String
    @objc dynamic var timestamp: String
    @objc dynamic var desc: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case timestamp
        case desc
    }
    
    enum EventName: String {
        case e1
        case e3
        case e4
        case e5
        case e6
        case e7
        case e8
        case e9
        case e10
        case e11
        case e12
        case e14
        case e15
        case e16
        case e17
        case e18
        case e19
    }
    
    init(name: String, timestamp: String, desc: String?) {
        self.name = name
        self.timestamp = timestamp
        self.desc = desc
        super.init()
    }
    
    required override init() {
        self.name = ""
        self.timestamp = ""
        super.init()
    }
    
    func toJson() -> JSON? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? JSON
    }
    
}
