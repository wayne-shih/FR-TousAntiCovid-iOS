// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MultiPassErrorResponse.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/01/2022 - for the TousAntiCovid project.
//

import Foundation

struct MultiPassErrorResponse: RBServerResponse {
    let status: Int
    let errors: [MultiPassError]?
}

