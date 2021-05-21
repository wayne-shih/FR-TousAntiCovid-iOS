// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AnalyticsError.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import RealmSwift

final class AnalyticsError: Object, Encodable {

    @objc dynamic var name: String
    @objc dynamic var timestamp: String
    @objc dynamic var desc: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case timestamp
        case desc
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
