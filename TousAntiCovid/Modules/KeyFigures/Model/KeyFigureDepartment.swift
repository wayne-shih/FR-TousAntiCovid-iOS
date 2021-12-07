// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureDepartment.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import Foundation

struct KeyFigureDepartment: Codable {
    
    let number: String
    let label: String
    let extractDate: Int
    let value: Double?
    let valueToDisplay: String
    let series: [KeyFigureSeriesItem]?

    var ascendingSeries: [KeyFigureSeriesItem]? { series?.sorted { $0.date < $1.date } }
    
    var formattedDate: String {
        Date(timeIntervalSince1970: Double(extractDate)).relativelyFormattedDay(prefixStringKey: "keyFigures.update", todayPrefixStringKey: "keyFigures.update.today", yesterdayPrefixStringKey: "keyFigures.update.today")
    }
    
    enum CodingKeys: String, CodingKey {
        case number = "dptNb"
        case label = "dptLabel"
        case extractDate
        case value
        case valueToDisplay
        case series
    }
    
}
