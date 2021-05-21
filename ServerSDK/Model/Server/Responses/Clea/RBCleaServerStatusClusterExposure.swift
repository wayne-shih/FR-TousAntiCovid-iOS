// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBCleaServerStatusClusterExposure.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/04/2021 - for the TousAntiCovid project.
//

import Foundation

struct RBCleaServerStatusClusterExposure: RBServerResponse {

    let ntpTimestamp: Int
    let duration: Int
    let riskLevel: Double

    enum CodingKeys: String, CodingKey {
        case ntpTimestamp = "s"
        case duration = "d"
        case riskLevel = "r"
    }
    
}
