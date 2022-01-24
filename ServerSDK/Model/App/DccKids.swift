// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DccKids.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 24/12/2021 - for the TousAntiCovid project.
//

public struct DccKids: Decodable {
    public var age: Int
    public var smileys: [String]
    
    enum CodingKeys: String, CodingKey {
        case age
        case smileys = "s"
    }
}
