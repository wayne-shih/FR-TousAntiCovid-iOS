// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ChartsDateFormatter.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/01/2021 - for the TousAntiCovid project.
//

import Foundation
import Charts

final class ChartsDateFormatter: IAxisValueFormatter {

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date: Date = Date(timeIntervalSince1970: value)
        let year: Int = Calendar.current.component(.year, from: date)
        let currentYear: Int = Calendar.current.component(.year, from: Date())
        return year != currentYear ? date.dateFormatted() : date.shortDayMonthFormatted()
    }

}
