// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AnalyticsManager+Infos.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import RealmSwift
import RobertSDK
import ProximityNotification

extension AnalyticsManager {
    
    func createInfoIfNeeded() {
        createAppInfoIfNeeded()
        createHealthInfoIfNeeded()
        resetAppEvents()
        resetHealthEvents()
        resetErrors()
    }
    
    func createAppInfoIfNeeded() {
        guard getCurrentAppInfo() == nil else { return }
        let infos: AnalyticsAppInfo = AnalyticsAppInfo()
        let realm: Realm = try! Realm.analyticsDb()
        try! realm.write {
            realm.add(infos, update: .all)
        }
    }
    
    func createHealthInfoIfNeeded() {
        guard getCurrentHealthInfo() == nil else { return }
        let infos: AnalyticsHealthInfo = AnalyticsHealthInfo()
        let realm: Realm = try! Realm.analyticsDb()
        try! realm.write {
            realm.add(infos, update: .all)
        }
    }
    
    func resetInfo() {
        let realm: Realm = try! Realm.analyticsDb()
        try! realm.write {
            realm.delete(realm.objects(AnalyticsAppInfo.self))
            realm.delete(realm.objects(AnalyticsHealthInfo.self))
            realm.add(AnalyticsAppInfo(), update: .all)
            realm.add(AnalyticsHealthInfo(), update: .all)
        }
    }
    
    func getCurrentAppInfo() -> AnalyticsAppInfo? {
        let realm: Realm = try! Realm.analyticsDb()
        guard let analyticsInfo = realm.objects(AnalyticsAppInfo.self).first else { return nil }
        return analyticsInfo
    }
    
    func getCurrentHealthInfo() -> AnalyticsHealthInfo? {
        let realm: Realm = try! Realm.analyticsDb()
        guard let analyticsInfo = realm.objects(AnalyticsHealthInfo.self).first else { return nil }
        return analyticsInfo
    }
    
    func statusDidSucceed() {
        reportAppEvent(.e16)
        guard let infos = getCurrentAppInfo() else { return }
        let realm: Realm = try! Realm.analyticsDb()
        try! realm.write {
            infos.statusSuccessCount += 1
        }
    }
    
    func initProximityStartTimestampIfNeeded() {
        if RBManager.shared.isProximityActivated {
            proximityDidStart()
        } else {
            clearProximityStartTimestamp()
        }
    }
    
    func proximityDidStart() {
        lastProximityActivationStartTimestamp = Date().timeIntervalSince1970
    }
    
    func proximityDidStop() {
        updateInfoTracingDuration()
        clearProximityStartTimestamp()
    }
    
    func clearProximityStartTimestamp() {
        lastProximityActivationStartTimestamp = nil
    }
    
    func updateAppInfo() {
        guard let infos = getCurrentAppInfo() else { return }
        let realm: Realm = try! Realm.analyticsDb()
        try! realm.write {
            infos.os = UIDevice.current.systemName
            infos.deviceModel = UIDevice.current.modelName
            infos.osVersion = UIDevice.current.systemVersion
            infos.appVersion = UIApplication.shared.marketingVersion
            infos.appBuild = UIApplication.shared.buildNumber
            infos.receivedHelloMessagesCount = RBManager.shared.localProximityList.count
            infos.placesCount = VenuesManager.shared.venuesQrCodes.count
            infos.formsCount = AttestationsManager.shared.attestations.count
            infos.certificatesCount = WalletManager.shared.walletCertificates.count
            infos.userHasAZipcode = KeyFiguresManager.shared.currentPostalCode != nil
        }
        
        updateInfoTracingDuration()
    }
    
    func updateHealthInfo() {
        guard let infos = getCurrentHealthInfo() else { return }
        let realm: Realm = try! Realm.analyticsDb()
        try! realm.write {
            infos.os = UIDevice.current.systemName
            infos.deviceModel = UIDevice.current.modelName
            infos.osVersion = UIDevice.current.systemVersion
            infos.appVersion = UIApplication.shared.marketingVersion
            infos.appBuild = UIApplication.shared.buildNumber
            infos.receivedHelloMessagesCount = RBManager.shared.localProximityList.count
            infos.placesCount = VenuesManager.shared.venuesQrCodes.count
            infos.riskLevel = StatusManager.shared.currentStatusRiskLevel?.riskLevel ?? 0.0
            infos.dateSample = RBManager.shared.reportPositiveTestDate?.universalDateFormatted()
            infos.dateFirstSymptoms = RBManager.shared.reportSymptomsStartDate?.universalDateFormatted()
            infos.dateLastContactNotification = StatusManager.shared.currentStatusRiskLevel?.lastContactDate?.universalDateFormatted()
        }
        
        updateInfoTracingDuration()
    }
    
    private func updateInfoTracingDuration() {
        guard let lastStartTimestamp = lastProximityActivationStartTimestamp else { return }
        let elapsedTime: Double = Date().timeIntervalSince1970 - lastStartTimestamp
        incrementAppInfoTracingDuration(by: elapsedTime)
        incrementHealthInfoTracingDuration(by: elapsedTime)
        
        lastProximityActivationStartTimestamp = Date().timeIntervalSince1970
    }
    
    private func incrementAppInfoTracingDuration(by duration: Double) {
        guard let info = getCurrentAppInfo() else { return }
        let realm: Realm = try! Realm.analyticsDb()
        try! realm.write {
            info.secondsTracingActivated += Int(duration)
        }
    }
    
    private func incrementHealthInfoTracingDuration(by duration: Double) {
        guard let info = getCurrentHealthInfo() else { return }
        let realm: Realm = try! Realm.analyticsDb()
        try! realm.write {
            info.secondsTracingActivated += Int(duration)
        }
    }

}
