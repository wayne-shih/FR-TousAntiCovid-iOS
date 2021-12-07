// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AnimatedHeaderCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/10/2021 - for the TousAntiCovid project.
//

import UIKit
import Lottie

final class AnimatedHeaderCell: CVTableViewCell {
    @IBOutlet var animationView: AnimationView?
    @IBOutlet private var dateView: UIView!
    @IBOutlet private var button: ComponentHighlightButton!
    private let animationSpeed: CGFloat = 1.0

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        startAnimation(animation: row.animation)
    }

    private func setupUI() {
        animationView?.backgroundColor = .clear
        dateView.layer.masksToBounds = true
        button.setTitle("", for: .normal)
        layoutIfNeeded()
    }

    override func setupAccessibility() {
        super.setupAccessibility()
        isAccessibilityElement = false
        accessibilityElements = []
        accessibilityElementsHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerRadius()
    }

    private func updateCornerRadius() {
        dateView.layer.cornerRadius = dateView.frame.height / 2.0
    }

    private func startAnimation(animation: Animation?) {
        guard animationView?.animation == nil else { return }
        animationView?.animation = animation
        animationView?.animationSpeed = animationSpeed
        animationView?.loopMode = .loop
        animationView?.play()
    }

    @IBAction private func didTouchDateView() {
        currentAssociatedRow?.secondarySelectionAction?()
    }
}
