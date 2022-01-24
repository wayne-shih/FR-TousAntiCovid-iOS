// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SmartWalletConfig.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/11/2021 - for the TousAntiCovid project.
//

import Foundation

public struct SmartWalletConfig {
    public let ages: Ages
    public let exp: Expiration
    public let elg: Eligibility
}

public struct Ages: Codable {
    public var low: Int = 18
    public var lowExpDays: Int = 152
    public var high: Int = 65
    
    enum CodingKeys: String, CodingKey {
        case low
        case lowExpDays
        case high
    }
}

public struct Expiration: Codable {
    public var pivot1: String = "2021-12-15"
    public var pivot2: String = "2033-07-21"
    public var pivot3: String = "2022-02-15"
    public var vacc22DosesNbDays: Int = 214
    public var vacc11DosesNbDays: Int = 214
    public var vacc22DosesNbNewDays: Int = 122
    public var vacc11DosesNbNewDays: Int = 122
    public var recNbDays: Int = 180
    public var vaccJan11DosesNbDays: Int = 61
    public var displayExpDays: Int = 21
    public var displayExpOnAllDcc: Int = 240
    
    enum CodingKeys: String, CodingKey {
        case pivot1
        case pivot2
        case vacc22DosesNbDays
        case vacc11DosesNbDays
        case vacc22DosesNbNewDays
        case vacc11DosesNbNewDays
        case recNbDays
        case vaccJan11DosesNbDays
        case displayExpOnAllDcc
        case displayExpDays
    }
}

public struct Eligibility: Codable {
    public var vacc22DosesNbDays: Int = 153
    public var vaccJan11DosesNbDays: Int = 31
    public var recNbDays: Int = 153
    public var displayElgDays: Int = 60
    
    enum CodingKeys: String, CodingKey {
        case vacc22DosesNbDays
        case vaccJan11DosesNbDays
        case recNbDays
        case displayElgDays
    }
}

public struct Vaccins: Codable {
    public var arnm: [String]
    public var janssen: [String]
    public var astraZeneca: [String]
    
    enum CodingKeys: String, CodingKey {
        case arnm = "ar"
        case janssen = "ja"
        case astraZeneca = "az"
    }
}
