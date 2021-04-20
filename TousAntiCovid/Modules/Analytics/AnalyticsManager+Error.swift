// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AnalyticsManager+Error.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK
import RealmSwift

extension AnalyticsManager {

    func reportError<ApiVersion: RawRepresentable>(serviceName: String, apiVersion: ApiVersion, code: Int, desc: String? = nil)  where ApiVersion.RawValue == String {
        let error: AnalyticsError = AnalyticsError(name: "ERR-\(serviceName.uppercased())-\(apiVersion.rawValue)-\(code)", timestamp: Date().universalDateFormatted(), desc: desc)
        let realm: Realm = try! Realm.analyticsDb()
        try! realm.write {
            realm.add(error)
        }
    }
    
    func getCurrentErrors() -> [AnalyticsError] {
        let realm: Realm = try! Realm.analyticsDb()
        return [AnalyticsError](realm.objects(AnalyticsError.self))
    }
    
    func resetErrors() {
        let realm: Realm = try! Realm.analyticsDb()
        try! realm.write {
            realm.delete(realm.objects(AnalyticsError.self))
        }
    }
    
}
