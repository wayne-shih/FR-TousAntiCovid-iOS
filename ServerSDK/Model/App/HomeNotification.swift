// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  HomeNotification.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/10/2021 - for the TousAntiCovid project.
//

import Foundation

public struct HomeNotification: Codable {
    public let titleKey: String
    public let subtitleKey: String
    public let urlStringKey: String
    public let version: Int
    
    enum CodingKeys: String, CodingKey {
        case titleKey = "t"
        case subtitleKey = "s"
        case urlStringKey = "u"
        case version = "v"
    }
}
