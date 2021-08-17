// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletDocumentsCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 11/05/2021 - for the TousAntiCovid project.
//

import UIKit

final class WalletDocumentsCell: CardCell {
    
    @IBOutlet private var leftImageView: UIImageView!
    @IBOutlet private var leftLabel: UILabel!
    @IBOutlet private var rightLabel: UILabel!
    @IBOutlet private var rightImageView: UIImageView!

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
        setupContent(with: row)
        setupAccessibility()
    }

    private func setupUI(with row: CVRow) {
        cvSubtitleLabel?.font = row.theme.subtitleFont()
        cvSubtitleLabel?.textColor = row.theme.subtitleColor
        cvSubtitleLabel?.textAlignment = row.theme.textAlignment
        cvSubtitleLabel?.adjustsFontForContentSizeCategory = true
        leftLabel.font = row.theme.subtitleFont()
        rightLabel.font = row.theme.subtitleFont()
        
        guard !UIColor.isDarkMode else { return }
        leftImageView.layer.borderWidth = 1.0
        leftImageView.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        rightImageView.layer.borderWidth = 1.0
        rightImageView.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
    }
    
    private func setupContent(with row: CVRow) {
        leftImageView.image = row.image
        rightImageView.image = row.secondaryImage
        leftLabel.text = row.accessoryText
        rightLabel.text = row.footerText
    }

    override func setupAccessibility() {
        super.setupAccessibility()
        leftImageView.accessibilityLabel = leftLabel?.text?.removingEmojis()
        leftImageView.accessibilityTraits = .image
        leftImageView.isAccessibilityElement = true
        rightImageView.accessibilityLabel = rightLabel?.text?.removingEmojis()
        rightImageView.accessibilityTraits = .image
        rightImageView.isAccessibilityElement = true
        leftLabel.isAccessibilityElement = false
        rightLabel.isAccessibilityElement = false
        accessibilityElements = [containerView, leftImageView, leftLabel, rightImageView, rightLabel].compactMap { $0 }
    }
    
    @IBAction private func leftDocumentButtonDidPress() {
        currentAssociatedRow?.secondarySelectionAction?()
    }
    
    @IBAction private func rightDocumentButtonDidPress() {
        currentAssociatedRow?.tertiarySelectionAction?()
    }
    
}
