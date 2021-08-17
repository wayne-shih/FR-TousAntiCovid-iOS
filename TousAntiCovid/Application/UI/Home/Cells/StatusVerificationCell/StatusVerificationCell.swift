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

final class StatusVerificationCell: CardCell {

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
        guard let currentRiskLevel = row.associatedValue as? RisksUILevel else { return }
        gradientView.startColor = currentRiskLevel.color.fromColor
        gradientView.endColor = currentRiskLevel.color.toColor
        gradientView.alpha = 0.95
        activityIndicator.startAnimating()
    }

}
