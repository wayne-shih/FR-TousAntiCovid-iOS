// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVTextField.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 11/08/2021 - for the TousAntiCovid project.
//

import UIKit

final class CVTextField: UITextField {

    override public var accessibilityValue: String? {
        get { self.text }
        set { super.accessibilityValue = newValue }
    }

}
