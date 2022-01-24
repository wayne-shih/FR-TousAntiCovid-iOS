// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UILabel+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 11/01/2022 - for the TousAntiCovid project.
//

import UIKit

extension UILabel {
    var isTruncated: Bool {
        guard let labelText = text else { return false }
        guard numberOfLines != 0 else { return false }
        let labelTextSize: CGSize = (labelText as NSString).boundingRect(
            with: CGSize(width: frame.size.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font as Any],
            context: nil).size
        let linesRoundedUp: Int = Int(ceil(labelTextSize.height / font.lineHeight))
        return linesRoundedUp > numberOfLines
    }
}
