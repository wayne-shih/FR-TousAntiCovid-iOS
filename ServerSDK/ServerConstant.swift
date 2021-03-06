// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ServerConstant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 27/04/2020 - for the TousAntiCovid project.
//

import Foundation

public enum ServerConstant {
    
    static let timeout: Double = 30.0
    static let largeTimeout: Double = 90.0
    static let maxClockShiftToleranceInSeconds: Double = 120.0
    public static let acceptedReportCodeLength: [Int] = [6, 36]
    
    enum Etag {
        static let requestHeaderField: String = "If-None-Match"
        static let responseHeaderField: String = "Etag"
    }
    
}
