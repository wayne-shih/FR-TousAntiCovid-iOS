// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  HeaderWithActionView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/12/2021 - for the TousAntiCovid project.
//

import UIKit

final class HeaderWithActionView: CVHeaderFooterSectionView {
    @IBOutlet private weak var actionButton: UIButton!
    
    @IBAction private func buttonPressed() {
        currentAssociatedHeaderSection?.selectionAction?()
    }
    
    override func setup(with headerSection: CVFooterHeaderSection) {
        super.setup(with: headerSection)
        setupTheme()
        actionButton.setTitle(headerSection.subtitle, for: .normal)
    }
    
    override func setupAccessibility() {
        super.setupAccessibility()
        isAccessibilityElement = false
        accessibilityElements = [actionButton].compactMap { $0 }
        accessibilityTraits = .button
        actionButton.accessibilityLabel = [currentAssociatedHeaderSection?.title, currentAssociatedHeaderSection?.subtitle].compactMap { $0 }.joined(separator: ":").removingEmojis()
        actionButton.isAccessibilityElement = true
    }
}

// MARK: - Private functions
private extension HeaderWithActionView {
    func setupTheme() {
        actionButton.tintColor = Appearance.tintColor
    }
}
 
