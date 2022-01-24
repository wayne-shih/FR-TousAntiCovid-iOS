// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVHeaderFooterSectionView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 06/10/2021 - for the TousAntiCovid project.
//

import UIKit

class CVHeaderFooterSectionView: UITableViewHeaderFooterView {

    var currentAssociatedHeaderSection: CVFooterHeaderSection?
    @IBOutlet var cvTitleLabel: UILabel?
    @IBOutlet var cvSubtitleLabel: UILabel?
    @IBOutlet private var leadingConstraint: NSLayoutConstraint?
    @IBOutlet private var trailingConstraint: NSLayoutConstraint?
    @IBOutlet private var topConstraint: NSLayoutConstraint?
    @IBOutlet private var bottomConstraint: NSLayoutConstraint?

    func setup(with headerSection: CVFooterHeaderSection) {
        currentAssociatedHeaderSection = headerSection
        cvTitleLabel?.text = headerSection.title
        cvSubtitleLabel?.text = headerSection.subtitle
        setupTheme(with: headerSection)
        setupAccessibility()
    }

    func capture() -> UIImage? {
        return cvScreenshot()
    }
    
    func setupAccessibility() {
        accessibilityTraits = currentAssociatedHeaderSection?.selectionAction != nil ? .button : .staticText
        accessibilityLabel = [cvTitleLabel?.text, cvSubtitleLabel?.text].compactMap { $0 }.joined(separator: "\n").removingEmojis()
        accessibilityElements = []
    }

    private func setupTheme(with headerSection: CVFooterHeaderSection) {
        contentView.backgroundColor = headerSection.theme.backgroundColor
        cvTitleLabel?.isHidden = headerSection.title == nil
        cvTitleLabel?.textAlignment = headerSection.theme.textAlignment
        cvTitleLabel?.adjustsFontForContentSizeCategory = true
        cvTitleLabel?.font = headerSection.theme.titleFont()
        cvTitleLabel?.textColor = headerSection.theme.titleColor

        cvSubtitleLabel?.isHidden = headerSection.subtitle == nil
        cvSubtitleLabel?.textAlignment = headerSection.theme.textAlignment
        cvSubtitleLabel?.adjustsFontForContentSizeCategory = true
        cvSubtitleLabel?.font = headerSection.theme.subtitleFont()
        cvSubtitleLabel?.textColor = headerSection.theme.subtitleColor

        leadingConstraint?.constant = headerSection.theme.leftInset
        trailingConstraint?.constant = headerSection.theme.rightInset
        topConstraint?.constant = headerSection.theme.topInset
        bottomConstraint?.constant = headerSection.theme.bottomInset
    }

}
