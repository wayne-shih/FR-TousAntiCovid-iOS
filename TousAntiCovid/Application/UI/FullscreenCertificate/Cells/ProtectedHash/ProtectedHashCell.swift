// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ProtectedHashCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 22/10/2021 - for the TousAntiCovid project.
//

import UIKit

final class ProtectedHashCell: CVTableViewCell {
    override var isAccessibilityElement: Bool {
        get { false }
        set { }
    }

    override var accessibilityElementsHidden: Bool {
        get { true }
        set { }
    }

    @IBOutlet private var fakeTextField: UITextField!
    private let protectedLabel: UILabel = UILabel()

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
    }

    private func setupUI(with row: CVRow) {
        protectedLabel.textAlignment = row.theme.textAlignment
        protectedLabel.adjustsFontForContentSizeCategory = true
        protectedLabel.font = row.theme.titleFont()
        protectedLabel.textColor = row.theme.titleColor
        protectedLabel.text = row.title
        protectedLabel.numberOfLines = 0
        fakeTextField?.subviews.first?.addConstrainedSubview(protectedLabel)
    }
}
