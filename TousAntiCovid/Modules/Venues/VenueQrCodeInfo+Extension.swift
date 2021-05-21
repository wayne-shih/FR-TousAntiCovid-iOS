// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenueQrCodeInfo+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/11/2020 - for the TousAntiCovid project.
//

import Foundation
import StorageSDK
import ServerSDK

extension VenueQrCodeInfo {
    
    enum QrCodeType: Int {
        case `static` = 0
        case dynamic = 1
        
        var name: String {
            switch self {
            case .static:
                return "STATIC"
            case .dynamic:
                return "DYNAMIC"
            }
        }
    }
    
    var venueTypeDisplayName: String {
        let date: Date = Date(timeIntervalSince1900: ntpTimestamp)
        let dateString: String = date.relativelyFormatted(prefixStringKey: "", displayYear: true)

        return String(format: "venuesHistoryController.entry".localized, "venueType.default".localized, dateString)
    }

    func toCleaServerVisit() -> CleaServerVisit {
        CleaServerVisit(qrCodeScanTime: ntpTimestamp,
                           qrCode: base64)
    }
    
}
