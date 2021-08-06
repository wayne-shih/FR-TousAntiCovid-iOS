// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UITableView+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/07/2021 - for the TousAntiCovid project.
//

import UIKit

extension UITableView {

    func scrollToTop() {
        let topRow: IndexPath = IndexPath(row: 0, section: 0)
        scrollToRow(at: topRow, at: .top, animated: true)
    }

}
