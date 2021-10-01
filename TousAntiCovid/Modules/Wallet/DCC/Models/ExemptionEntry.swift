// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ExemptionEntry.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import Foundation
import SwiftyJSON

struct ExemptionEntry: HCertEntry {
    var typeAddon: String { "" }

    var validityFailures: [String] { [] }

    enum Fields: String {
        case diseaseTargeted = "tg"
        case exemptionStatus = "es"
        case validFrom = "df"
        case validUntil = "du"
        case countryCode = "co"
        case issuer = "is"
        case uvci = "ci"
    }

    init?(body: SwiftyJSON.JSON) {
        guard
            let diseaseTargeted = body[Fields.diseaseTargeted.rawValue].string,
            let exemptionStatus = body[Fields.exemptionStatus.rawValue].string,
            let validFromStr = body[Fields.validFrom.rawValue].string,
            let validFrom = Date(dateString: validFromStr),
            let validUntilStr = body[Fields.validUntil.rawValue].string,
            let validUntil = Date(dateString: validUntilStr),
            let country = body[Fields.countryCode.rawValue].string,
            let issuer = body[Fields.issuer.rawValue].string,
            let uvci = body[Fields.uvci.rawValue].string
        else {
            return nil
        }
        self.diseaseTargeted = diseaseTargeted
        self.exemptionStatus = exemptionStatus
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.countryCode = country
        self.issuer = issuer
        self.uvci = uvci
    }

    var diseaseTargeted: String
    var exemptionStatus: String
    var validFrom: Date
    var validUntil: Date
    var countryCode: String
    var issuer: String
    var uvci: String
}
