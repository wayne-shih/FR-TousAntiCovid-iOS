// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StandardCardSwitchCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 26/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class StandardCardSwitchCell: CardCell {

    @IBOutlet private var titleStackView: UIStackView?
    @IBOutlet var cvSwitch: UISwitch!

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
        setupAccessibility()
    }

    private func setupUI(with row: CVRow) {
        titleStackView?.isHidden = row.title == nil && row.image == nil
        cvSwitch.onTintColor = Appearance.Switch.onTint
        cvSwitch.isOn = row.isOn ?? false
    }

    override func setupAccessibility() {
        super.setupAccessibility()
        accessibilityElements = [cvTitleLabel].compactMap { $0 }
    }

    @IBAction private func switchValueChanged() {
        currentAssociatedRow?.valueChanged?(cvSwitch.isOn)
    }

}
