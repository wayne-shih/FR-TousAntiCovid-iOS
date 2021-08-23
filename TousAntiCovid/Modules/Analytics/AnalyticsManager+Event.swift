// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AnalyticsManager+Event.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import RealmSwift

extension AnalyticsManager {
    
    func reportAppEvent(_ eventName: AnalyticsAppEvent.EventName, description: String? = nil) {
        guard isOptIn else { return }
        let event: AnalyticsAppEvent = AnalyticsAppEvent(name: eventName.rawValue, timestamp: Date().roundingToHour()?.universalDateFormatted() ?? "", desc: description)
        let realm: Realm = try! Realm.analyticsDb()
        try! realm.write {
            realm.add(event)
        }
    }
    
    func reportHealthEvent(_ eventName: AnalyticsHealthEvent.EventName, description: String? = nil) {
        guard isOptIn else { return }
        let event: AnalyticsHealthEvent = AnalyticsHealthEvent(name: eventName.rawValue, timestamp: Date().roundingToHour()?.universalDateFormatted() ?? "", desc: description)
        let realm: Realm = try! Realm.analyticsDb()
        try! realm.write {
            realm.add(event)
        }
    }
    
    func getCurrentAppEvents() -> [AnalyticsAppEvent] {
        let realm: Realm = try! Realm.analyticsDb()
        return [AnalyticsAppEvent](realm.objects(AnalyticsAppEvent.self))
    }
    
    func getCurrentHealthEvents() -> [AnalyticsHealthEvent] {
        let realm: Realm = try! Realm.analyticsDb()
        return [AnalyticsHealthEvent](realm.objects(AnalyticsHealthEvent.self))
    }
    
    func resetAppEvents() {
        let realm: Realm = try! Realm.analyticsDb()
        try! realm.write {
            realm.delete(realm.objects(AnalyticsAppEvent.self))
        }
    }
    
    func resetHealthEvents() {
        let realm: Realm = try! Realm.analyticsDb()
        try! realm.write {
            realm.delete(realm.objects(AnalyticsHealthEvent.self))
        }
    }
    
}
