// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CleaStatusCluster.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/04/2021 - for the TousAntiCovid project.
//

import Foundation

public struct CleaServerStatusCluster {

    public let ltid: String
    public let exposures: [CleaServerStatusClusterExposure]

    public init(ltid: String, exposures: [CleaServerStatusClusterExposure]) {
        self.ltid = ltid
        self.exposures = exposures
    }

}

extension CleaServerStatusCluster {

    static func from(cluster: RBCleaServerStatusCluster) -> CleaServerStatusCluster {
        CleaServerStatusCluster(ltid: cluster.ltid,
                                exposures: cluster.exposures.map { CleaServerStatusClusterExposure.from(clusterExposure: $0) } )
    }

}
