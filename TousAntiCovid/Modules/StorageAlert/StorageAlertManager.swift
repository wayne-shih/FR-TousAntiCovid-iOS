// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StorageAlertManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 22/10/2021 - for the TousAntiCovid project.
//

import UIKit
import StorageSDK

final class StorageAlertManager {
    static let shared: StorageAlertManager = StorageAlertManager()
    
    private weak var storageManager: StorageManager?
    
    @UserDefault(key: .lastStorageAlertDisplayBuildNumber)
    private var lastStorageAlertDisplayBuildNumber: Int?
    
    var storageLimit: Int64 = 0
    
    func start(with storageManager: StorageManager, storageLimitMo: Int64 = 300) {
        self.storageManager = storageManager
        addNotification()
    }
}

// MARK: - Storage Alert type
extension StorageAlertManager {
    enum StorageAlertType {
        case storage
        case wipedDatabase
    }
}

// MARK: - Alert display management
private extension StorageAlertManager {
    func alertToDisplay() -> StorageAlertType? {
        if shouldDisplayWipedDatabaseAlert {
            return .wipedDatabase
        } else if shouldDisplayStorageAlert {
            return .storage
        } else {
            return nil
        }
    }
    
    func didDisplay(alert type: StorageAlertType) {
        switch type {
        case .storage:
            didDisplayStorageAlert()
        case .wipedDatabase:
            didDisplayWipedAlert()
        }
    }
}

// MARK: - Storage management
private extension StorageAlertManager {
    var currentAvailableSpace: UInt64 { UInt64(abs(FileManager.default.opportunisticAvailableDiskSpace ?? 0)) }
    
    var storageAlertAlreadyDisplayed: Bool {
        guard let lastBuildNumber = lastStorageAlertDisplayBuildNumber else { return false }
        return lastBuildNumber >= Int(UIApplication.shared.buildNumber) ?? 0
    }
    
    var shouldDisplayStorageAlert: Bool { !storageAlertAlreadyDisplayed && currentAvailableSpace <= storageLimit }
    
    func didDisplayStorageAlert() {
        lastStorageAlertDisplayBuildNumber = Int(UIApplication.shared.buildNumber) ?? 0
    }
}

// MARK: - Wiped database management
private extension StorageAlertManager {
    var shouldDisplayWipedDatabaseAlert: Bool { storageManager?.wasWiped ?? false }
    
    func didDisplayWipedAlert() {
        storageManager?.resetWasWiped()
    }
}

// MARK: - didBecomeActiveNotification management
private extension StorageAlertManager {
    func addNotification() {
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.notifyIfNecessary()
        }
    }
    
    func notifyIfNecessary() {
        guard let alertType = alertToDisplay() else { return }
        notifyObservers(toDisplay: alertType)
    }
}

// MARK: - Observers management
extension StorageAlertManager {
    private func notifyObservers(toDisplay alertType: StorageAlertType) {
        NotificationCenter.default.post(name: .shouldShowStorageAlert, object: alertType)
        didDisplay(alert: alertType)
    }
}
