// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBServerStatusResponse.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/04/2020 - for the TousAntiCovid project.
//

import UIKit

struct RBServerStatusResponse: RBServerResponse {

    let riskLevel: Double
    let lastContactDate: String?
    let lastRiskScoringDate: String?
    let message: String?
    let tuples: String
    let declarationToken: String?
    let analyticsToken: String?
    
}
