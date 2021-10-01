// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ExtensionDelegate.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 30/07/2021 - for the TousAntiCovid project.
//

import WatchKit
import WatchConnectivity
import ClockKit

final class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        WatchConnectivityManager.shared.start()
        WatchConnectivityManager.shared.addObserver(self)
    }

    func applicationDidBecomeActive() {
        updateCurrentController()
    }

    func applicationWillResignActive() {
        switchTo(.splashscreen)
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                switchTo(.splashscreen)
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                if WatchConnectivityManager.shared.hasSessionContentPending {
                    WatchConnectivityManager.shared.connectivityBackgroundTask = connectivityTask
                } else {
                    connectivityTask.setTaskCompletedWithSnapshot(false)
                }
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    private func updateCurrentController() {
        FavoriteManager.shared.hasFavorite ? switchTo(.qrCode) : switchTo(.empty)
    }

    private func switchTo(_ controller: ControllerName) {
        switch controller {
        case .qrCode:
            let contexts: [Any]?
            if let data = FavoriteManager.shared.qrData {
                contexts = [data]
            } else {
                contexts = nil
            }
            WKInterfaceController.reloadRootPageControllers(withNames: [ControllerName.qrCode.rawValue], contexts: contexts, orientation: .horizontal, pageIndex: 0)
        case .empty:
            WKInterfaceController.reloadRootPageControllers(withNames: [ControllerName.empty.rawValue], contexts: nil, orientation: .horizontal, pageIndex: 0)
        default:
            WKInterfaceController.reloadRootPageControllers(withNames: [controller.rawValue], contexts: nil, orientation: .horizontal, pageIndex: 0)
        }
    }

}

extension ExtensionDelegate: WatchConnectivityObserver {

    func watchConnectivityDidReceiveApplicationContext() {
        guard WKExtension.shared().applicationState == .active else { return }
        updateCurrentController()
    }

}
