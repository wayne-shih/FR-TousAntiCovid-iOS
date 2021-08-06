// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ImageCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 16/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class ImageCell: CVTableViewCell {

    @IBOutlet private var bottomEdging: UIView?

    override var isAccessibilityElement: Bool {
        get { false }
        set { }
    }
    
    override var accessibilityElementsHidden: Bool {
        get { true }
        set { }
    }

    override func setup(with row: CVRow) {
        super.setup(with: row)
        bottomEdging?.isHidden = !row.theme.showImageBottomEdging
    }
}
