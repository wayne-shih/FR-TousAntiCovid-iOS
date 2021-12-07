// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureSelectionCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/11/2021 - for the TousAntiCovid project.
//

import UIKit

final class KeyFigureSelectionCell: CVTableViewCell {
    override func setup(with row: CVRow) {
        super.setup(with: row)
        accessoryType = .none
        setupContent(with: row)
        setupAccessibility()
    }
    
    private func setupContent(with row: CVRow) {
        cvImageView?.image = row.isOn ?? false ? row.image : nil
    }
    
    override func setupAccessibility() {
        super.setupAccessibility()
        contentView.isAccessibilityElement = true
        cvTitleLabel?.isAccessibilityElement = false
        cvSubtitleLabel?.isAccessibilityElement = false
        accessibilityTraits = currentAssociatedRow?.selectionAction != nil ? .button : .staticText
        contentView.accessibilityTraits = currentAssociatedRow?.selectionAction != nil ? .button : .staticText
        accessibilityElements = [contentView]
        contentView.accessibilityLabel = "\(cvTitleLabel?.text ?? ""). \(cvSubtitleLabel?.text ?? "")"
    }
}
