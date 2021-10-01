// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyNumbers.pb+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 31/08/2021 - for the TousAntiCovid project.
//

import Foundation

extension KeyNumbers {

    func toAppModel() -> [KeyFigure] {
        keyfigureList.map {
            KeyFigure(labelKey: $0.labelKey,
                      category: KeyFigure.Category(rawValue: $0.category),
                      valueGlobalToDisplay: $0.valueGlobalToDisplay,
                      valueGlobal: $0.valueGlobal,
                      isFeatured: $0.isFeatured,
                      isHighlighted: $0.isHighlighted,
                      extractDate: Int($0.extractDate),
                      valuesDepartments: $0.valuesDepartments.map { $0.toAppModel() },
                      displayOnSameChart: $0.displayOnSameChart,
                      avgSeries: $0.avgSeries.map { $0.toAppModel() },
                      limitLine: $0.limitLine,
                      series: $0.series.map { $0.toAppModel() },
                      chartType: KeyFigure.ChartKind(rawValue: $0.chartType))
        }
    }

}

extension KeyNumbers.DepartmentValuesMessage {

    func toAppModel() -> KeyFigureDepartment {
        KeyFigureDepartment(number: dptNb,
                            label: dptLabel,
                            extractDate: Int(extractDate),
                            value: value,
                            valueToDisplay: valueToDisplay,
                            series: series.map { $0.toAppModel() })
    }

}

extension KeyNumbers.ElementSerieMessage {

    func toAppModel() -> KeyFigureSeriesItem {
        KeyFigureSeriesItem(date: Double(date), value: value)
    }

}
