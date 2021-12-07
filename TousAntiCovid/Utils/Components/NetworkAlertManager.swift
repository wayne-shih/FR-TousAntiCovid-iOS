// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NetworkAlertManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 04/11/2021 - for the TousAntiCovid project.
//

import UIKit

@available(iOS 12, *)
final class NetworkAlertManager: NSObject {
    
    static let shared: NetworkAlertManager = NetworkAlertManager()
    
    private var alreadyDisplayedAlert: Bool = false
    private var isDisplayingAlert: Bool = false
    
    func start() {
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
}

// MARK: - NetworkChangesObserver
@available(iOS 12, *)
extension NetworkAlertManager: NetworkChangesObserver {
    func networkStateDidChange(isUnreachable: Bool, for reason: UnsatisfiedReason?) {
        manageNoConnectionAlertIfNeeded(isUnreachable: isUnreachable, reason: reason)
    }
}

// MARK: - Private functions
@available(iOS 12, *)
private extension NetworkAlertManager {
    func addObservers() {
        NetworkMonitor.shared.addObserver(self)
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.alreadyDisplayedAlert = false
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.manageNoConnectionAlertIfNeeded(isUnreachable: NetworkMonitor.shared.isUnreachable,
                                                  reason: NetworkMonitor.shared.unsatisfiedReason)
        }
    }
    
    func removeObservers() {
        NetworkMonitor.shared.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    func manageNoConnectionAlertIfNeeded(isUnreachable: Bool, reason: UnsatisfiedReason?) {
        if isUnreachable {
            guard !isDisplayingAlert && !alreadyDisplayedAlert else { return }
            isDisplayingAlert = true
            alreadyDisplayedAlert = true
            showNoConnectionAlert(for: reason)
        } else {
            alreadyDisplayedAlert = false
            if isDisplayingAlert {
                (UIApplication.shared.topPresentedController as? UIAlertController)?.dismiss(animated: true) { [weak self] in
                    self?.isDisplayingAlert = false
                }
            }
        }
    }
    
    func showNoConnectionAlert(for reason: UnsatisfiedReason?) {
        UIApplication.shared.topPresentedController?.showAlert(
            title: "common.warning".localized,
            message: reason.localizedDescription,
            okTitle: "common.ok".localized,
            cancelTitle: "common.settings".localized,
            handler: { [weak self] in
                self?.isDisplayingAlert = false
            }, cancelHandler: { [weak self] in
                UIApplication.shared.openSettings()
                self?.isDisplayingAlert = false
            })
    }
}

private extension Optional where Wrapped == UnsatisfiedReason {
    var localizedDescription: String {
        guard let self = self else { return "homeScreen.error.networkUnreachable".localized }
        switch self {
        case .cellularDenied:
            return "homeScreen.error.cellularDenied".localized
        case .localNetworkDenied:
            return "homeScreen.error.localNetworkDenied".localized
        case .wifiDenied:
            return "homeScreen.error.wifiDenied".localized
        }
    }
}
