// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletAddCertificateCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 11/05/2021 - for the TousAntiCovid project.
//

import UIKit

final class WalletAddCertificateCell: CVTableViewCell {
    
    @IBOutlet private var documentImageView: UIImageView!
    @IBOutlet private var containerView: UIView!

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
        setupContent(with: row)
        setupAccessibility()
    }

    private func setupUI(with row: CVRow) {
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        containerView.layer.cornerRadius = 10.0
        containerView.layer.maskedCorners = row.theme.maskedCorners
        containerView.layer.masksToBounds = true
        cvSubtitleLabel?.font = row.theme.subtitleFont()
        cvSubtitleLabel?.textColor = row.theme.subtitleColor
        cvSubtitleLabel?.textAlignment = row.theme.textAlignment
        cvSubtitleLabel?.adjustsFontForContentSizeCategory = true
        accessoryType = .none
        selectionStyle = .none
        guard !UIColor.isDarkMode else { return }
        documentImageView.layer.borderWidth = 1.0
        documentImageView.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
    }
    
    private func setupContent(with row: CVRow) {
        documentImageView.image = row.image
    }

    private func setupAccessibility() {
        accessibilityElements = [cvTitleLabel].compactMap { $0 }
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
    
    @IBAction private func documentButtonDidPress() {
        currentAssociatedRow?.secondarySelectionAction?()
    }
    
}
