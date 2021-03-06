// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StorageManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 27/04/2020 - for the TousAntiCovid project.
//

import UIKit
import KeychainSwift
import RealmSwift
import RobertSDK

public final class StorageManager: RBStorage {

    enum KeychainKey: String, CaseIterable {
        case dbKey
        case epochTimeStart
        case ka
        case kea
        case proximityActivated
        case isAtRisk
        case lastExposureTimeFrame
        case lastStatusReceivedDate
        case lastStatusErrorDate
        case lastCleaStatusReceivedDate
        case lastCleaStatusErrorDate
        case lastRiskReceivedDate
        case positiveToSymptoms
        case pushToken
        case reportDate
        case reportDataOriginDate
        case reportSymptomsStartDate
        case reportPositiveTestDate
        case reportToken

        case currentRiskStatusLevel
        case lastRobertRiskStatusLevel
        case lastCleaRiskStatusLevel
        case declarationToken
        case analyticsToken

        case isolationState
        case isolationLastContactDate
        case isolationIsKnownIndexAtHome
        case isolationKnowsIndexSymptomsEndDate
        case isolationIndexSymptomsEndDate
        case isolationIsTestNegative
        case isolationPositiveTestingDate
        case isolationIsHavingSymptoms
        case isolationSymptomsStartDate
        case isolationIsStillHavingFever
        case isolationIsFeverReminderScheduled
    }
    
    let keychain: KeychainSwift = KeychainSwift(keyPrefix: "SC")
    public private(set) var wasWiped: Bool = false
    
    private var realm: Realm?
    private var loggingHandler: (_ message: String) -> ()
    
    public init(loggingHandler: @escaping (_ message: String) -> ()) {
        self.loggingHandler = loggingHandler
    }
    
    public func start() {
        loadDb()
    }
    
    public func stop() {
        realm = nil
    }
    
    public func resetWasWiped() {
        wasWiped = false
    }
    
    // MARK: - Epoch -
    public func save(epochs: [RBEpoch]) {
        guard let realm = realm else { return }
        Realm.queue.sync {
            let realmEpochs: [RealmEpoch] = epochs.map { RealmEpoch.from(epoch: $0) }
            try! realm.write {
                realm.add(realmEpochs, update: .all)
            }
        }
    }
    
    public func getCurrentEpoch(defaultingToLast: Bool) -> RBEpoch? {
        do {
            let timeStart: Int = try getTimeStart()
            let now: Int = Date().timeIntervalSince1900
            let quartersCount: Int = Int(Double(now - timeStart) / Double(RBConstants.epochDurationInSeconds))
            return getEpoch(for: quartersCount) ?? (defaultingToLast ? getLastEpoch() : nil)
        } catch {
            return nil
        }
    }
    
    public func getEpoch(for id: Int) -> RBEpoch? {
        guard let realm = realm else { return nil }
        var epoch: RBEpoch?
        Realm.queue.sync {
            epoch = realm.object(ofType: RealmEpoch.self, forPrimaryKey: id)?.toRBEpoch()
        }
        return epoch
    }
    
    public func getLastEpoch() -> RBEpoch? {
        guard let realm = realm else { return nil }
        var epoch: RBEpoch?
        Realm.queue.sync {
            epoch = realm.objects(RealmEpoch.self).sorted { $0.epochId < $1.epochId }.last?.toRBEpoch()
        }
        return epoch
    }
    
    public func epochsCount() -> Int {
        guard let realm = realm else { return 0 }
        var count: Int = 0
        Realm.queue.sync {
            count = realm.objects(RealmEpoch.self).count
        }
        return count
    }
    
