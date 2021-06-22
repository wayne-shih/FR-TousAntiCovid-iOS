// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StatusManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/02/2021 - for the TousAntiCovid project.
//

import UIKit
import RobertSDK
import ServerSDK
import StorageSDK

protocol StatusChangesObserver: AnyObject {
    
    func statusRiskLevelDidChange()
    
}

final class StatusObserverWrapper: NSObject {
    
    weak var observer: StatusChangesObserver?
    
    init(observer: StatusChangesObserver) {
        self.observer = observer
    }
    
}

final class StatusManager {
    
    static let shared: StatusManager = StatusManager()
    
    @UserDefault(key: .hideStatus)
    var hideStatus: Bool = false {
        didSet { notifyStatusChange() }
    }
    
    var currentStatusRiskLevel: RBStatusRiskLevelInfo? {
        get { RBManager.shared.currentStatusRiskLevel }
        set {
            if currentStatusRiskLevel?.riskLevel != newValue?.riskLevel {
                hideStatus = false
            }
            RBManager.shared.currentStatusRiskLevel = newValue
        }
    }
    
    @UserDefault(key: .cleaLastIteration)
    var cleaLastIteration: Int?

    var lastRobertStatusRiskLevel: RBStatusRiskLevelInfo? {
        get { RBManager.shared.lastRobertStatusRiskLevel }
        set { RBManager.shared.lastRobertStatusRiskLevel = newValue }
    }
    
    var lastCleaStatusRiskLevel: RBStatusRiskLevelInfo? {
        get { storageManager.lastCleaStatusRiskLevel() }
        set { storageManager.saveLastCleaStatusRiskLevel(newValue) }
    }

    var isAtRisk: Bool { currentStatusRiskLevel?.riskLevel ?? 0.0 >= ParametersManager.shared.isolationMinRiskLevel }
    var isStatusOnGoing: Bool = false {
        didSet {
            if oldValue != isStatusOnGoing { notifyStatusChange() }
        }
    }

    private let statusModelVersion: Int = 1
    
    @UserDefault(key: .currentStatusModelVersion)
    private var currentStatusModelVersion: Int = 0
    
    private var lastStatusTriggerEventTimestamp: TimeInterval = 0.0
    private var mustNotifyLastRiskLevelChange: Bool = false

    private var mustShowAlertAboutLastRiskLevelChange: Bool = false
    private var observers: [StatusObserverWrapper] = []
    private var storageManager: StorageManager!

    func start(storageManager: StorageManager) {
        self.storageManager = storageManager
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        migrateOldAtRiskIfNeeded()
    }
    
    func status(showNotifications: Bool = false, force: Bool = false, completion: ((_ error: Error?) -> ())? = nil) {
        guard RBManager.shared.isRegistered else {
            completion?(nil)
            return
        }
        let nowTimestamp: TimeInterval = Date().timeIntervalSince1970
        guard nowTimestamp - lastStatusTriggerEventTimestamp > Constant.secondsBeforeStatusRetry || force else {
            let error: Error = NSError.localizedError(message: "lastStatusTriggerEventTimestamp registered less than \(Int(Constant.secondsBeforeStatusRetry)) seconds ago", code: 0)
            completion?(error)
            return
        }
        self.lastStatusTriggerEventTimestamp = nowTimestamp

        var robertStatusInfo: Result<RBStatusRiskLevelInfo?, Error> = .success(nil)
        var cleaStatusInfo: Result<RBStatusRiskLevelInfo?, Error> = .success(nil)

        let dispatchGroup: DispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        triggerStatusRequestIfNeeded(showNotifications: showNotifications, force: force) { statusResult in
            robertStatusInfo = statusResult
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        triggerCleaStatusRequestIfNeeded(force: force) { cleaStatusResult in
            cleaStatusInfo = cleaStatusResult
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            self.isStatusOnGoing = false
            self.processReceivedStatusInfo(statusInfo: robertStatusInfo, cleaStatusInfo: cleaStatusInfo)

            var error: Error?
            if case let .failure(robertError) = robertStatusInfo {
                error = robertError
            } else if case let .failure(cleaError) = cleaStatusInfo {
                error = cleaError
            }
            completion?(error)
        }
    }
    
}

extension StatusManager {
    
    func addObserver(_ observer: StatusChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(StatusObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: StatusChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: StatusChangesObserver) -> StatusObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
    private func notifyObservers() {
        observers.forEach { $0.observer?.statusRiskLevelDidChange() }
    }
    
}

// MARK: - Migration management -
extension StatusManager {
    
