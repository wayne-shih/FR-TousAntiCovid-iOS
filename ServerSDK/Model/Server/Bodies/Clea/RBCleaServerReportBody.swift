// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBCleaServerReportBody.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/11/2020 - for the TousAntiCovid project.
//

import Foundation

struct RBCleaServerReportBody: RBServerBody {

    let pivotDate: Int
    let visits: [RBCleaServerVisit]
    
}