    // MARK: - TimeStart -
    public func save(timeStart: Int) throws {
        guard let data = "\(timeStart)".data(using: .utf8) else { throw NSError.stLocalizedError(message: "Can't generate data from timeStart", code: 400) }
        keychain.set(data, forKey: KeychainKey.epochTimeStart.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
    }
    
    public func getTimeStart() throws -> Int {
        guard let data = keychain.getData(KeychainKey.epochTimeStart.rawValue) else { throw NSError.stLocalizedError(message: "timeStart not found in Keychain", code: 404) }
        guard let timeString = String(data: data, encoding: .utf8),
              let timeStart = Int(timeString) else { throw NSError.stLocalizedError(message: "Can't generate Int from timeStart data", code: 400) }
        return timeStart
    }
    
    // MARK: - Keys -
    public func save(ka: Data) {
        keychain.set(ka, forKey: KeychainKey.ka.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
    }
    
    public func getKa() -> Data? {
        keychain.getData(KeychainKey.ka.rawValue)
    }
    
    public func save(kea: Data) {
        keychain.set(kea, forKey: KeychainKey.kea.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
    }
    
    public func getKea() -> Data? {
        keychain.getData(KeychainKey.kea.rawValue)
    }
    
    public func areKeysStored() -> Bool {
        getKa() != nil && getKea() != nil
    }
    
    // MARK: - Local Proximity -
    public func save(localProximity: RBLocalProximity) -> Bool {
        guard let realm = realm else { return false }
        var success: Bool = false
        Realm.queue.sync {
            let proximity: RealmLocalProximity = RealmLocalProximity.from(localProximity: localProximity)
            if realm.object(ofType: RealmLocalProximity.self, forPrimaryKey: proximity.id) == nil {
                try! realm.write {
                    realm.add(proximity, update: .all)
                }
                success = true
            } else {
                success = false
            }
        }
        if success {
            notifyLocalProximityDataChanged()
        }
        return success
    }
    
    public func getLocalProximityList() -> [RBLocalProximity] {
        guard let realm = realm else { return [] }
        var proximities: [RBLocalProximity] = []
        Realm.queue.sync {
            proximities = realm.objects(RealmLocalProximity.self).map { $0.toRBLocalProximity() }
        }
        return proximities
    }
    
    public func getLocalProximityList(from: Date, to: Date) -> [RBLocalProximity] {
        guard let realm = realm else { return [] }
        var localProximities: [RBLocalProximity] = []
        Realm.queue.sync {
            let proximities: [RealmLocalProximity] = [RealmLocalProximity](realm.objects(RealmLocalProximity.self))
            let matchingProximities: [RealmLocalProximity] = proximities.filter { $0.timeCollectedOnDevice >= from.timeIntervalSince1900 && $0.timeCollectedOnDevice <= to.timeIntervalSince1900 }
            localProximities = matchingProximities.map { $0.toRBLocalProximity() }
        }
        return localProximities
    }
    
    public func clearProximityList(before date: Date) {
        guard let realm = realm else { return }
        Realm.queue.sync {
            let proximities: [RealmLocalProximity] = [RealmLocalProximity](realm.objects(RealmLocalProximity.self))
            let proximitiesToDelete: [RealmLocalProximity] = proximities.filter { $0.timeCollectedOnDevice < date.timeIntervalSince1900 }
            if !proximitiesToDelete.isEmpty {
                try! realm.write {
                    loggingHandler(formatLog(type: .deletion(.realm), message: "all local proximities"))
                    realm.delete(proximitiesToDelete)
                }
            }
        }
    }
    
    // MARK: - Proximity -
    public func save(proximityActivated: Bool) {
        UserDefaults.standard.set(proximityActivated, forKey: KeychainKey.proximityActivated.rawValue)
        UserDefaults.standard.synchronize()
        notifyStatusDataChanged()
    }
    
    public func isProximityActivated() -> Bool {
        if let bool = UserDefaults.standard.object(forKey: KeychainKey.proximityActivated.rawValue) as? Bool {
            return bool
        } else {
            let bool: Bool = keychain.getBool(KeychainKey.proximityActivated.rawValue) ?? false
            save(proximityActivated: bool)
            return bool
        }
    }
    
    // MARK: - Status: last exposure time frame -
    public func save(lastExposureTimeFrame: Int?) {
        if let lastExposureTimeFrame = lastExposureTimeFrame {
            keychain.set("\(lastExposureTimeFrame)", forKey: KeychainKey.lastExposureTimeFrame.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            loggingHandler(formatLog(type: .deletion(.keychain), message: "\(KeychainKey.lastExposureTimeFrame.rawValue) content"))
            keychain.delete(KeychainKey.lastExposureTimeFrame.rawValue)
        }
        notifyStatusDataChanged()
    }
    
    public func lastExposureTimeFrame() -> Int? {
        guard let lastExposureString = keychain.get(KeychainKey.lastExposureTimeFrame.rawValue), let lastExposure = Int(lastExposureString) else { return nil }
        return lastExposure
    }
    
    // MARK: - Status: last status received date -
    public func saveLastStatusReceivedDate(_ date: Date?) {
        saveDate(date, key: .lastStatusReceivedDate)
    }
    
    public func lastStatusReceivedDate() -> Date? {
        getDate(key: .lastStatusReceivedDate)
    }
    
    // MARK: - Status: last status error date -
    public func saveLastStatusErrorDate(_ date: Date?) {
        saveDate(date, key: .lastStatusErrorDate)
    }
    
    public func lastStatusErrorDate() -> Date? {
        getDate(key: .lastStatusErrorDate)
    }
    
    // MARK: - Status: last risk received date -
    public func saveLastRiskReceivedDate(_ date: Date?) {
        saveDate(date, key: .lastRiskReceivedDate)
    }
    
    public func lastRiskReceivedDate() -> Date? {
        getDate(key: .lastRiskReceivedDate)
    }

    // MARK: - Status: last clea status received date -
    public func saveLastCleaStatusReceivedDate(_ date: Date?) {
        saveDate(date, key: .lastCleaStatusReceivedDate)
    }

    public func lastCleaStatusReceivedDate() -> Date? {
        getDate(key: .lastCleaStatusReceivedDate)
    }

    // MARK: - Status: last clea status error date -
    public func saveLastCleaStatusErrorDate(_ date: Date?) {
        saveDate(date, key: .lastCleaStatusErrorDate)
    }

    public func lastCleaStatusErrorDate() -> Date? {
        getDate(key: .lastCleaStatusErrorDate)
    }
    
    // MARK: - Push token -
    public func save(pushToken: String?) {
        saveString(pushToken, key: .pushToken)
    }
    
    public func pushToken() -> String? {
        getString(key: .pushToken)
    }
    
    // MARK: - Report dates -
    public func saveReportDate(_ date: Date?) {
        saveDate(date, key: .reportDate)
    }
    
    public func reportDate() -> Date? {
        getDate(key: .reportDate)
    }
    
    public func saveReportDataOriginDate(_ date: Date?) {
        saveDate(date, key: .reportDataOriginDate)
    }
    
    public func reportDataOriginDate() -> Date? {
        getDate(key: .reportDataOriginDate)
    }
    
    public func saveReportSymptomsStartDate(_ date: Date?) {
        saveDate(date, key: .reportSymptomsStartDate)
    }
    
    public func reportSymptomsStartDate() -> Date? {
        getDate(key: .reportSymptomsStartDate)
    }
    
    public func saveReportPositiveTestDate(_ date: Date?) {
        saveDate(date, key: .reportPositiveTestDate)
    }
    
    public func reportPositiveTestDate() -> Date? {
        getDate(key: .reportPositiveTestDate)
    }
    
    // MARK: - Report token -
    public func saveReportToken(_ token: String?) {
        saveString(token, key: .reportToken, notify: false)
    }
    
    public func reportToken() -> String? {
        getString(key: .reportToken)
    }
    
    // MARK: - Isolation -
    public func saveIsolationState(_ state: String?) {
        saveString(state, key: .isolationState, notify: false)
    }
    
    public func isolationState() -> String? {
        getString(key: .isolationState)
    }
    
    public func saveIsolationLastContactDate(_ date: Date?) {
        saveDate(date, key: .isolationLastContactDate, notify: false)
    }
    
    public func isolationLastContactDate() -> Date? {
        getDate(key: .isolationLastContactDate)
    }
    
    public func saveIsolationIsKnownIndexAtHome(_ isAtHome: Bool?) {
        saveBool(isAtHome, key: .isolationIsKnownIndexAtHome, notify: false)
    }
    
    public func isolationIsKnownIndexAtHome() -> Bool? {
        keychain.getBool(KeychainKey.isolationIsKnownIndexAtHome.rawValue)
    }
    
    public func saveIsolationKnowsIndexSymptomsEndDate(_ knowsEndDate: Bool?) {
        saveBool(knowsEndDate, key: .isolationKnowsIndexSymptomsEndDate, notify: false)
    }
    
    public func isolationKnowsIndexSymptomsEndDate() -> Bool? {
        keychain.getBool(KeychainKey.isolationKnowsIndexSymptomsEndDate.rawValue)
    }
    
    public func saveIsolationIndexSymptomsEndDate(_ date: Date?) {
        saveDate(date, key: .isolationIndexSymptomsEndDate, notify: false)
    }
    
    public func isolationIndexSymptomsEndDate() -> Date? {
        getDate(key: .isolationIndexSymptomsEndDate)
    }
    
    public func saveIsolationIsTestNegative(_ isTestNegative: Bool?) {
        saveBool(isTestNegative, key: .isolationIsTestNegative, notify: false)
    }
    
    public func isolationIsTestNegative() -> Bool? {
        keychain.getBool(KeychainKey.isolationIsTestNegative.rawValue)
    }
    
    public func saveIsolationPositiveTestingDate(_ date: Date?) {
        saveDate(date, key: .isolationPositiveTestingDate, notify: false)
    }
    
    public func isolationPositiveTestingDate() -> Date? {
        getDate(key: .isolationPositiveTestingDate)
    }
    
    public func saveIsolationIsHavingSymptoms(_ havingSymptoms: Bool?) {
        saveBool(havingSymptoms, key: .isolationIsHavingSymptoms, notify: false)
    }
    
    public func isolationIsHavingSymptoms() -> Bool? {
        keychain.getBool(KeychainKey.isolationIsHavingSymptoms.rawValue)
    }
    
    public func saveIsolationSymptomsStartDate(_ date: Date?) {
        saveDate(date, key: .isolationSymptomsStartDate, notify: false)
    }
    
    public func isolationSymptomsStartDate() -> Date? {
        getDate(key: .isolationSymptomsStartDate)
    }
    
    public func saveIsolationIsStillHavingFever(_ stillHavingFever: Bool?) {
        saveBool(stillHavingFever, key: .isolationIsStillHavingFever, notify: false)
    }
    
    public func isolationIsStillHavingFever() -> Bool? {
        keychain.getBool(KeychainKey.isolationIsStillHavingFever.rawValue)
    }
    
    public func saveIsolationIsFeverReminderScheduled(_ isScheduled: Bool?) {
        saveBool(isScheduled, key: .isolationIsFeverReminderScheduled, notify: false)
    }
    
    public func isolationIsFeverReminderScheduled() -> Bool? {
        keychain.getBool(KeychainKey.isolationIsFeverReminderScheduled.rawValue)
    }
    
    // MARK: - Status: Declaration token -
    public func saveDeclarationToken(_ token: String?) {
        saveString(token, key: .declarationToken, notify: false)
    }
    
    public func declarationToken() -> String? {
        getString(key: .declarationToken)
    }
    
    // MARK: - Status: Analytics token -
    public func saveAnalyticsToken(_ token: String?) {
        saveString(token, key: .analyticsToken, notify: false)
    }
    
    public func analyticsToken() -> String? {
        getString(key: .analyticsToken)
    }
    
    // MARK: - Status: Current risk level -
    public func saveCurrentStatusRiskLevel(_ statusRiskLevelInfo: RBStatusRiskLevelInfo?) {
        guard let statusRiskLevelInfo = statusRiskLevelInfo else {
            loggingHandler(formatLog(type: .deletion(.keychain), message: "\(KeychainKey.currentRiskStatusLevel.rawValue) content"))
            keychain.delete(KeychainKey.currentRiskStatusLevel.rawValue)
            return
        }
        guard let data = try? JSONEncoder().encode(statusRiskLevelInfo) else { return }
        keychain.set(data, forKey: KeychainKey.currentRiskStatusLevel.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
    }
    
    public func currentStatusRiskLevel() -> RBStatusRiskLevelInfo? {
        guard let data = keychain.getData(KeychainKey.currentRiskStatusLevel.rawValue) else { return nil }
        return try? JSONDecoder().decode(RBStatusRiskLevelInfo.self, from: data)
    }
    
    // MARK: - Status: Last Robert risk level -
    public func saveLastRobertStatusRiskLevel(_ statusRiskLevelInfo: RBStatusRiskLevelInfo?) {
        guard let statusRiskLevelInfo = statusRiskLevelInfo else {
            loggingHandler(formatLog(type: .deletion(.keychain), message: "\(KeychainKey.lastRobertRiskStatusLevel.rawValue) content"))
            keychain.delete(KeychainKey.lastRobertRiskStatusLevel.rawValue)
            return
        }
        guard let data = try? JSONEncoder().encode(statusRiskLevelInfo) else { return }
        keychain.set(data, forKey: KeychainKey.lastRobertRiskStatusLevel.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
    }
    
    public func lastRobertStatusRiskLevel() -> RBStatusRiskLevelInfo? {
        guard let data = keychain.getData(KeychainKey.lastRobertRiskStatusLevel.rawValue) else { return nil }
        return try? JSONDecoder().decode(RBStatusRiskLevelInfo.self, from: data)
    }
    
    // MARK: - Status: Last Clea risk level -
    public func saveLastCleaStatusRiskLevel(_ statusRiskLevelInfo: RBStatusRiskLevelInfo?) {
        guard let statusRiskLevelInfo = statusRiskLevelInfo else {
            loggingHandler(formatLog(type: .deletion(.keychain), message: "\(KeychainKey.lastCleaRiskStatusLevel.rawValue) content"))
            keychain.delete(KeychainKey.lastCleaRiskStatusLevel.rawValue)
            return
        }
        guard let data = try? JSONEncoder().encode(statusRiskLevelInfo) else { return }
        keychain.set(data, forKey: KeychainKey.lastCleaRiskStatusLevel.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
    }
    
    public func lastCleaStatusRiskLevel() -> RBStatusRiskLevelInfo? {
        guard let data = keychain.getData(KeychainKey.lastCleaRiskStatusLevel.rawValue) else { return nil }
        return try? JSONDecoder().decode(RBStatusRiskLevelInfo.self, from: data)
    }
    
    private func saveDate(_ date: Date?, key: KeychainKey, notify: Bool = true) {
        if let date = date {
            keychain.set("\(date.timeIntervalSince1970)", forKey: key.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            loggingHandler(formatLog(type: .deletion(.keychain), message: "\(key.rawValue) content"))
            keychain.delete(key.rawValue)
        }
        guard notify else { return }
        notifyStatusDataChanged()
    }
    
    private func getDate(key: KeychainKey) -> Date? {
        guard let timestampString = keychain.get(key.rawValue), let timestamp = Double(timestampString) else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    private func saveString(_ string: String?, key: KeychainKey, notify: Bool = true) {
        if let string = string {
            keychain.set(string, forKey: key.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            loggingHandler(formatLog(type: .deletion(.keychain), message: "\(key.rawValue) content"))
            keychain.delete(key.rawValue)
        }
        guard notify else { return }
        notifyStatusDataChanged()
    }
    
    private func getString(key: KeychainKey) -> String? {
        keychain.get(key.rawValue)
    }
    
    private func saveBool(_ bool: Bool?, key: KeychainKey, notify: Bool = true) {
        if let bool = bool {
            keychain.set(bool, forKey: key.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            loggingHandler(formatLog(type: .deletion(.keychain), message: "\(key.rawValue) content"))
            keychain.delete(key.rawValue)
        }
        guard notify else { return }
        notifyStatusDataChanged()
    }
    
    // MARK: - Data clearing -
    public func clearLocalEpochs() {
        guard let realm = realm else { return }
        Realm.queue.sync {
            try! realm.write {
                loggingHandler(formatLog(type: .deletion(.realm), message: "all local epochs"))
                realm.delete(realm.objects(RealmEpoch.self))
            }
        }
    }
    
    public func clearLocalProximityList() {
        guard let realm = realm else { return }
        Realm.queue.sync {
            try! realm.write {
                loggingHandler(formatLog(type: .deletion(.realm), message: "all local proximities"))
                realm.delete(realm.objects(RealmLocalProximity.self))
            }
        }
        notifyLocalProximityDataChanged()
    }
    
    public func clearAll(includingDBKey: Bool) {
        keychain.allKeys.forEach {
            guard $0.hasPrefix("SC") else { return }
            let keyWithoutPrefix: String = String($0.suffix($0.count - 2))
            if keyWithoutPrefix != KeychainKey.dbKey.rawValue || includingDBKey {
                loggingHandler(formatLog(type: .deletion(.keychain), message: "\(keyWithoutPrefix)"))
                keychain.delete(keyWithoutPrefix)
            }
        }
        deleteAllAttestationFields()
        deleteDb(includingFile: includingDBKey)
        notifyStatusDataChanged()
    }
    
    public func clearRobertData() {
        // Delete Realm data
        guard let realm = realm else { return }
        Realm.queue.sync {
            try! realm.write {
                loggingHandler(formatLog(type: .deletion(.realm), message: "all local proximities"))
                realm.delete(realm.objects(RealmLocalProximity.self))
                loggingHandler(formatLog(type: .deletion(.realm), message: "all local epochs"))
                realm.delete(realm.objects(RealmEpoch.self))
            }
        }
        // Delete keychain data
        keychain.delete(KeychainKey.ka.rawValue)
        keychain.delete(KeychainKey.kea.rawValue)
        keychain.delete(KeychainKey.epochTimeStart.rawValue)
        keychain.delete(KeychainKey.isAtRisk.rawValue)
        keychain.delete(KeychainKey.lastRobertRiskStatusLevel.rawValue)
        keychain.delete(KeychainKey.lastStatusErrorDate.rawValue)
        keychain.delete(KeychainKey.lastStatusReceivedDate.rawValue)
        keychain.delete(KeychainKey.lastExposureTimeFrame.rawValue)
        keychain.delete(KeychainKey.lastRiskReceivedDate.rawValue)
        keychain.delete(KeychainKey.proximityActivated.rawValue)
        keychain.delete(KeychainKey.reportDate.rawValue)
        keychain.delete(KeychainKey.reportToken.rawValue)
        keychain.delete(KeychainKey.declarationToken.rawValue)
        keychain.delete(KeychainKey.analyticsToken.rawValue)
        loggingHandler(formatLog(type: .deletion(.keychain), message: "all Robert associated keys"))
    }
    
    private func deleteDb(includingFile: Bool) {
        Realm.queue.sync {
            try? realm?.write {
                loggingHandler(formatLog(type: .deletion(.realm), message: "all data"))
                realm?.deleteAll()
            }
            if includingFile {
                realm = nil
                loggingHandler(formatLog(type: .deletion(.realm), message: "database files"))
                Realm.deleteDb()
            }
        }
    }
    
    // MARK: - DB Key -
    private func loadDb() {
        if let key = getDbKey() {
            realm = try! Realm.db(key: key)
        } else if let newKey = Realm.generateEncryptionKey(), !keychain.allKeys.contains("SC\(KeychainKey.dbKey.rawValue)") {
            deleteDb(includingFile: true)
            realm = try! Realm.db(key: newKey)
            save(dbKey: newKey)
        }
    }
    
    private func save(dbKey: Data) {
        keychain.set(dbKey, forKey: KeychainKey.dbKey.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
    }
    
    private func getDbKey() -> Data? {
        keychain.getData(KeychainKey.dbKey.rawValue)
    }
    
}

public extension StorageManager {
    
    func saveAttestation(_ attestation: Attestation) {
        guard let realm = realm else { return }
        Realm.queue.sync {
            let realmAttestation: RealmAttestation = RealmAttestation.from(attestation: attestation)
            try! realm.write {
                realm.add(realmAttestation, update: .all)
            }
        }
        notifyAttestationDataChanged()
    }
    
    func attestations() -> [Attestation] {
        guard let realm = realm else { return [] }
        var attestations: [Attestation] = []
        Realm.queue.sync {
            attestations = realm.objects(RealmAttestation.self).map { $0.toAttestation() }
        }
        return attestations
    }
    
    func deleteAttestationsData() {
        guard let realm = realm else { return }
        Realm.queue.sync {
            try! realm.write {
                loggingHandler(formatLog(type: .deletion(.realm), message: "all attestations"))
                realm.delete(realm.objects(RealmAttestation.self))
            }
        }
        notifyAttestationDataChanged()
    }
    
    func deleteAttestation(_ attestation: Attestation) {
        guard let realm = realm else { return }
        Realm.queue.sync {
            if let attestation = realm.object(ofType: RealmAttestation.self, forPrimaryKey: attestation.id) {
                try! realm.write {
                    loggingHandler(formatLog(type: .deletion(.realm), message: "one attestation"))
                    realm.delete(attestation)
                }
            }
        }
        notifyAttestationDataChanged()
    }
    
    func deleteExpiredAttestationsData(durationInHours: Double) {
        guard let realm = realm else { return }
        let now: Date = Date()
        Realm.queue.sync {
            let expiredAttestations: [RealmAttestation] = [RealmAttestation](realm.objects(RealmAttestation.self)).filter { attestation in
                (now.timeIntervalSince1970 - Double(attestation.timestamp)) >= durationInHours * 3600.0
            }
            if !expiredAttestations.isEmpty {
                try! realm.write {
                    loggingHandler(formatLog(type: .deletion(.realm), message: "\(expiredAttestations.count) expired attestations"))
                    realm.delete(expiredAttestations)
                }
            }
        }
        notifyAttestationDataChanged()
    }
    
    func saveAttestationFieldValueForKey(_ key: String, dataKey: String, value: String?) {
        let keychainKey: String = "attestation-\(dataKey)-\(key)"
        if let value = value {
            keychain.set(value, forKey: keychainKey, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            loggingHandler(formatLog(type: .deletion(.keychain), message: "attestation-\(dataKey)-\(key) content"))
            keychain.delete(keychainKey)
        }
    }

    func getAttestationFieldValues() -> [String: [String: String]] {
        var fieldValues: [String: [String: String]] = [:]
        keychain.allKeys.forEach { key in
            if key.hasPrefix("SCattestation-") {
                let composedKey: String = key.replacingOccurrences(of: "SCattestation-", with: "")
                let dataKey: String = composedKey.components(separatedBy: "-").filter { !$0.isEmpty }[0]
                var fieldKey: String?
                if let range = composedKey.range(of: "\(dataKey)-") {
                    fieldKey = composedKey.replacingCharacters(in: range, with: "")
                }
                guard let fieldValue = keychain.get(key.replacingOccurrences(of: "SC", with: "")) else { return }
                var dict: [String: String] = fieldValues[dataKey] ?? [:]
                dict[fieldKey ?? dataKey] = fieldValue
                fieldValues[dataKey] = dict
            }
        }
        return fieldValues
    }
    
    func getAttestationFieldValueForKey(_ key: String) -> String? {
        let keychainKey: String = "attestation-\(key)"
        return keychain.get(keychainKey)
    }
    
    func deleteAllAttestationFields() {
        keychain.allKeys.forEach { key in
            if key.hasPrefix("SCattestation-") {
                loggingHandler(formatLog(type: .deletion(.keychain), message: "\(key) content"))
                keychain.delete(key.replacingOccurrences(of: "SC", with: ""))
            }
        }
    }
    
}

// MARK: - DCC Blacklist -
public extension StorageManager {
    
    // Get if dcc is in blacklist
    func isBlacklistedDcc(_ dccHash: String) -> Bool {
        var isBlacklisted: Bool = false
        Realm.queue.sync {
            isBlacklisted = realm?.object(ofType: RealmBlacklistedDcc.self, forPrimaryKey: dccHash) != nil
        }
        return isBlacklisted
    }
    
    // Get content of blacklist
    func dccBlacklist() -> [String] {
        guard let realm = realm else { return [] }
        var hashes: [String] = []
        Realm.queue.sync {
            hashes = realm.objects(RealmBlacklistedDcc.self).map { $0.hashString }
        }
        return hashes
    }
    
    // Delete all the content of the blacklist
    func clearDccBlacklist() {
        guard let realm = realm else { return }
        Realm.queue.sync {
            try! realm.write {
                realm.delete(realm.objects(RealmBlacklistedDcc.self))
            }
        }
    }
    
    // Update balcklist with new or existing dccs
    func updateDccBlacklist(_ hashes: [String]) {
        guard let realm = realm else { return }
        Realm.queue.sync {
            try! realm.write {
                realm.add(hashes.map { RealmBlacklistedDcc(hash: $0) }, update: .all)
            }
        }
    }
    
    // Remove an array of dccs from blacklist
    func deleteDccsFromBlacklist(_ dccHashes: [String]) {
        guard let realm = realm else { return }
        Realm.queue.sync {
            try! realm.write {
                realm.delete(realm.objects(RealmBlacklistedDcc.self).filter("hashString IN %@", dccHashes))
            }
        }
    }
    
    // Utils for UnitTests
    func blacklistRandomElement() -> String {
        guard let realm = realm else { return "" }
        var element: String = ""
        Realm.queue.sync {
            element = realm.objects(RealmBlacklistedDcc.self)[(0..<realm.objects(RealmBlacklistedDcc.self).count).randomElement()!].hashString
        }
        return element
    }
    
    func dccBlacklistSize() -> Int {
        guard let realm = realm else { return 0 }
        var count: Int = 0
        Realm.queue.sync {
            count = realm.objects(RealmBlacklistedDcc.self).count
        }
        return count
    }
}

// MARK: - 2dDoc Blacklist -
public extension StorageManager {
    
    // Get if 2dDoc is in blacklist
    func isBlacklisted2dDoc(_ docHash: String) -> Bool {
        var isBlacklisted: Bool = false
        Realm.queue.sync {
            isBlacklisted = realm?.object(ofType: RealmBlacklisted2dDoc.self, forPrimaryKey: docHash) != nil
        }
        return isBlacklisted
    }
    
    // Get content of blacklist
    func blacklist2dDoc() -> [String] {
        guard let realm = realm else { return [] }
        var hashes: [String] = []
        Realm.queue.sync {
            hashes = realm.objects(RealmBlacklisted2dDoc.self).map { $0.hashString }
        }
        return hashes
    }
    
    // Delete all the content of the blacklist
    func delete2dDocBlacklist() {
        guard let realm = realm else { return }
        Realm.queue.sync {
            try! realm.write {
                realm.delete(realm.objects(RealmBlacklisted2dDoc.self))
            }
        }
    }
    
    // Update balcklist with new or existing 2dDocs
    func update2dDocBlacklist(_ hashes: [String]) {
        guard let realm = realm else { return }
        Realm.queue.sync {
            try! realm.write {
                realm.add(hashes.compactMap { RealmBlacklisted2dDoc(hash: $0) }, update: .modified)
            }
        }
    }
    
    // Remove an array of 2dDocs from blacklist
    func delete2dDocsFromBlacklist(_ docHashes: [String]) {
        guard let realm = realm else { return }
        Realm.queue.sync {
            let docsToDelete: [RealmBlacklisted2dDoc] = realm.objects(RealmBlacklisted2dDoc.self).filter({ docHashes.contains($0.hashString) })
            guard !docsToDelete.isEmpty else { return }
            try! realm.write {
                realm.delete(docsToDelete)
            }
        }
    }
}

public extension StorageManager {

    func saveVenueQrCodeInfo(_ venueQrCodeInfo: VenueQrCodeInfo) {
        guard let realm = realm else { return }
        Realm.queue.sync {
            let realmVenueQrCodeInfo: RealmVenueQrCodeInfo = RealmVenueQrCodeInfo.from(venueQrCodeInfo: venueQrCodeInfo)
            try! realm.write {
                realm.add(realmVenueQrCodeInfo, update: .all)
            }
        }
        notifyVenueQrCodeDataChanged()
    }

    func deleteVenueQrCodeInfo(_ venueQrCodeInfo: VenueQrCodeInfo) {
        guard let realm = realm else { return }
        Realm.queue.sync {
            guard let realmVenueQrCodeInfo = realm.object(ofType: RealmVenueQrCodeInfo.self, forPrimaryKey: venueQrCodeInfo.id) else { return }
            try! realm.write {
                loggingHandler(formatLog(type: .deletion(.realm), message: "one venue QRCode info"))
                realm.delete(realmVenueQrCodeInfo)
            }
        }
        notifyVenueQrCodeDataChanged()
    }

    func venuesQrCodes() -> [VenueQrCodeInfo] {
        guard let realm = realm else { return [] }
        var venues: [VenueQrCodeInfo] = []
        Realm.queue.sync {
            venues = realm.objects(RealmVenueQrCodeInfo.self).map { $0.toVenueQrCodeInfo() }
        }
        return venues
    }

    func deleteVenuesQrCodeData() {
        guard let realm = realm else { return }
        Realm.queue.sync {
            try! realm.write {
                loggingHandler(formatLog(type: .deletion(.realm), message: "all venue QRCode info"))
                realm.delete(realm.objects(RealmVenueQrCodeInfo.self))
            }
        }
        notifyVenueQrCodeDataChanged()
    }

    func deleteExpiredVenuesQrCodeData(durationInSeconds: Double) {
        guard let realm = realm else { return }
        let now: Date = Date()
        Realm.queue.sync {
            let expiredVenueQrCodeInfoList: [RealmVenueQrCodeInfo] = [RealmVenueQrCodeInfo](realm.objects(RealmVenueQrCodeInfo.self)).filter { venueQrCodeInfo in
                (Double(now.timeIntervalSince1900) - Double(venueQrCodeInfo.ntpTimestamp)) >= durationInSeconds
            }
            if !expiredVenueQrCodeInfoList.isEmpty {
                try! realm.write {
                    loggingHandler(formatLog(type: .deletion(.realm), message: "expired venue QRCode info"))
                    realm.delete(expiredVenueQrCodeInfoList)
                }
            }        }
        notifyVenueQrCodeDataChanged()
    }

}

public extension StorageManager {
    
    func saveWalletCertificate(_  certificate: RawWalletCertificate) {
        guard let realm = realm else { return }
        Realm.queue.sync {
            let realmRawWalletCertificate: RealmRawWalletCertificate = RealmRawWalletCertificate.from(rawCertificate: certificate)
            try! realm.write {
                realm.add(realmRawWalletCertificate, update: .all)
            }
        }
        notifyWalletCertificateDataChanged()
    }

    func saveWalletCertificates(_  certificates: [RawWalletCertificate]) {
        guard let realm = realm else { return }
        Realm.queue.sync {
            let realmRawWalletCertificates: [RealmRawWalletCertificate] = certificates.map { RealmRawWalletCertificate.from(rawCertificate: $0) }
            try! realm.write {
                realm.add(realmRawWalletCertificates, update: .all)
            }
        }
        notifyWalletCertificateDataChanged()
    }
    
    func walletCertificates() -> [RawWalletCertificate] {
        guard let realm = realm else { return [] }
        var certificates: [RawWalletCertificate] = []
        Realm.queue.sync {
            certificates = realm.objects(RealmRawWalletCertificate.self).map { $0.toRawWalletCertificate() }
        }
        return certificates
    }
    
    func deleteWalletCertificate(id: String) {
        guard let realm = realm else { return }
        Realm.queue.sync {
            if let realmRawWalletCertificate = realm.object(ofType: RealmRawWalletCertificate.self, forPrimaryKey: id) {
                try! realm.write {
                    loggingHandler(formatLog(type: .deletion(.realm), message: "one wallet certificate"))
                    realm.delete(realmRawWalletCertificate)
                }
            }
        }
        notifyWalletCertificateDataChanged()
    }

    func deleteWalletCertificates(ids: [String]) {
        guard let realm = realm else { return }
        Realm.queue.sync {
            let realmRawWalletCertificates: [RealmRawWalletCertificate] = realm.objects(RealmRawWalletCertificate.self).filter { ids.contains($0.id) }
            
            if !realmRawWalletCertificates.isEmpty {
                try! realm.write {
                    loggingHandler(formatLog(type: .deletion(.realm), message: "\(realmRawWalletCertificates.count) wallet certificate(s)"))
                    realm.delete(realmRawWalletCertificates)
                }
            }
        }
        notifyWalletCertificateDataChanged()
    }
    
    func deleteWalletCertificates() {
        guard let realm = realm else { return }
        Realm.queue.sync {
            try! realm.write {
                loggingHandler(formatLog(type: .deletion(.realm), message: "all wallet certificates"))
                realm.delete(realm.objects(RealmRawWalletCertificate.self))
            }
        }
        notifyWalletCertificateDataChanged()
    }
    
}

private extension StorageManager {
    
    func notifyStatusDataChanged() {
        NotificationCenter.default.post(name: .statusDataDidChange, object: nil)
    }
    
    func notifyLocalProximityDataChanged() {
        NotificationCenter.default.post(name: .localProximityDataDidChange, object: nil)
    }
    
    func notifyAttestationDataChanged() {
        NotificationCenter.default.post(name: .attestationDataDidChange, object: nil)
    }

    func notifyVenueQrCodeDataChanged() {
        NotificationCenter.default.post(name: .venueQrCodeDataDidChange, object: nil)
    }
    
    func notifyWalletCertificateDataChanged() {
        NotificationCenter.default.post(name: .walletCertificateDataDidChange, object: nil)
    }
}

// MARK: - Logger -
private extension StorageManager {
    enum LogType {
        case deletion(_ type: DeletionType)
        
        enum DeletionType: String {
            case realm = "Realm"
            case keychain = "Keychain"
        }
        
        var description: String {
            switch self {
            case .deletion(let type):
                return ["Deletion", type.rawValue].joined(separator: "|")
            }
        }
    }
    
    func isWiped() -> Bool {
        // Check if keychain contains db key
        guard !keychain.allKeys.contains("SC\(KeychainKey.dbKey.rawValue)") else { return false }
        // Check if Realm db exist
        let isWiped = realm == nil
        // save that info
        if isWiped {
            wasWiped = true
        }
        return isWiped
    }
    
    func formatIsWiped() -> String? {
        isWiped() ? "?????? WIPED" : nil
    }
    
    func formatLog(type: LogType, message: String) -> String {
        [type.description, message, formatIsWiped()].compactMap { $0 }.joined(separator: "|")
    }
}

private extension Realm {
    
    static let queue: DispatchQueue = DispatchQueue(label: "RealmQueue", qos: .userInitiated)

    static func db(key: Data?) throws -> Realm {
        guard let key = key else { throw NSError.stLocalizedError(message: "Impossible to decrypt the database", code: 0) }
        return try Self.queue.sync { try Realm(configuration: configuration(key: key), queue: Self.queue) }
    }
    
    static func deleteDb() {
        try? FileManager.default.removeItem(at: dbsDirectoryUrl().appendingPathComponent("db.realm"))
        try? FileManager.default.removeItem(at: dbsDirectoryUrl().appendingPathComponent("db.lock"))
        try? FileManager.default.removeItem(at: dbsDirectoryUrl().appendingPathComponent("db.note"))
        try? FileManager.default.removeItem(at: dbsDirectoryUrl().appendingPathComponent("db.management"))
    }
    
    static func generateEncryptionKey() -> Data? {
        var keyData: Data = Data(count: 64)
        let result: Int32 = keyData.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 64, $0.baseAddress!) }
        return result == errSecSuccess ? keyData : nil
    }
    
    static private func dbsDirectoryUrl() -> URL {
        var directoryUrl: URL = FileManager.stLibraryDirectory().appendingPathComponent("DBs")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
            try? directoryUrl.stAddSkipBackupAttribute()
        }
        return directoryUrl
    }
    
    static private func configuration(key: Data) -> Realm.Configuration {
        let classes: [Object.Type] = [RealmEpoch.self,
                                      RealmLocalProximity.self,
                                      RealmAttestation.self,
                                      RealmVenueQrCodeInfo.self,
                                      RealmRawWalletCertificate.self,
                                      RealmBlacklistedDcc.self,
                                      RealmBlacklisted2dDoc.self]
        let databaseUrl: URL = dbsDirectoryUrl().appendingPathComponent("db.realm")
        let userConfig: Realm.Configuration = Realm.Configuration(fileURL: databaseUrl, encryptionKey: key, schemaVersion: 24, migrationBlock: { _, _ in }, objectTypes: classes)
        return userConfig
    }
    
}
