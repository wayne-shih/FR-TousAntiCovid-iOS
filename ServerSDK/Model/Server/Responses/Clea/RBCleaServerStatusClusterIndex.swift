// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBCleaServerStatusClusterIndex.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/11/2020 - for the TousAntiCovid project.
//

import Foundation

struct RBCleaServerStatusClusterIndex: RBServerResponse {

    let iteration: Int
    let clusterPrefixes: [String]

    enum CodingKeys: String, CodingKey {
        case iteration = "i"
        case clusterPrefixes = "c"
    }
    
}
