// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ChartsValueFormatter.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/01/2021 - for the TousAntiCovid project.
//

import Foundation
import Charts

final class ChartsValueFormatter: IAxisValueFormatter {

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return value.formatKeyFiguresValue()
    }

}
