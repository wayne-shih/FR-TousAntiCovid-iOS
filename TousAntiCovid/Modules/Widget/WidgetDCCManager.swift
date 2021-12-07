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
#if !WIDGET
import UIKit
import PKHUD
#endif

@available(iOS 14.0, *)
final class WidgetDCCManager {

    static let shared: WidgetDCCManager = WidgetDCCManager()

    static let scheme: String = "tousanticovid"

    @WidgetDCCUserDefault(key: .bottomText)
    private(set) var bottomText: String = ""

    @WidgetDCCUserDefault(key: .bottomTextActivityPass)
    private(set) var bottomTextActivityPass: String = ""

    @WidgetDCCUserDefault(key: .noCertificateText)
    private(set) var noCertificateText: String = ""

    @WidgetDCCUserDefault(key: .certificateQrCodeData)
    private(set) var certificateQrCodeData: Data?

    @WidgetDCCUserDefault(key: .certificateActivityQrCodeData)
    private(set) var certificateActivityQrCodeData: Data?

    @WidgetDCCUserDefault(key: .certificateActivityExpiryTimestamp)
    private(set) var certificateActivityExpiryTimestamp: Double?

    @WidgetDCCUserDefault(key: .currentlyDisplayedActivityCertificateTimestamp)
    var currentlyDisplayedActivityCertificateTimestamp: Double?

#if !WIDGET
    @WidgetDCCUserDefault(key: .isOnboardingDone)
    var isOnboardingDone: Bool = false

    private var needActivityCertificateRefreshAfterTouch: Bool = false

    private var certificateEligibleToActivityPass: Bool {
        guard let certificate = currentCertificate else { return false }
        return certificate.isEligibleToActivityCertificateGeneration && !DccBlacklistManager.shared.isBlacklisted(certificate: certificate)
    }

    private var timer: Timer?
    private var currentCertificate: EuropeanCertificate?
    private var currentActivityCertificate: ActivityCertificate?
    private var isHavingActivityCertificate: Bool { currentActivityCertificate != nil }
    private var wasCertificateValid: Bool = false
#endif

    private init() {}

#if !WIDGET
    func processUserActivity(_ userActivity: NSUserActivity) {
        guard userActivity.activityType == "fr.gouv.stopcovid.ios.Widget.dcc" && isOnboardingDone else { return }
        NotificationCenter.default.post(name: WalletManager.shared.favoriteDccId.isNil ? .openWallet : .openCertificateQRCode , object: nil)
        if certificateEligibleToActivityPass && currentlyDisplayedActivityCertificateTimestamp ?? 0.0 < Date().timeIntervalSince1970 {
            needActivityCertificateRefreshAfterTouch = true
        }
    }

    func start() {
        addObservers()
        updateCertificate()
        reloadData()
    }

    func showActivityCertificateRefreshConfirmationIfNeeded() {
        guard needActivityCertificateRefreshAfterTouch else { return }
        needActivityCertificateRefreshAfterTouch = false
        HUD.flash(.labeledSuccess(title: "activityPass.fullscreen.upToDate".localized, subtitle: nil), delay: 2.0)
    }

    private func addObservers() {
        LocalizationsManager.shared.addObserver(self)
        WalletManager.shared.addObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func updateCertificate() {
        if let certificate = WalletManager.shared.favoriteCertificate as? EuropeanCertificate {
            currentCertificate = certificate
            certificateQrCodeData = certificate.codeImage?.jpegData(compressionQuality: 1.0)
            if let activityCertificate = WalletManager.shared.activityCertificateFor(certificate: certificate) {
                if activityCertificate.isValid {
                    currentActivityCertificate = activityCertificate
                    certificateActivityQrCodeData = activityCertificate.codeImage?.jpegData(compressionQuality: 1.0)
                    certificateActivityExpiryTimestamp = activityCertificate.endDate.timeIntervalSince1970
                } else {
                    currentActivityCertificate = nil
                    certificateActivityQrCodeData = nil
                    certificateActivityExpiryTimestamp = nil
                }
                startTimer()
            } else {
                currentActivityCertificate = nil
                certificateActivityQrCodeData = nil
                certificateActivityExpiryTimestamp = nil
                stopTimer()
            }
        } else {
            currentCertificate = nil
            currentActivityCertificate = nil
            certificateQrCodeData = nil
            certificateActivityQrCodeData = nil
            certificateActivityExpiryTimestamp = nil
            stopTimer()
        }
    }

    @objc private func appDidBecomeActive() {
        updateCertificate()
        reloadData()
    }

    @objc private func appDidEnterBackground() {
        stopTimer()
    }

    @objc private func appWillEnterForeground() {
        if isHavingActivityCertificate { startTimer() }
    }
#endif

}

#if !WIDGET
@available(iOS 14.0, *)
extension WidgetDCCManager: LocalizationsChangesObserver {

    func localizationsChanged() {
        reloadData()
    }

    func reloadData() {
        bottomText = certificateEligibleToActivityPass && WalletManager.shared.isActivityPassActivated ? "widget.dcc.full.activityPass".localized : "widget.dcc.full".localized
        noCertificateText = "widget.dcc.empty".localized
        if let timestamp = certificateActivityExpiryTimestamp {
            let date: Date = Date(timeIntervalSince1970: timestamp)
            bottomTextActivityPass = String(format: "widget.dcc.activityPass".localized, date.dayNameShortDayMonthFormatted(), date.timeFormatted())
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

}

@available(iOS 14.0, *)
extension WidgetDCCManager: WalletChangesObserver {

    func walletCertificatesDidUpdate() {}

    func walletActivityCertificateDidUpdate() {
        updateCertificate()
        reloadData()
    }

    func walletFavoriteCertificateDidUpdate() {
        updateCertificate()
        reloadData()
    }

    func walletSmartStateDidUpdate() {}
}

@available(iOS 14.0, *)
extension WidgetDCCManager {

    private func startTimer() {
        print("⏰ Start Widget Timer")
        timer?.invalidate()
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }

    @objc private func timerFired() {
        print("⏰ Timer Widget fired")
        if WalletManager.shared.activityCertificateIdFor(certificate: currentCertificate) != currentActivityCertificate?.id {
            updateCertificate()
            wasCertificateValid = currentActivityCertificate?.isValid == true
            reloadData()
            if !isHavingActivityCertificate { stopTimer() }
        } else if !wasCertificateValid && currentActivityCertificate?.isValid == true {
            wasCertificateValid = true
            reloadData()
        }
    }

    private func stopTimer() {
        print("⏰ Stop Widget Timer")
        timer?.invalidate()
        timer = nil
    }

}
#endif
