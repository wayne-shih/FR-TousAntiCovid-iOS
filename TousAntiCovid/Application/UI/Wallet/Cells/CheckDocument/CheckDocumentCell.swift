// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CheckDocumentCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 11/05/2021 - for the TousAntiCovid project.
//

import UIKit

final class CheckDocumentCell: CardCell {
    
    @IBOutlet private var documentImageView: UIImageView!

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
        guard !UIColor.isDarkMode else { return }
        documentImageView.layer.borderWidth = 1.0
        documentImageView.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
    }
    
    private func setupContent(with row: CVRow) {
        documentImageView.image = row.image
    }

    override func setupAccessibility() {
        super.setupAccessibility()
        accessibilityElements = [cvTitleLabel].compactMap { $0 }
    }
    
}
