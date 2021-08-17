// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  IsolationInitialCaseSafeCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 9/12/2020 - for the TousAntiCovid project.
//

import UIKit

final class IsolationInitialCaseSafeCell: CardCell {
    
    @IBOutlet private var headerImageView: UIImageView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupAccessibility()
    }
    
    private func setupUI() {
        cvTitleLabel?.font = Appearance.Cell.Text.titleFont
        cvSubtitleLabel?.font = Appearance.Cell.Text.subtitleFont
        headerImageView.image = Asset.Images.badge.image
        headerImageView.tintColor = Appearance.Cell.Text.titleColor
    }

    override func setupAccessibility() {
        super.setupAccessibility()
        headerImageView.isAccessibilityElement = false
    }
    
}
