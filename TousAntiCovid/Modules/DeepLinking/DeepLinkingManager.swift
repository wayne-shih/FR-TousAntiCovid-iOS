// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DeepLinkingManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import RobertSDK

final class DeepLinkingManager {
    
    static let shared: DeepLinkingManager = DeepLinkingManager()
    var appLaunchedFromDeeplinkOrShortcut: Bool = false
    weak var enterCodeController: EnterCodeController?
    
    weak var attestationController: AttestationsViewController?
    weak var walletCoordinator: WalletCoordinator?
    
    private var waitingNotification: Notification?
    private(set) var lastDeeplinkScannedDirectlyFromApp: Bool = false
    
    func start() {
        addObservers()
    }

    func deeplinkForCode(_ code: String) -> URL? {
        if let url = URL(string: code), url.scheme == "https" {
            return url
        } else if code.isUuidCode || code.isShortCode {
            return URL(string: "https://bonjour.tousanticovid.gouv.fr/app/code/\(code)")
        } else {
            // In this case it means we scanned a raw DCC certificate.
            let encodedCode: String = code.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? ""
            let path: String
            if code.hasPrefix("DC04") {
                path = WalletConstant.URLPath.wallet2D.rawValue
            } else {
                path = WalletConstant.URLPath.walletDCC.rawValue
            }
            return URL(string: "https://bonjour.tousanticovid.gouv.fr\(path)#" + encodedCode)
        }
    }

    func isComboDeeplink(_ url: URL) -> Bool {
        url.absoluteString.contains(WalletConstant.Separator.declareCode.rawValue) && url.absoluteString.contains(WalletConstant.URLPath.walletDCC.rawValue)
    }

    func processActivity(_ activity: NSUserActivity) {
        guard activity.activityType == "NSUserActivityTypeBrowsingWeb" else { return }
        guard let url = activity.webpageURL else { return }
        processUrl(url)
    }
    
    func processAttestationUrl() {
        guard attestationController == nil else { return }
        let notification: Notification = Notification(name: .newAttestationFromDeeplink)
        guard UIApplication.shared.applicationState == .active else {
            waitingNotification = notification
            return
        }
        NotificationCenter.default.post(notification)
    }
    
    func processFullVenueRecordingUrl() {
        let notification: Notification = Notification(name: .openFullVenueRecordingFlowFromDeeplink)
        guard UIApplication.shared.applicationState == .active else {
            waitingNotification = notification
            return
        }
        NotificationCenter.default.post(notification)
    }

    func processOpenQrScan() {
        let notification: Notification = Notification(name: .openQrScan)
        guard UIApplication.shared.applicationState == .active else {
            waitingNotification = notification
            return
        }
        NotificationCenter.default.post(notification)
    }

    func processOpenFavoriteCertificateQrCode() {
        let notification: Notification = Notification(name: .openCertificateQRCode)
        guard UIApplication.shared.applicationState == .active else {
            waitingNotification = notification
            return
        }
        NotificationCenter.default.post(notification)
    }
    
    func processUrl(_ url: URL, fromApp: Bool = false) {
        lastDeeplinkScannedDirectlyFromApp = fromApp
        if url.host == "tac.gouv.fr" {
            processVenueUrl(url)
        } else if url.path.hasPrefix("/app/code") {
            processCodeUrl(url)
        } else {
            switch url.path {
            case "/app/attestation":
                processAttestationUrl()
            case WalletConstant.URLPath.wallet.rawValue,
                 WalletConstant.URLPath.wallet2D.rawValue,
                 WalletConstant.URLPath.walletDCC.rawValue:
                if WalletManager.shared.isWalletActivated {
                    processWalletUrl(url)
                } else if let code = getComboCodeFrom(url: url), let codeUrl = deeplinkForCode(code) {
                    processCodeUrl(codeUrl)
                }
            default:
                break
            }
        }
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func appDidBecomeActive() {
        guard let notification = waitingNotification else { return }
        NotificationCenter.default.post(notification)
        waitingNotification = nil
    }
    
    private func processCodeUrl(_ url: URL) {
        guard RBManager.shared.isRegistered else { return }
        let code: String = url.path.replacingOccurrences(of: "/app/code/", with: "")
        let notification: Notification = Notification(name: .didEnterCodeFromDeeplink, object: code)
        guard UIApplication.shared.applicationState == .active else {
            waitingNotification = notification
            return
        }
        NotificationCenter.default.post(notification)
    }
    
    private func processVenueUrl(_ url: URL) {
        guard VenuesManager.shared.isVenueUrlValid(url) else {
            UIApplication.shared.keyWindow?.rootViewController?.topPresentedController.showAlert(title: "enterCodeController.alert.invalidCode.title".localized,
                                                                                                 message: "enterCodeController.alert.invalidCode.message".localized,
                                                                                                 okTitle: "common.ok".localized)
            return
        }
        guard !VenuesManager.shared.isVenueUrlExpired(url) else {
            UIApplication.shared.keyWindow?.rootViewController?.topPresentedController.showAlert(title: "enterCodeController.alert.expiredCode.title".localized,
                                                                                                 message: "enterCodeController.alert.expiredCode.message".localized,
                                                                                                 okTitle: "common.ok".localized)
            return
        }
        let notification: Notification = Notification(name: .newVenueRecordingFromDeeplink, object: url)
        guard UIApplication.shared.applicationState == .active else {
            waitingNotification = notification
            return
        }
        NotificationCenter.default.post(notification)
    }
    
    private func processWalletUrl(_ url: URL) {
        guard WalletManager.shared.isWalletActivated else { return }
        let notification: Notification = Notification(name: .newWalletCertificateFromDeeplink, object: url)
        guard UIApplication.shared.applicationState == .active else {
            waitingNotification = notification
            return
        }
        NotificationCenter.default.post(notification)
    }

    func getComboCodeFrom(url: URL) -> String? {
        let separator: String = WalletConstant.Separator.declareCode.rawValue
        guard url.absoluteString.contains(separator) else { return nil }
        return url.absoluteString.components(separatedBy: separator).last
    }

}
