// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Blacklist2dDocManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/07/2021 - for the TousAntiCovid project.
//

import UIKit
import StorageSDK

final class Blacklist2dDocManager: BlacklistManager {
    static let shared: Blacklist2dDocManager = Blacklist2dDocManager()

    weak var storageManager: StorageManager?
    var baseUrl: String { Blacklist2dDocConstant.baseUrl }
    var filename: String { Blacklist2dDocConstant.filename }
    
    @UserDefault(key: .last2dDocBlacklistVersionNumber)
    var lastBlacklistVersionNumber: Int = 0
    
    deinit {
        removeNotifications()
    }
    
    func start(storageManager: StorageManager) {
        self.storageManager = storageManager
        addNotifications()
    }

    func isBlacklisted(certificate: WalletCertificate) -> Bool {
        guard let uniqueHash = certificate.uniqueHash else { return false }
        return storageManager?.isBlacklisted2dDoc(uniqueHash) ?? false
    }
}

// MARK: - Realm Persistence -
extension Blacklist2dDocManager {
    func updateBlacklist(addedOrUpdated: [String], removed: [String]) {
        if !removed.isEmpty {
            storageManager?.delete2dDocsFromBlacklist(removed)
        }
        if !addedOrUpdated.isEmpty {
            storageManager?.update2dDocBlacklist(addedOrUpdated)
        }
    }
}
