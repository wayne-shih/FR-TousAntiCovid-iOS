// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Double+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/01/2021 - for the TousAntiCovid project.
//

import Foundation

extension Double {
    
    func toString(isPercent: Bool, digits: Int = 2) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = digits
        formatter.alwaysShowsDecimalSeparator = false
        return formatter.string(for: self)?.appending(isPercent ? "%" : "")
    }
    
    func formatKeyFiguresValue() -> String {
        let formatter: NumberFormatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumIntegerDigits = 1
        let string: String
        if self < 1_000.0 {
            string = formatter.string(from: NSNumber(value: self.shrinkedValue()))!
        } else if self < 1_000_000.0 {
            string = formatter.string(from: NSNumber(value: (self / 1000.0).shrinkedValue()))! + "K"
        } else {
            string = formatter.string(from: NSNumber(value: (self / 1_000_000.0).shrinkedValue()))! + "M"
        }
        return string
    }
    
    func shrinkedValue() -> Double {
        let newValue: Double
        if self < 10.0 {
            newValue = Double(Int(self * 100.0)) / 100.0
        } else if self < 100.0 {
            newValue = Double(Int(self * 10.0)) / 10.0
        } else {
            newValue = Double(Int(self))
        }
        return newValue
    }
    
    var truncatedStringValue: String { "\(Int(self))" }
    
    func secondsToDays() -> Int { Int(self/24/3600) }
}
