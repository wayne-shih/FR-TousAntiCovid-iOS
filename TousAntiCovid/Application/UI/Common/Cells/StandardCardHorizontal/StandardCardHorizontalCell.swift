// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StandardCardHorizontal.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/02/2021 - for the TousAntiCovid project.
//

import UIKit

final class StandardCardHorizontalCell: CardCell {

    @IBOutlet private var titleStackView: UIStackView?

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
    }

    private func setupUI(with row: CVRow) {
        titleStackView?.isHidden = row.title == nil && row.image == nil
    }

}
