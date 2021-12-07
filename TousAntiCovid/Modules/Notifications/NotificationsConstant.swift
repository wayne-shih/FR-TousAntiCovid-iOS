// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NotificationsConstant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 27/05/2020 - for the TousAntiCovid project.
//


import UIKit

enum NotificationsConstant {
 
    enum Identifier {
        static let atRisk: String = "atRiskNotification"
        static let error: String = "errorNotification"
        static let deviceTimeError: String = "deviceTimeErrorNotification"
        static let ultimate: String = "ultimateNotification"
        static let proximityReactivation: String = "proximityReactivationNotification"
        static let stillHavingFever: String = "stillHavingFever"
        static let completedVaccination: String = "completedVaccination"
        static let activityPassAvailable: String = "activityPassAvailable"
    }
    
}
