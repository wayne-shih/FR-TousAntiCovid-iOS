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

protocol WatchConnectivityObserver: AnyObject {

    func watchConnectivityDidReceiveApplicationContext()

}

final class WatchConnectivityObserverWrapper: NSObject {

    weak var observer: WatchConnectivityObserver?

    init(observer: WatchConnectivityObserver) {
        self.observer = observer
    }

}

final class WatchConnectivityManager: NSObject {

    static let shared: WatchConnectivityManager = WatchConnectivityManager()
    private var session: WCSession { WCSession.default }

    private var observers: [WatchConnectivityObserverWrapper] = []

    @UserDefault(key: .didAlreadyRequestInitialData)
    private var didAlreadyRequestInitialData: Bool = false

    func start() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }

    private func sendDataInitializationMessageIfNeeded() {
        guard session.activationState == .activated else { return }
        guard !FavoriteManager.shared.hasFavorite else { return }
        guard !didAlreadyRequestInitialData else { return }
        session.sendMessage([WatchMessage.Key.action.rawValue: WatchMessage.Action.getInitialData.rawValue]) { result in
            self.didAlreadyRequestInitialData = true
        }
    }

}

extension WatchConnectivityManager: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // This is an optimization to wait just a bit in the case of having an application context already being delivered after the app installation.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sendDataInitializationMessageIfNeeded()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        sendDataInitializationMessageIfNeeded()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        didAlreadyRequestInitialData = true
        FavoriteManager.shared.qrData = applicationContext["qr"] as? Data
        notifyReceivedApplicationContext()
    }

}

extension WatchConnectivityManager {

    func addObserver(_ observer: WatchConnectivityObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(WatchConnectivityObserverWrapper(observer: observer))
    }

    func removeObserver(_ observer: WatchConnectivityObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }

    private func observerWrapper(for observer: WatchConnectivityObserver) -> WatchConnectivityObserverWrapper? {
        observers.first { $0.observer === observer }
    }

    private func notifyReceivedApplicationContext() {
        observers.forEach { $0.observer?.watchConnectivityDidReceiveApplicationContext() }
    }

}
