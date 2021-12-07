// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StorageAlertType+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 22/10/2021 - for the TousAntiCovid project.
//

extension StorageAlertManager.StorageAlertType {
    var localizedDescription: String {
        switch self {
        case .storage:
            return "storageAlertScreen.storageAlert.description".localized
        case .wipedDatabase:
            return "storageAlertScreen.wipedAlert.description".localized
        }
    }
    
    var localizedConfirmationButtonTitle: String { "common.ok".localized }
}
