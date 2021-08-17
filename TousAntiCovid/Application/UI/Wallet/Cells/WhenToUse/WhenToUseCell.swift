// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WhenToUseCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 26/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class WhenToUseCell: CardCell {

    @IBOutlet private var button: UIButton?

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
        setupContent(with: row)
        setupAccessibility()
    }

    private func setupUI(with row: CVRow) {
        button?.tintColor = Appearance.Button.Tertiary.titleColor
        button?.titleLabel?.font = Appearance.Button.linkFont
        button?.titleLabel?.adjustsFontForContentSizeCategory = true
    }
    
    private func setupContent(with row: CVRow) {
        UIView.performWithoutAnimation {
            self.button?.setTitle(row.buttonTitle, for: .normal)
            self.button?.layoutIfNeeded()
        }
        button?.accessibilityLabel = row.title?.removingEmojis()
        button?.accessibilityHint = nil
    }

    override func setupAccessibility() {
        super.setupAccessibility()
        accessibilityElements = [cvTitleLabel, cvSubtitleLabel, button].compactMap { $0 }
    }
    
    @IBAction private func buttonDidPress() {
        currentAssociatedRow?.secondarySelectionAction?()
    }

}