    private func migrateOldAtRiskIfNeeded() {
        guard currentStatusModelVersion != statusModelVersion else { return }
        currentStatusModelVersion = statusModelVersion
        guard currentStatusRiskLevel == nil else { return }
        guard let lastRiskReceivedDate = RBManager.shared.lastRiskReceivedDate else {
            if RBManager.shared.lastStatusReceivedDate != nil {
                currentStatusRiskLevel = RBStatusRiskLevelInfo(riskLevel: 0.0, lastContactDate: nil, lastRiskScoringDate: nil)
            }
            return
        }
        let periodEndDate: Date = lastRiskReceivedDate.dateByAddingDays(ParametersManager.shared.quarantinePeriod)
        let now: Date = Date()
        if now < periodEndDate {
            currentStatusRiskLevel = RBStatusRiskLevelInfo(riskLevel: 4.0, lastContactDate: lastRiskReceivedDate, lastRiskScoringDate: nil)
        } else {
            currentStatusRiskLevel = RBStatusRiskLevelInfo(riskLevel: 0.0, lastContactDate: nil, lastRiskScoringDate: nil)
        }
        RBManager.shared.lastRiskReceivedDate = nil
    }
    
}

// MARK: - Status triggering requests -
extension StatusManager {
    
    private func triggerStatusRequestIfNeeded(showNotifications: Bool = false, force: Bool = false, completion: ((_ result: Result<RBStatusRiskLevelInfo?, Error>) -> ())? = nil) {
        let lastStatusErrorTimestamp: Double = RBManager.shared.lastStatusErrorDate?.timeIntervalSince1970 ?? 0.0
        let lastStatusSuccessTimestamp: Double = RBManager.shared.lastStatusReceivedDate?.timeIntervalSince1970 ?? 0.0
        let mostRecentResponseTimestamp: Double = max(lastStatusErrorTimestamp, lastStatusSuccessTimestamp)
        let nowTimestamp: Double = Date().timeIntervalSince1970
        if (nowTimestamp - mostRecentResponseTimestamp >= ParametersManager.shared.minStatusRetryTimeInterval && nowTimestamp - lastStatusSuccessTimestamp >= ParametersManager.shared.statusTimeInterval) || force {
            switch ParametersManager.shared.apiVersion {
            case .v5, .v6:
                isStatusOnGoing = true
                RBManager.shared.status { result in
                    switch result {
                    case let .success(info):
                        if showNotifications {
                            self.processStatusResponseNotification(error: nil)
                        }
                        AnalyticsManager.shared.statusDidSucceed()
                        NotificationsManager.shared.scheduleUltimateNotification(minHour: ParametersManager.shared.minHourContactNotif, maxHour: ParametersManager.shared.maxHourContactNotif)

                        completion?(.success(info))
                    case let .failure(error):
                        AnalyticsManager.shared.reportError(serviceName: "status", apiVersion: ParametersManager.shared.apiVersion, code: (error as NSError).code)
                        if showNotifications {
                            self.processStatusResponseNotification(error: error)
                        }
                        completion?(.failure(error))
                    }
                }
            }
        } else {
            if showNotifications {
                self.processStatusResponseNotification(error: nil)
            }
            let retryCriteria: String = "Current: \(Int(nowTimestamp - mostRecentResponseTimestamp)) | Expected: \(Int(ParametersManager.shared.minStatusRetryTimeInterval))"
            let timeCriteria: String = "Current: \(Int(nowTimestamp - lastStatusSuccessTimestamp)) | Expected: \(Int(ParametersManager.shared.statusTimeInterval))"
            let error: Error = NSError.localizedError(message: "Last status requested/received too recently:\n\n-----\nRetry\n-----\n\(retryCriteria)\n\n--------\nMin time\n--------\n\(timeCriteria)", code: 0)
            completion?(.failure(error))
        }
    }
    
