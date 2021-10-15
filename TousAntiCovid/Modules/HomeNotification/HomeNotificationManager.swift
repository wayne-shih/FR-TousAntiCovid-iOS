// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  HomeNotificationManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/10/2021 - for the TousAntiCovid project.
//

import ServerSDK

final class HomeNotificationManager {
    static let shared: HomeNotificationManager = HomeNotificationManager()
    
    @UserDefault(key: .notifClosedVersion)
    private var versionClosed: Int?
    
    func wasAlreadyClosed(notification: HomeNotification) -> Bool {
        guard let versionClosed = versionClosed else { return false }
        return notification.version <= versionClosed
    }
    
    func close(notification: HomeNotification) {
        versionClosed = notification.version
    }
}
