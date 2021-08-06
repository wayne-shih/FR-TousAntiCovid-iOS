// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RatingsManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/07/2021 - for the TousAntiCovid project.
//

import UIKit
import StoreKit
import ServerSDK

final class RatingsManager {
    
    static let shared: RatingsManager = RatingsManager()
    
    @UserDefault(key: .keyFiguresOpeningCount)
    private var keyFiguresOpeningCount: Int = 0
    
    @UserDefault(key: .lastBuildNumberForRatingsAlert)
    private var lastBuildNumberForRatingsAlert: Int = 0
    
    @UserDefault(key: .didShowRatingsAlert)
    private var didShowRatingsAlert: Bool = false
    
    private init() {
        addObserver()
    }
    
    func start() {
        guard let buildNumber = Int(UIApplication.shared.buildNumber) else { return }
        if lastBuildNumberForRatingsAlert != buildNumber {
            lastBuildNumberForRatingsAlert = buildNumber
            resetCounters()
        }
    }
    
    func didOpenKeyFigures() {
        keyFiguresOpeningCount += 1
    }

    private func resetCounters() {
        keyFiguresOpeningCount = 0
        didShowRatingsAlert = false
    }
    
    @objc private func appDidBecomeActive() {
        guard !didShowRatingsAlert else { return }
        guard keyFiguresOpeningCount >= ParametersManager.shared.ratingsKeyFiguresOpeningThreshold else { return }
        SKStoreReviewController.requestReview()
        didShowRatingsAlert = true
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
}