    private func triggerCleaStatusRequestIfNeeded(force: Bool = false, completion: ((_ result: Result<RBStatusRiskLevelInfo?, Error>) -> ())? = nil) {
        let lastCleaStatusErrorTimestamp: Double = storageManager.lastCleaStatusErrorDate()?.timeIntervalSince1970 ?? 0.0
        let lastCleaStatusSuccessTimestamp: Double = storageManager.lastCleaStatusReceivedDate()?.timeIntervalSince1970 ?? 0.0
        let mostRecentResponseTimestamp: Double = max(lastCleaStatusErrorTimestamp, lastCleaStatusSuccessTimestamp)
        let nowTimestamp: Double = Date().timeIntervalSince1970
        if (nowTimestamp - mostRecentResponseTimestamp >= ParametersManager.shared.minStatusRetryTimeInterval && nowTimestamp - lastCleaStatusSuccessTimestamp >= ParametersManager.shared.statusTimeInterval) || force {

            let now: Date = Date()
            let qrCodes: [VenueQrCodeInfo] = VenuesManager.shared.venuesQrCodes.filter { $0.ntpTimestamp <= now.timeIntervalSince1900 }
            guard !qrCodes.isEmpty else {
                completion?(.success(nil))
                return
            }
            let cleaStatusStartDate: Date = Date()
            let ltids: [String] = qrCodes.map { $0.ltid }
            isStatusOnGoing = true
            fetchNeededClusterPrefixes(ltids: ltids) { result in
                switch result {
                case let .success(matchingPrefixes):
                    CleaServer.shared.getAllCleaClusters(for: matchingPrefixes, iteration: self.cleaLastIteration ?? 0) { result in
                        switch result {
                        case let .success(clusters):
                            let clustersForLtids: [CleaServerStatusCluster] = clusters.filter { ltids.contains($0.ltid) }

                            let matchingClusters: [CleaServerStatusCluster] = self.matchingClusters(clusters: clustersForLtids, venueQrCodeInfos: qrCodes)
                            let newStatusRiskLevelInfo: RBStatusRiskLevelInfo? = self.newRiskStatus(clusters: matchingClusters)
                            self.sendCleaStatusAnalytics(startDate: cleaStatusStartDate)
                            self.storageManager.saveLastCleaStatusReceivedDate(Date())
                            self.storageManager.saveLastCleaStatusErrorDate(nil)
                            completion?(.success(newStatusRiskLevelInfo))
                        case let .failure(error):
                            AnalyticsManager.shared.reportError(serviceName: "wStatus", apiVersion: ParametersManager.shared.cleaStatusApiVersion, code: (error as NSError).code)
                            self.storageManager.saveLastCleaStatusErrorDate(Date())
                            completion?(.failure(error))
                        }
                    }
                case let .failure(error):
                    AnalyticsManager.shared.reportError(serviceName: "wStatus", apiVersion: ParametersManager.shared.cleaStatusApiVersion, code: (error as NSError).code)
                    self.storageManager.saveLastCleaStatusErrorDate(Date())
                    completion?(.failure(error))
                }
            }
        } else {
            let retryCriteria: String = "Current: \(Int(nowTimestamp - mostRecentResponseTimestamp)) | Expected: \(Int(ParametersManager.shared.minStatusRetryTimeInterval))"
            let timeCriteria: String = "Current: \(Int(nowTimestamp - lastCleaStatusSuccessTimestamp)) | Expected: \(Int(ParametersManager.shared.statusTimeInterval))"
            let error: Error = NSError.localizedError(message: "Last Clea status requested/received too recently:\n\n-----\nRetry\n-----\n\(retryCriteria)\n\n--------\nMin time\n--------\n\(timeCriteria)", code: 0)
            completion?(.failure(error))
        }
    }
}

// MARK: - Clea Management -
extension StatusManager {
    
