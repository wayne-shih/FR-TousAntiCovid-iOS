// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  LastInfoCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class LastInfoCell: CardCell {
    
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var button: UIButton!
    @IBOutlet private var headerLabel: UILabel!
    @IBOutlet private var headerImageView: UIImageView!
    @IBOutlet private var newInfoAvailableIndicatorView: UIView!
    
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupContent(with: row)
        setupAccessibility()
    }
    
    private func setupUI() {
        dateLabel.font = Appearance.Cell.Text.captionTitleFont
        dateLabel.textColor = Appearance.Cell.Text.captionTitleColor
        cvTitleLabel?.font = Appearance.Cell.Text.titleFont
        cvSubtitleLabel?.font = Appearance.Cell.Text.subtitleFont
        button?.contentHorizontalAlignment = .left
        button?.tintColor = Appearance.Button.Tertiary.titleColor
        button?.titleLabel?.font = Appearance.Button.linkFont
        button?.titleLabel?.adjustsFontForContentSizeCategory = true
        headerImageView.image = Asset.Images.homeRing.image
        headerImageView.tintColor = Appearance.Cell.Text.headerTitleColor
        headerImageView.tintAdjustmentMode = .normal
        headerLabel.textColor = Appearance.Cell.Text.headerTitleColor
        headerLabel.text = "home.infoSection.lastInfo".localized
        headerLabel.font = Appearance.Cell.Text.titleFont
        newInfoAvailableIndicatorView.layer.cornerRadius = 4.0
        newInfoAvailableIndicatorView.layer.masksToBounds = true
        newInfoAvailableIndicatorView.backgroundColor = Asset.Colors.error.color
    }
    
    private func setupContent(with row: CVRow) {
        dateLabel.text = row.accessoryText
        button.setTitle(row.buttonTitle, for: .normal)
        button.isHidden = row.buttonTitle == nil
        if let didReceiveInfo = row.associatedValue as? Bool {
            newInfoAvailableIndicatorView.isHidden = !didReceiveInfo
        }
    }
    
    override func setupAccessibility() {
        accessibilityLabel = button.title(for: .normal)
        accessibilityTraits = .button
        accessibilityElements = []
        accessibilityHint = [headerLabel.text, dateLabel.text, cvTitleLabel?.text, cvSubtitleLabel?.text].compactMap { $0 }.joined(separator: ".\n")
        headerLabel.isAccessibilityElement = false
        dateLabel.isAccessibilityElement = false
        cvTitleLabel?.isAccessibilityElement = false
        cvSubtitleLabel?.isAccessibilityElement = false
        button.isAccessibilityElement = false
    }
    
    @IBAction private func buttonPressed(_ sender: Any) {
        currentAssociatedRow?.selectionAction?(self)
    }
    
}
