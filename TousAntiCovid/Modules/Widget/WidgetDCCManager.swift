// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WidgetDCCManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 22/07/2021 - for the TousAntiCovid project.
//

import Foundation
import WidgetKit
#if !WIDGETDCC
import UIKit
#endif

@available(iOS 14.0, *)
final class WidgetDCCManager {
    
    static let shared: WidgetDCCManager = WidgetDCCManager()
    
    static let scheme: String = "tousanticovid"
    
    @WidgetDCCUserDefault(key: .bottomText)
    private var bottomText: String = ""
    
    @WidgetDCCUserDefault(key: .noCertificateText)
    var noCertificateText: String = ""
    
    @WidgetDCCUserDefault(key: .certificateQrCodeData)
    private var certificateQrCodeData: Data?

    @WidgetDCCUserDefault(key: .isOnboardingDone)
    var isOnboardingDone: Bool = false
    
    private init() {}
    
    #if !WIDGETDCC
    func processUserActivity(_ userActivity: NSUserActivity) {
        guard userActivity.activityType == "fr.gouv.stopcovid.ios.Widget.dcc" && isOnboardingDone else { return }
        NotificationCenter.default.post(name: WalletManager.shared.favoriteDccId.isNil ? .openWallet : .openCertificateQRCode , object: nil)
    }
    #endif
    
    func start() {
        #if !WIDGETDCC
        LocalizationsManager.shared.addObserver(self)
        WalletManager.shared.addObserver(self)
        initializeCertificateIfNeeded()
        reloadData()
        #endif
    }
    
    #if !WIDGETDCC
    private func initializeCertificateIfNeeded() {
        guard certificateQrCodeData.isNil && !WalletManager.shared.favoriteDccId.isNil else { return }
        updateCertificate()
    }

    private func updateCertificate() {
        if WalletManager.shared.favoriteDccId.isNil {
            certificateQrCodeData = nil
        } else {
            certificateQrCodeData = WalletManager.shared.favoriteCertificate?.codeImage?.jpegData(compressionQuality: 1.0)
        }
    }
    #endif

}

#if !WIDGETDCC
@available(iOS 14.0, *)
extension WidgetDCCManager: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        reloadData()
    }
    
    func reloadData() {
        bottomText = "widget.dcc.full".localized
        noCertificateText = "widget.dcc.empty".localized
        WidgetCenter.shared.reloadAllTimelines()
    }
}
#endif

#if !WIDGETDCC
@available(iOS 14.0, *)
extension WidgetDCCManager: WalletChangesObserver {
    func walletCertificatesDidUpdate() {}

    func walletFavoriteCertificateDidUpdate() {
        updateCertificate()
        reloadData()
    }
}
#endif
