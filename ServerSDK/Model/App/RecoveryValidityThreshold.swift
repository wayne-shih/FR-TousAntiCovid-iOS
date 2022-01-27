// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RecoveryValidityThreshold.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/01/2022 - for the TousAntiCovid project.
//

public struct RecoveryValidityThreshold: Decodable {
    var minDays: Int = 11
    var maxDays: Int = 180
    
    public var minSec: Double { Double(minDays * 3600 * 24) }
    public var maxSec: Double { Double(maxDays * 3600 * 24) }
}
