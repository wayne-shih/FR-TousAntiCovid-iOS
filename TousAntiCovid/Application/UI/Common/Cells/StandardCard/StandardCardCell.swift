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

final class StandardCardCell: CardCell {

    @IBOutlet private var titleStackView: UIStackView?

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
    }

    private func setupUI(with row: CVRow) {
        titleStackView?.isHidden = row.title == nil && row.image == nil
    }

    override func setupAccessibility() {
        super.setupAccessibility()
        titleStackView?.isAccessibilityElement = false
    }

}
