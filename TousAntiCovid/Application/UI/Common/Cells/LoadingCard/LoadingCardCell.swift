// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  LoadingCardCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 28/01/2021 - for the TousAntiCovid project.
//

import UIKit

final class LoadingCardCell: CardCell {

    @IBOutlet private var activityIndicator: UIActivityIndicatorView!

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
    }

    private func setupUI(with row: CVRow) {
        activityIndicator.startAnimating()
        activityIndicator.color = .gray
        if #available(iOS 13.0, *) {
            activityIndicator.style = .large
        }
    }

    override func setupAccessibility() {
        super.setupAccessibility()
        accessibilityElements = []
    }

}