    private func fetchNeededClusterPrefixes(ltids: [String], _ completion: @escaping (Result<[String], Error>) -> ()) {
        CleaServer.shared.getClusterIndex { result in
            switch result {
            case let .success(cleaClusterIndex):
                guard let cleaClusterIndex = cleaClusterIndex else {
                    completion(.success([]))
                    return
                }
                
                // cleaLastIteration is set to nil after adding VenueQRCodeInfo
                guard self.cleaLastIteration == nil || cleaClusterIndex.iteration > self.cleaLastIteration ?? 0 else {
                    completion(.success([]))
                    return
                }
                self.cleaLastIteration = cleaClusterIndex.iteration
                let matchingPrefixes: [String] = self.matchingClusterPrefixes(for: ltids, clusterIndex: cleaClusterIndex)
                completion(.success(matchingPrefixes))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    private func matchingClusterPrefixes(for ltids: [String], clusterIndex: CleaServerStatusClusterIndex) -> [String] {
        clusterIndex.clusterPrefixes.filter { clusterPrefix in
            return ltids.first { $0.starts(with: clusterPrefix) } != nil
        }
    }
    
    private func matchingClusters(clusters: [CleaServerStatusCluster]?, venueQrCodeInfos: [VenueQrCodeInfo]) -> [CleaServerStatusCluster] {
        var clustersWithTimeMatch: [CleaServerStatusCluster] = []
        clusters?.forEach { cluster in
            venueQrCodeInfos.forEach { venueQrCodeInfo in
                guard cluster.ltid == venueQrCodeInfo.ltid  else { return }
                let timeMatchingExposures: [CleaServerStatusClusterExposure] = cluster.exposures.filter { exposure in
                    exposure.ntpTimestamp <= venueQrCodeInfo.ntpTimestamp
                        && venueQrCodeInfo.ntpTimestamp <= exposure.ntpTimestamp + exposure.duration
                }
                guard !timeMatchingExposures.isEmpty else { return }
                clustersWithTimeMatch.append(CleaServerStatusCluster(ltid: venueQrCodeInfo.ltid, exposures: timeMatchingExposures))
            }
        }
        return clustersWithTimeMatch
    }
    
    private func newRiskStatus(clusters: [CleaServerStatusCluster]?) -> RBStatusRiskLevelInfo? {
        var currentRiskLevel: Double?
        var currentNtpTimestamp: Int?
        clusters?.forEach { cluster in
            cluster.exposures.forEach { exposure in
                if exposure.riskLevel > currentRiskLevel ?? 0.0 {
                    currentRiskLevel = exposure.riskLevel
                    currentNtpTimestamp = exposure.ntpTimestamp
                } else if exposure.riskLevel ==  currentRiskLevel, exposure.ntpTimestamp > currentNtpTimestamp ?? 0 {
                    currentNtpTimestamp = exposure.ntpTimestamp
                }
            }
        }
        
        if let currentRiskLevel = currentRiskLevel {
            var lastContactDate: Date?
            if let lastContactDateTimestamp = currentNtpTimestamp {
                lastContactDate = min(Date(timeIntervalSince1900: lastContactDateTimestamp).svDateByAddingDays([-1, 1].randomElement() ?? 0), Date().svDateByAddingDays(-1))
            }
            return RBStatusRiskLevelInfo(riskLevel: currentRiskLevel, lastContactDate: lastContactDate, lastRiskScoringDate: lastContactDate)
        } else {
            return nil
        }
    }

    private func sendCleaStatusAnalytics(startDate: Date) {
        let appStatus: String = UIApplication.shared.applicationState == .active ? "f" : "b"
        let cleaStatusDuration: Int = Int((Date().timeIntervalSince1970 - startDate.timeIntervalSince1970) * 1000.0)
        AnalyticsManager.shared.reportAppEvent(.e15, description: "\(appStatus) \(cleaStatusDuration)")
    }
    
}

// MARK: - Status response processing -
extension StatusManager {
    
    private func processStatusResponseNotification(error: Error?) {
        let minHoursBetweenNotif: Int = ParametersManager.shared.minHoursBetweenVisibleNotif
        if error != nil {
            NotificationsManager.shared.triggerRestartNotification()
        } else {
            guard ParametersManager.shared.pushDisplayAll else { return }
            if RBManager.shared.isProximityActivated {
                guard ParametersManager.shared.pushDisplayOnSuccess else { return }
                NotificationsManager.shared.triggerProximityServiceRunningNotification(minHoursBetweenNotif: minHoursBetweenNotif)
            } else {
                NotificationsManager.shared.triggerProximityServiceNotRunningNotification(minHoursBetweenNotif: minHoursBetweenNotif)
            }
        }
    }
    
    private func processReceivedStatusInfo(statusInfo: Result<RBStatusRiskLevelInfo?, Error>, cleaStatusInfo: Result<RBStatusRiskLevelInfo?, Error>) {
        var isInError: Bool = false
        switch statusInfo {
        case .success(let statusRiskLevelInfo):
            if let statusInfo = statusRiskLevelInfo {
                if statusInfo.lastRiskScoringDate == nil || lastRobertStatusRiskLevel?.lastRiskScoringDate == nil || statusInfo.lastRiskScoringDate ?? .distantPast > lastRobertStatusRiskLevel?.lastRiskScoringDate ?? .distantPast {
                    lastRobertStatusRiskLevel = statusInfo
                }
            }
        case .failure:
            isInError = true
        }

        switch cleaStatusInfo {
        case .success(let statusRiskLevelInfo):
            if let cleaStatusInfo = statusRiskLevelInfo {
                if cleaStatusInfo.lastRiskScoringDate == nil || lastCleaStatusRiskLevel?.lastRiskScoringDate == nil || cleaStatusInfo.lastRiskScoringDate ?? .distantPast > lastCleaStatusRiskLevel?.lastRiskScoringDate ?? .distantPast {
                    lastCleaStatusRiskLevel = cleaStatusInfo
                }
            } else {
                lastCleaStatusRiskLevel = nil
            }
        case .failure:
            isInError = true
        }

        let newStatus: [RBStatusRiskLevelInfo] = [lastRobertStatusRiskLevel, lastCleaStatusRiskLevel].compactMap { $0 }
        guard let newMaxRiskLevelInfo = newStatus.max(\.riskLevel) else { return }
        guard !isInError || isInError && newMaxRiskLevelInfo.riskLevel > currentStatusRiskLevel?.riskLevel ?? 0.0 else { return }

        var newRiskLevelInfo: RBStatusRiskLevelInfo = newMaxRiskLevelInfo
        if RisksUIManager.shared.level(for: newRiskLevelInfo.riskLevel) == nil {
            newRiskLevelInfo.riskLevel = 0.0
        }

        if !RBManager.shared.isImmune {
            mustNotifyLastRiskLevelChange = (newRiskLevelInfo.riskLevel > currentStatusRiskLevel?.riskLevel ?? 0.0) || (newRiskLevelInfo.riskLevel != 0.0 && newRiskLevelInfo.riskLevel == currentStatusRiskLevel?.riskLevel && newRiskLevelInfo.lastRiskScoringDate ?? .distantPast > currentStatusRiskLevel?.lastRiskScoringDate ?? .distantPast)
            mustShowAlertAboutLastRiskLevelChange = newRiskLevelInfo.lastRiskScoringDate != currentStatusRiskLevel?.lastRiskScoringDate
            if mustNotifyLastRiskLevelChange || mustShowAlertAboutLastRiskLevelChange {
                AnalyticsManager.shared.reportAppEvent(.e2)
                AnalyticsManager.shared.reportHealthEvent(.eh2, description: "\(newRiskLevelInfo.riskLevel)")
            }
        }

        currentStatusRiskLevel = newRiskLevelInfo

        if UIApplication.shared.applicationState == .active {
            showRiskLevelUpdateAlertIfNeeded()
        } else {
            showRiskLevelUpdateNotificationIfNeeded()
        }

        notifyStatusChange()
        AnalyticsManager.shared.processAnalytics()
    }

    private func notifyStatusChange() {
        NotificationCenter.default.post(name: .statusDataDidChange, object: nil)
        notifyObservers()
    }
    
}

// MARK: - Status update notifications -
extension StatusManager {
    
    @objc private func appDidBecomeActive() {
        showRiskLevelUpdateAlertIfNeeded()
    }
    
    private func showRiskLevelUpdateNotificationIfNeeded() {
        guard !RBManager.shared.isImmune else { return }
        guard mustNotifyLastRiskLevelChange else { return }
        mustNotifyLastRiskLevelChange = false
        NotificationsManager.shared.cancelNotificationForIdentifier(NotificationsContant.Identifier.atRisk)
        NotificationsManager.shared.scheduleNotification(minHour: ParametersManager.shared.minHourContactNotif,
                                                         maxHour: ParametersManager.shared.maxHourContactNotif,
                                                         title: RisksUIManager.shared.currentLevel?.labels.notifTitle?.localized ?? "",
                                                         body: RisksUIManager.shared.currentLevel?.labels.notifBody?.localizedOrEmpty ?? "",
                                                         identifier: NotificationsContant.Identifier.atRisk,
                                                         badge: 1)
    }
    
    private func showRiskLevelUpdateAlertIfNeeded() {
        guard !RBManager.shared.isImmune else { return }
        guard mustShowAlertAboutLastRiskLevelChange else { return }
        mustShowAlertAboutLastRiskLevelChange = false
        NotificationsManager.shared.cancelNotificationForIdentifier(NotificationsContant.Identifier.atRisk)
        guard let title = RisksUIManager.shared.currentLevel?.labels.notifTitle else { return }
        guard let message = RisksUIManager.shared.currentLevel?.labels.notifBody else { return }
        UIApplication.shared.keyWindow?.rootViewController?.topPresentedController.showAlert(title: title.localized,
                                                                                             message: message.localized,
                                                                                             okTitle: "common.ok".localized)
    }
    
}
