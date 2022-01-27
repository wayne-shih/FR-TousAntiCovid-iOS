// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MultiPassConfiguration.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/01/2022 - for the TousAntiCovid project.
//

import Foundation

public struct MultiPassConfiguration: Decodable {
    public let testMaxHours: Int
    public let maxDcc: Int
    public let minDcc: Int
    
    init() {
        testMaxHours = 24
        maxDcc = 2
        minDcc = 2
    }
}
