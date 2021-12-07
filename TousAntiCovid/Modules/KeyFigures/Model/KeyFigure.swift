// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigure.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

struct KeyFigure: Codable {
    
    enum Category: String, Codable, CaseIterable {
        case vaccine
        case health
        case app
    }
    
    enum ChartKind: String, Codable {
        case bars
        case line
    }
    
    let labelKey: String
    let category: Category?
    let valueGlobalToDisplay: String
    let valueGlobal: Double?
    let isFeatured: Bool
    let isHighlighted: Bool?
    let extractDate: Int
    let valuesDepartments: [KeyFigureDepartment]?
    let displayOnSameChart: Bool
    let avgSeries: [KeyFigureSeriesItem]?
    let limitLine: Double?
    let magnitude: UInt32
    
    let series: [KeyFigureSeriesItem]?
    let chartType: ChartKind?
    var isLabelReady: Bool { "\(labelKey).label".localizedOrNil != nil }
    var label: String { "\(labelKey).label".localized.trimmingCharacters(in: .whitespaces) }
    var labelWithUnit: String {
        if let unit = "\(labelKey).unit".localizedOrNil?.trimmingCharacters(in: .whitespaces) {
            return "\(labelKey).label".localized.trimmingCharacters(in: .whitespaces) + " (\(unit))"
        } else {
            return label
        }
    }
    var shortLabel: String { "\(labelKey).shortLabel".localized.trimmingCharacters(in: .whitespaces) }
    var description: String { "\(labelKey).description".localized.trimmingCharacters(in: .whitespaces) }
    var learnMore: String { "\(labelKey).learnMore".localizedOrEmpty.trimmingCharacters(in: .whitespaces) }
    var limitLineLabel: String { "\(labelKey).limitLine".localizedOrEmpty.trimmingCharacters(in: .whitespaces) }
    var color: UIColor {
        let colorCode: String = UIColor.isDarkMode ? "\(labelKey).colorCode.dark".localized : "\(labelKey).colorCode.light".localized
        return UIColor(hexString: colorCode)
    }
    var ascendingSeries: [KeyFigureSeriesItem]? { series?.sorted { $0.date < $1.date } }
    var chartKind: ChartKind { chartType ?? .line }
    
    var formattedDate: String {
        switch category {
        case .vaccine, .health:
            return Date(timeIntervalSince1970: Double(extractDate)).relativelyFormattedDay(prefixStringKey: "keyFigures.update", todayPrefixStringKey: "keyFigures.update.today", yesterdayPrefixStringKey: "keyFigures.update.today")
        case .app:
            return Date(timeIntervalSince1970: Double(extractDate)).relativelyFormatted(prefixStringKey: "keyFigures.update", todayPrefixStringKey: "keyFigures.update.today", yesterdayPrefixStringKey: "keyFigures.update.today")
        default:
            return ""
        }
    }
    
    var currentDepartmentSpecificKeyFigure: KeyFigureDepartment? {
        guard KeyFiguresManager.shared.displayDepartmentLevel else { return nil }
        return valuesDepartments?.first
    }
}

extension KeyFigure: Equatable {
    static func == (lhs: KeyFigure, rhs: KeyFigure) -> Bool {
        lhs.labelKey == rhs.labelKey
    }
}

extension Array where Element == KeyFigure {
    var haveSameMagnitude: Bool {
        Dictionary(grouping: self) { keyFigure in
            keyFigure.magnitude
        }.keys.count == 1
    }
}
