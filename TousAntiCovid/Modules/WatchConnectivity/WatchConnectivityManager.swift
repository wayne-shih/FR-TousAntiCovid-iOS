// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WatchConnectivityManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 04/08/2021 - for the TousAntiCovid project.
//

import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject {

    static let shared: WatchConnectivityManager = WatchConnectivityManager()
    private var session: WCSession { WCSession.default }

    @UserDefault(key: .isWatchAppInstalled)
    private var isWatchAppInstalled: Bool = false

    func start() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
        WalletManager.shared.addObserver(self)
    }

    private func updateApplicationContext() {
        guard session.activationState == .activated else { return }
        guard session.isWatchAppInstalled else { return }
        if let favoriteCertificate = WalletManager.shared.favoriteCertificate {
            guard let qrCode = favoriteCertificate.value.qrCode(small: true) else { return }
            guard let qrCodeData = qrCode.jpegData(compressionQuality: 1.0) else { return }
            var context: [String: Any] = ["id": favoriteCertificate.id, "qr": qrCodeData]
            if let activityCertificate = WalletManager.shared.activityCertificateFor(certificate: favoriteCertificate as? EuropeanCertificate),
               let qrCodeData = activityCertificate.value.qrCode(small: true)?.jpegData(compressionQuality: 1.0) {
                context["qrAct"] = qrCodeData
                context["exp"] = activityCertificate.endDate.timeIntervalSince1970
            }
            try? session.updateApplicationContext(context)
        } else {
            clearApplicationContext()
        }
    }

    private func clearApplicationContext() {
        try? session.updateApplicationContext([:])
    }

    private func forceUpdateApplicationContext() {
        clearApplicationContext()
        updateApplicationContext()
    }

    private func triggerApplicationContextUpdateIfNeeded() {
        let currentId: String? = session.applicationContext["id"] as? String
        if currentId != WalletManager.shared.favoriteDccId { updateApplicationContext() }
    }

    private func processReceivedMessage(_ message: [String : Any]) {
        guard let actionValue = message[WatchMessage.Key.action.rawValue] as? String else { return }
        guard let action = WatchMessage.Action(rawValue: actionValue) else { return }
        switch action {
        case .getInitialData:
            forceUpdateApplicationContext()
        }
    }

    private func updateAppInstallationState() {
        if session.isWatchAppInstalled && !self.isWatchAppInstalled { self.forceUpdateApplicationContext() }
        self.isWatchAppInstalled = session.isWatchAppInstalled
    }

}

extension WatchConnectivityManager: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.updateAppInstallationState()
            self.triggerApplicationContextUpdateIfNeeded()
        }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.updateAppInstallationState() }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async { session.activate() }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async { self.processReceivedMessage(message) }
        replyHandler(["status": 200])
    }

}

extension WatchConnectivityManager: WalletChangesObserver {

    func walletCertificatesDidUpdate() {}

    func walletActivityCertificateDidUpdate() {
        updateApplicationContext()
    }

    func walletFavoriteCertificateDidUpdate() {
        updateApplicationContext()
    }

}
