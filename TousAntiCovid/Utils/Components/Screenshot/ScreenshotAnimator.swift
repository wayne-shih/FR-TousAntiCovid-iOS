// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ScreenshotAnimator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 22/10/2021 - for the TousAntiCovid project.
//

import UIKit

final class ScreenshotAnimator {

    static let shared: ScreenshotAnimator = ScreenshotAnimator()
    private var window: UIWindow?

    func generateScreenshotAnimation(for screenshot: UIImage, completion: @escaping () -> ()) {
        let screenshotController: ScreenshotViewController = .init(screenshot: screenshot, didFinishAnimating: { [weak self] in
            guard let self = self else { return }
            self.window?.isHidden = true
            self.window = nil
            completion()
        })
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .clear
        window?.rootViewController = screenshotController
        window?.makeKeyAndVisible()
    }

}
