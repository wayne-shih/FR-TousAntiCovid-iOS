// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NSNotification+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 14/04/2020 - for the TousAntiCovid project.
//

import UIKit

extension NSNotification.Name {
    
    static var selectTab: NSNotification.Name { NSNotification.Name(rawValue: "selectTab") }
    static var changeAppState: NSNotification.Name { NSNotification.Name(rawValue: "changeAppState") }
    static let didTouchProximityReactivationNotification: NSNotification.Name = NSNotification.Name(rawValue: "didTouchProximityReactivationNotification")
    static let didEnterCodeFromDeeplink: NSNotification.Name = NSNotification.Name(rawValue: "didEnterCodeFromDeeplink")
    static let newAttestationFromDeeplink: NSNotification.Name = NSNotification.Name(rawValue: "newAttestationFromDeeplink")
    static let requestRegister: NSNotification.Name = NSNotification.Name(rawValue: "requestRegister")
    static let dismissAllAndShowRecommandations: NSNotification.Name = NSNotification.Name(rawValue: "dismissAllAndShowRecommandations")
    static let newVenueRecordingFromDeeplink: NSNotification.Name = NSNotification.Name(rawValue: "newVenueRecordingFromDeeplink")
    static let openFullVenueRecordingFlowFromDeeplink: NSNotification.Name = NSNotification.Name(rawValue: "openFullVenueRecordingFlowFromDeeplink")
    static let newWalletCertificateFromDeeplink: NSNotification.Name = NSNotification.Name(rawValue: "newWalletCertificateFromDeeplink")
    static let lastAvailableBuildDidUpdate: NSNotification.Name = NSNotification.Name(rawValue: "lastAvailableBuildDidUpdate")
    static let openQrScan: NSNotification.Name = NSNotification.Name(rawValue: "openQrScan")
    static let didCompletedVaccinationNotification: NSNotification.Name = NSNotification.Name(rawValue: "didCompletedVaccinationNotification")
    static let openWallet: NSNotification.Name = NSNotification.Name(rawValue: "openWallet")
    static let openCertificateQRCode: Notification.Name = Notification.Name(rawValue: "openCertificateQRCode")
    static let gotRobert430Error: Notification.Name = Notification.Name(rawValue: "gotRobert430Error")
    static let shouldShowStorageAlert: Notification.Name = Notification.Name(rawValue: "shouldShowStorageAlert")
    static let openSmartWalletFromNotification: NSNotification.Name = NSNotification.Name(rawValue: "openSmartWalletFromNotification")
}
