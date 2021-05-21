// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenueQrCodeInfo.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 24/11/2020 - for the TousAntiCovid project.
//

import Foundation

public struct VenueQrCodeInfo {

    public let id: String
    public let ltid: String
    public let ntpTimestamp: Int
    public let base64: String
    public let version: Int

    public init(id: String, ltid: String, ntpTimestamp: Int, base64: String, version: Int) {
        self.id = id
        self.ltid = ltid
        self.ntpTimestamp = ntpTimestamp
        self.base64 = base64
        self.version = version
    }

}
