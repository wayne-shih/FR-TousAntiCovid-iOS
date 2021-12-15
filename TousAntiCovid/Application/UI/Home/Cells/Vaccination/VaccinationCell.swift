// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VaccinationCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 07/12/2021 - for the TousAntiCovid project.
//

import UIKit

final class VaccinationCell: CardCell {
    
    @IBOutlet private weak var titleImageView: UIImageView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
    }
}

// MARK: Private functions
private extension VaccinationCell {
    func setupUI() {
        titleImageView.image = Asset.Images.pharmacy.image
        titleImageView.tintColor = Asset.Colors.gradientEndGreen.color
    }
}
