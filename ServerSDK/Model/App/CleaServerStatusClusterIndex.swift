// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CleaStatusClusterIndex.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/04/2021 - for the TousAntiCovid project.
//

import Foundation

public struct CleaServerStatusClusterIndex: Codable {

    public let iteration: Int
    public let clusterPrefixes: [String]
    
}

extension CleaServerStatusClusterIndex {

    static func from(clusterIndex: RBCleaServerStatusClusterIndex) -> CleaServerStatusClusterIndex {
        CleaServerStatusClusterIndex(iteration: clusterIndex.iteration,
                                     clusterPrefixes: clusterIndex.clusterPrefixes)
    }
    
}
