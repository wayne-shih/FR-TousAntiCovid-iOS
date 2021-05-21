// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ZoomableImageCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 16/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class ZoomableImageCell: CVTableViewCell {

    @IBOutlet private var zoomableImageView: PanZoomImageView!
    
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
        setupContent(with: row)
    }

    private func setupContent(with row: CVRow) {
        zoomableImageView.imageView.image = row.image
    }
    
}
