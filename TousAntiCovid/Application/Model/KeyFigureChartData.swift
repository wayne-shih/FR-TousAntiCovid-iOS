// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureChartData.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/01/2021 - for the TousAntiCovid project.
//

import Foundation

struct KeyFigureChartData {

    let id: String = UUID().uuidString
    let legend: KeyFigureChartLegend
    let series: [KeyFigureSeriesItem]
    let currentValueToDisplay: String?
    let footer: String?
    let minValue: Double
    let maxValue: Double
    let isAverage: Bool
    let limitLineValue: Double?
    let limitLineLabel: String?
    let chartKind: KeyFigure.ChartKind
    let magnitude: UInt32

    var initialValue: Double { series.first?.value ?? 0.0 }
    var lastValue: Double { series.last?.value ?? 0.0 }

    init(legend: KeyFigureChartLegend,
         series: [KeyFigureSeriesItem],
         currentValueToDisplay: String?,
         footer: String?,
         isAverage: Bool = false,
         limitLineValue: Double?,
         limitLineLabel: String?,
         chartKind: KeyFigure.ChartKind,
         magnitude: UInt32) {
        self.legend = legend
        self.series = series
        self.currentValueToDisplay = currentValueToDisplay
        self.footer = footer
        self.minValue = series.min { $0.value < $1.value }?.value ?? 0.0
        self.maxValue = series.max { $0.value < $1.value }?.value ?? 0.0
        self.isAverage = isAverage
        self.limitLineValue = limitLineValue
        self.limitLineLabel = limitLineLabel
        self.chartKind = chartKind
        self.magnitude = magnitude
    }

}

extension Array where Element == KeyFigureChartData {
    var haveSameMagnitude: Bool {
        Dictionary(grouping: self) { $0.magnitude }.keys.count == 1
    }
}
