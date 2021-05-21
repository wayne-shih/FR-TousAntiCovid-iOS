// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  PhoneCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 17/03/2020 - for the TousAntiCovid project.
//

import UIKit

final class PhoneCell: CVTableViewCell {
    
    @IBOutlet private var containerView: UIView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupAccessibility()
    }
    
    private func setupUI() {
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
        accessoryType = .none
        selectionStyle = .none
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
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

    private func setupAccessibility() {
        cvTitleLabel?.isAccessibilityElement = true
        cvTitleLabel?.accessibilityLabel = "\(cvTitleLabel?.text?.removingEmojis() ?? "") \(cvSubtitleLabel?.text?.removingEmojis() ?? "")"
        cvTitleLabel?.accessibilityTraits = .staticText
        cvImageView?.isAccessibilityElement = false
        cvSubtitleLabel?.isAccessibilityElement = false
    }
    
}
