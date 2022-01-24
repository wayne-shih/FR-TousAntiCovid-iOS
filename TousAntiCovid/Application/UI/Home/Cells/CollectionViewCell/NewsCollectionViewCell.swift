// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NewsCollectionViewCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 22/12/2021 - for the TousAntiCovid project.
//

import UIKit

final class NewsCollectionViewCell: CardCollectionViewCell {
    @IBOutlet private var dateLabel: UILabel?
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupTheme(theme: row.theme)
        dateLabel?.text = row.accessoryText
    }
}

private extension NewsCollectionViewCell {
    func setupTheme(theme: CVRow.Theme) {
        containerView.backgroundColor = theme.backgroundColor
        dateLabel?.font = theme.accessoryTextFont?() ?? theme.titleFont()
        dateLabel?.textColor = theme.accessoryTextColor
        dateLabel?.textAlignment = theme.textAlignment
    }
}
