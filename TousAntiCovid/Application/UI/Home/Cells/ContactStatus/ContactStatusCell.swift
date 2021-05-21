// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ContactStatusCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class ContactStatusCell: CVTableViewCell {
    
    private var isParallaxConfigurated: Bool = false
    
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var gradientView: GradientView!
    @IBOutlet private weak var effectView: UIImageView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
        setupContent(with: row)
    }
    
    private func setupUI(with row: CVRow) {
        cvTitleLabel?.font = Appearance.Cell.Text.titleFont
        cvSubtitleLabel?.font = Appearance.Cell.Text.subtitleFont
        cvAccessoryLabel?.font = Appearance.Cell.Text.accessoryFont
        cvAccessoryLabel?.textColor = .white
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
        containerView.layer.maskedCorners = row.theme.maskedCorners
        setupParallaxEffect()
    }
    
    private func setupParallaxEffect() {
        guard !isParallaxConfigurated else { return }
        isParallaxConfigurated = true
        effectView.configureParallax(intensity: -400)
    }
    
    private func setupContent(with row: CVRow) {
        guard let gradientColors = row.associatedValue as? (startColor: UIColor, endColor: UIColor, effectAlpha: CGFloat) else { return }
        gradientView.startColor = gradientColors.startColor
        gradientView.endColor = gradientColors.endColor
        effectView.alpha = gradientColors.effectAlpha
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
    
}
