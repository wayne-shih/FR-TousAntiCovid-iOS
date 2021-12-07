// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DccBlacklistManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/07/2021 - for the TousAntiCovid project.
//

import UIKit
import StorageSDK

final class DccBlacklistManager: BlacklistManager {
    
    static let shared: DccBlacklistManager = DccBlacklistManager()

    weak var storageManager: StorageManager?
    var baseUrl: String { DccBlacklistConstant.baseUrl }
    var filename: String { DccBlacklistConstant.filename }
    
    @UserDefault(key: .lastDccBlacklistVersionNumber)
    var lastBlacklistVersionNumber: Int = 0
    
    deinit {
        removeNotifications()
    }
    
    func start(storageManager: StorageManager) {
        self.storageManager = storageManager
        addNotifications()
    }

    func isBlacklisted(certificate: WalletCertificate) -> Bool {
        guard let cert = certificate as? EuropeanCertificate else { return false }
        return storageManager?.isBlacklistedDcc(cert.uniqueHash) ?? false
    }
}

// MARK: - Realm Persistence -
extension DccBlacklistManager {
    func updateBlacklist(addedOrUpdated: [String], removed: [String]) {
        if !removed.isEmpty {
            storageManager?.deleteDccsFromBlacklist(removed)
        }
        if !addedOrUpdated.isEmpty {
            storageManager?.updateDccBlacklist(addedOrUpdated)
        }
    }
}
