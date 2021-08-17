// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  TextCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 06/08/2021 - for the TousAntiCovid project.
//

import Foundation

final class TextCell: CVTableViewCell {

    override func setupAccessibility() {
        let isHeader: Bool = [Appearance.Cell.Text.headTitleFont, Appearance.Cell.Text.smallHeadTitleFont].contains(cvTitleLabel?.font)
        accessibilityLabel = cvTitleLabel?.text?.removingEmojis()
        accessibilityHint = [cvSubtitleLabel?.text, cvAccessoryLabel?.text].compactMap { $0 }.joined(separator: ".\n").removingEmojis()
        accessibilityTraits = isHeader ? .header : .staticText
        accessibilityElements = []
        isAccessibilityElement = true
        cvAccessoryLabel?.isAccessibilityElement = false
        cvTitleLabel?.isAccessibilityElement = false
        cvSubtitleLabel?.isAccessibilityElement = false
    }

}
