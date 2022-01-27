// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MultiPassBody.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/01/2022 - for the TousAntiCovid project.
//

import Foundation

struct MultiPassBody: RBServerBody {
    let publicKey: String
    let certificates: [String]
}
