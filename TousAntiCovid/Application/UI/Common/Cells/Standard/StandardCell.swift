// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StandardCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/08/2021 - for the TousAntiCovid project.
//

import Foundation

class StandardCell: CVTableViewCell {

    override func setupAccessibility() {
        accessibilityLabel = [cvTitleLabel?.text?.removingEmojis(), cvSubtitleLabel?.text].compactMap { $0 }.joined(separator: ".\n").removingEmojis()
        accessibilityHint = cvAccessoryLabel?.text?.removingEmojis()
        accessibilityTraits = currentAssociatedRow?.selectionAction != nil ? .button : .staticText
        accessibilityElements = []
        isAccessibilityElement = true
        cvAccessoryLabel?.isAccessibilityElement = false
        cvTitleLabel?.isAccessibilityElement = false
        cvSubtitleLabel?.isAccessibilityElement = false
        cvImageView?.isAccessibilityElement = false
        cvImageView?.accessibilityTraits = []
        cvImageView?.isUserInteractionEnabled = false
    }

}
