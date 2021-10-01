// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ConversionServerConvertBody.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 24/06/2021 - for the TousAntiCovid project.
//

import Foundation 

struct ConversionServerConvertBody: RBServerBody {
    let chainEncoded: String
    let source: String
    let destination: String
}
