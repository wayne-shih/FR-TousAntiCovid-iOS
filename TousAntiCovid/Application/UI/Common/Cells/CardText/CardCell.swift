// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CardCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/10/2020 - for the TousAntiCovid project.
//

import UIKit

class CardCell: CVTableViewCell {
    
    @IBOutlet var containerView: UIView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
        containerView.backgroundColor = backgroundColor
        containerView.layer.maskedCorners = row.theme.maskedCorners
        backgroundColor = .clear
        selectionStyle = .none
        accessoryType = .none
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

    override func setupAccessibility() {
        let row: CVRow? = currentAssociatedRow
        accessibilityLabel = row?.title?.removingEmojis()
        accessibilityHint = [row?.subtitle, row?.accessoryText].compactMap { $0?.accessibilityNumberFormattedString() }.joined(separator: ".\n").removingEmojis()
        accessibilityTraits = row?.selectionAction != nil ? .button : .staticText
        accessibilityElements = []
        isAccessibilityElement = true
        containerView.isAccessibilityElement = false
        cvAccessoryLabel?.isAccessibilityElement = false
        cvTitleLabel?.isAccessibilityElement = false
        cvSubtitleLabel?.isAccessibilityElement = false
        cvImageView?.isAccessibilityElement = false
        cvImageView?.accessibilityTraits = []
        cvImageView?.isUserInteractionEnabled = false
    }

}
