// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StandardCardCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 26/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class StandardCardCell: CVTableViewCell {

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var titleStackView: UIStackView?

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
        setupAccessibility()
    }

    private func setupUI(with row: CVRow) {
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        containerView.layer.cornerRadius = 10.0
        containerView.layer.maskedCorners = row.theme.maskedCorners
        containerView.layer.masksToBounds = true
        titleStackView?.isHidden = row.title == nil && row.image == nil
    }

    private func setupAccessibility() {
        accessibilityElements = [cvTitleLabel].compactMap { $0 }
        if let cvSubtitleLabel = cvSubtitleLabel, !cvSubtitleLabel.isHidden {
            accessibilityElements?.append(cvSubtitleLabel)
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        guard currentAssociatedRow?.selectionAction != nil else { return }
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
