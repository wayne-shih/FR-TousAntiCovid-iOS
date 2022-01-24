// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CardCollectionViewCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 10/12/2021 - for the TousAntiCovid project.
//

import UIKit

class CardCollectionViewCell: CVCollectionViewCell {
    @IBOutlet var containerView: UIView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        backgroundColor = .clear
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
        containerView.layer.maskedCorners = row.theme.maskedCorners
    }
}
