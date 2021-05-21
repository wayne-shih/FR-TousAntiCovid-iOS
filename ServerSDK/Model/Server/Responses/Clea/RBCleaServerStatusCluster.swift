// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBCleaServerStatusCluster.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/04/2021 - for the TousAntiCovid project.
//

import Foundation

struct RBCleaServerStatusCluster: RBServerResponse {

    let ltid: String
    let exposures: [RBCleaServerStatusClusterExposure]

    enum CodingKeys: String, CodingKey {
        case ltid
        case exposures = "exp"
    }
}
