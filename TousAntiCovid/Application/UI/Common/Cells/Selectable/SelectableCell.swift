// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SelectableCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/07/2021 - for the TousAntiCovid project.
//

import UIKit

class SelectableCell: CVTableViewCell {
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupContent(with: row)
    }
    
    private func setupContent(with row: CVRow) {
        self.accessoryType = row.isOn ?? false ? .checkmark : .none
    }
}
