// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ActivityPassExpirationCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 19/08/2021 - for the TousAntiCovid project.
//

import UIKit

final class ActivityPassExpirationCell: CVTableViewCell {

    @IBOutlet private var titleContainerView: UIView!

    private var lastRemainingMinutes: Int?

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
        reload()
    }

    func reload() {
        updateContent()
    }

    private func setupUI(with row: CVRow) {
        backgroundColor = .clear
        titleContainerView.backgroundColor = row.theme.backgroundColor
        cvTitleLabel?.isHidden = false
    }

    private func updateContent() {
        guard let expirationTimestamp = currentAssociatedRow?.associatedValue as? Double else { return }
        let remainingTime: Double = expirationTimestamp - Date().timeIntervalSince1970
        let remainingMinutes: Int = Int(ceil(remainingTime / 60.0))
        lastRemainingMinutes = remainingMinutes
        let minutes: Int = remainingMinutes % 60
        let hours: Int = remainingMinutes / 60
        let formattedTimeRemaining: String
        if hours == 0 && minutes == 0 {
            formattedTimeRemaining = "activityPass.fullscreen.validFor.timeFormat.lessThanAMinute".localized
        } else if hours == 0 {
            formattedTimeRemaining = String(format: "activityPass.fullscreen.validFor.timeFormat.minutes".localized, minutes)
        } else {
            formattedTimeRemaining = String(format: "activityPass.fullscreen.validFor.timeFormat.hoursMinutes".localized, hours, minutes)
        }
        let currentText: String? = cvTitleLabel?.text
        let newText: String = String(format: "activityPass.fullscreen.validFor".localized, formattedTimeRemaining)
        if newText != currentText {
            cvTitleLabel?.text = newText
            setNeedsLayout()
            layoutIfNeeded()
            if currentText != nil {
                bounceLabel()
            }
        }
    }

    private func bounceLabel() {
        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut) { [weak self] in
            self?.titleContainerView?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseIn) { [weak self] in
                self?.titleContainerView?.transform = .identity
            } completion: { _ in }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerRadius()
    }

    private func updateCornerRadius() {
        titleContainerView.layer.cornerRadius = titleContainerView.frame.height / 2.0
    }

}
