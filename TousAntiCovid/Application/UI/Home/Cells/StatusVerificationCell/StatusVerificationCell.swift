// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StatusVerificationCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 03/05/2021 - for the TousAntiCovid project.
//

import UIKit

final class StatusVerificationCell: CVTableViewCell {

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var gradientView: GradientView!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
    }

    private func setupUI(with row: CVRow) {
        cvTitleLabel?.font = Appearance.Cell.Text.subtitleFont
        cvTitleLabel?.textColor = .white
        activityIndicator.color = .white
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
        containerView.layer.maskedCorners = row.theme.maskedCorners
        guard let currentRiskLevel = row.associatedValue as? RisksUILevel else { return }
        gradientView.startColor = currentRiskLevel.color.fromColor
        gradientView.endColor = currentRiskLevel.color.toColor
        containerView.backgroundColor = .black
        gradientView.alpha = 0.95
        activityIndicator.startAnimating()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard currentAssociatedRow?.selectionAction != nil else { return }
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            contentView.layer.removeAllAnimations()
            contentView.alpha = 0.6
        } else {
            UIView.animate(withDuration: 0.3) {
                self.contentView.alpha = 1.0
            }
        }
    }

}
