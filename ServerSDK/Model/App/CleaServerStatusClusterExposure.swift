// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CleaStatusClusterExposure.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/04/2021 - for the TousAntiCovid project.
//

import Foundation

public struct CleaServerStatusClusterExposure {

    public let ntpTimestamp: Int
    public let duration: Int
    public let riskLevel: Double

}

extension CleaServerStatusClusterExposure {

    static func from(clusterExposure: RBCleaServerStatusClusterExposure) -> CleaServerStatusClusterExposure {
        CleaServerStatusClusterExposure(ntpTimestamp: clusterExposure.ntpTimestamp,
                                        duration: clusterExposure.duration,
                                        riskLevel: clusterExposure.riskLevel)
    }
    
}
