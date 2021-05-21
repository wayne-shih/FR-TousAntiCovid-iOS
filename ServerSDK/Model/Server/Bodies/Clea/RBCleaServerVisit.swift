// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBCleaServerVisit.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/11/2020 - for the TousAntiCovid project.
//

import Foundation

struct RBCleaServerVisit: RBServerBody {

    let qrCodeScanTime: Int
    let qrCode: String

}

extension RBCleaServerVisit {

    static func from(visit: CleaServerVisit) -> RBCleaServerVisit {
        RBCleaServerVisit(qrCodeScanTime: visit.qrCodeScanTime,
                          qrCode: visit.qrCode)
    }
    
}
