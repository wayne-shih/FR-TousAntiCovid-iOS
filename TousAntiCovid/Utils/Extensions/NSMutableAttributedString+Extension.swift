// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NSMutableAttributedString+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 15/02/2021 - for the TousAntiCovid project.
//

import UIKit

extension NSMutableAttributedString {

    func color(text: String, color: UIColor) {
        let paramsRange: NSRange = (string as NSString).range(of: text)
        addAttributes([.foregroundColor: color], range: paramsRange)
    }
    
}
