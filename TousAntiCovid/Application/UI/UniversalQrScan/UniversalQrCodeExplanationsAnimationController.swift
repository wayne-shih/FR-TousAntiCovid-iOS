// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UniversalQrCodeExplanationsContainerController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 11/06/2021 - for the TousAntiCovid project.
//

import UIKit

final class UniversalQrCodeExplanationsAnimationController: UIViewController {

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private var imageViewHeightConstraint: NSLayoutConstraint!

    private var initialButtonFrame: CGRect?

    static func controller(initialButtonFrame: CGRect?) -> UniversalQrCodeExplanationsAnimationController {
        let explanationsController: UniversalQrCodeExplanationsAnimationController = StoryboardScene.UniversalQrScan.universalQrCodeExplanationsContainerController.instantiate()
        explanationsController.initialButtonFrame = initialButtonFrame
        return explanationsController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.tintColor = Appearance.tintColor
    }

    func positionImageViewToMatchView(_ view: UIView?) -> Bool {
        guard let view = view else { return false }
        let rect: CGRect = self.view.convert(view.frame, from: view.superview)
        guard rect.origin.y >= 0 else { return false }
        imageViewTopConstraint.constant = rect.origin.y
        imageViewLeadingConstraint.constant = rect.origin.x
        imageViewWidthConstraint.constant = rect.width
        imageViewHeightConstraint.constant = rect.height
        return true
    }

    private func setImageViewPositionToDestination() {
        imageViewTopConstraint.constant = initialButtonFrame?.origin.y ?? 0.0
        imageViewLeadingConstraint.constant = initialButtonFrame?.origin.x ?? 0.0
        imageViewWidthConstraint.constant = initialButtonFrame?.width ?? 0.0
        imageViewHeightConstraint.constant = initialButtonFrame?.height ?? 0.0
    }

    func animateDisappearing(_ completion: @escaping () -> ()) {
        setImageViewPositionToDestination()
        UIView.animate(withDuration: 0.6, delay: 0.1, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            completion()
        }

    }

}
