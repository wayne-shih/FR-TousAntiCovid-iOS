// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Thread+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 10/08/2021 - for the TousAntiCovid project.
//

import Foundation

extension Thread {

    static var callStackSymbolsString: String { callStackSymbols.joined(separator: "\n") }

}
