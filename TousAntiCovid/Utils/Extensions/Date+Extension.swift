// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Date+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 04/05/2020 - for the TousAntiCovid project.
//

import Foundation

extension Calendar {
    static var utc: Calendar {
        var calendar: Calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}

extension Date {

    func dateFormatted() -> String {
        let formatter: DateFormatter = .init()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    func timeFormatted() -> String {
        let formatter: DateFormatter = .init()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    func shortDateTimeFormatted() -> String {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "dd/MM/yyyy, HH:mm"
        return formatter.string(from: self).uppercased()
    }
    
    func shortDateFormatted(timeZoneIndependant: Bool) -> String {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "dd/MM/yyyy"
        if timeZoneIndependant {
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
        }
        return formatter.string(from: self).uppercased()
    }
    
    func shortTimeFormatted() -> String {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self).uppercased()
    }
    
    func dayMonthFormatted() -> String {
        let formatter: DateFormatter = .init()
        formatter.setLocalizedDateFormatFromTemplate("dMMMM")
        return formatter.string(from: self)
    }
    
    func dayShortMonthFormatted() -> String {
        let formatter: DateFormatter = .init()
        formatter.setLocalizedDateFormatFromTemplate("dMMM")
        return formatter.string(from: self)
    }
    
    func dayShortMonthYearFormatted(timeZoneIndependant: Bool, forceEnglishFormat: Bool = false) -> String {
        let formatter: DateFormatter = .init()
        if timeZoneIndependant {
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
        }
        if forceEnglishFormat {
            formatter.locale = Locale(identifier: "en-GB")
        }
        formatter.setLocalizedDateFormatFromTemplate("dMMMyyyy")
        return formatter.string(from: self)
    }
    
    func dayShortMonthYearTimeFormatted(forceEnglishFormat: Bool = false) -> String {
        let formatter: DateFormatter = .init()
        if forceEnglishFormat {
            formatter.locale = Locale(identifier: "en-GB")
        }
        formatter.setLocalizedDateFormatFromTemplate("dMMMyyyyHHmm")
        return formatter.string(from: self)
    }

    func dayMonthYearTimeFormatted(forceEnglishFormat: Bool = false) -> String {
        let formatter: DateFormatter = .init()
        if forceEnglishFormat {
            formatter.locale = Locale(identifier: "en-GB")
        }
        formatter.setLocalizedDateFormatFromTemplate("dMMMMyyyyHHmm")
        return formatter.string(from: self)
    }
    
    func fullDayMonthFormatted() -> String {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: self)
    }

    func dayNameShortDayMonthFormatted() -> String {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "EEEE dd/MM"
        return formatter.string(from: self)
    }

    func shortDayMonthFormatted() -> String {
        let formatter: DateFormatter = .init()
        formatter.setLocalizedDateFormatFromTemplate("ddMM")
        return formatter.string(from: self)
    }
    
    func dayMonthYearFormatted() -> String {
        let formatter: DateFormatter = .init()
        formatter.setLocalizedDateFormatFromTemplate("dMMMMyyyy")
        return formatter.string(from: self)
    }
    
    func fullTextFormatted() -> String {
        let formatter: DateFormatter = .init()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func fullDateTimeFormatted(withSeconds: Bool = true) -> String {
        let formatter: DateFormatter = .init()
        formatter.dateStyle = .short
        formatter.timeStyle = withSeconds ? .medium : .short
        return formatter.string(from: self)
    }
    
    func dateByAddingDays(_ days: Int) -> Date {
        addingTimeInterval(Double(days) * 24.0 * 3600.0)
    }
    
    func dateByAddingYears(_ years: Int) -> Date {
        var dateComponent: DateComponents = DateComponents()
        dateComponent.year = years
        return Calendar.current.date(byAdding: dateComponent, to: self)!
    }
    
    func fullDateFormatted() -> String {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: self)
    }
    
    func testCodeFormatted() -> String {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "dMMMyyyy"
        return formatter.string(from: self).uppercased()
    }
    
    func underscoreDateFormatted() -> String {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "dd_MM_yyyy"
        return formatter.string(from: self).uppercased()
    }
    
    func universalDateFormatted() -> String {
        let formatter: ISO8601DateFormatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
    
    #if !WIDGET
    func relativelyFormatted(prefixStringKey: String = "myHealthController.notification.update", todayPrefixStringKey: String? = nil, yesterdayPrefixStringKey: String? = nil, displayYear: Bool = false) -> String {
        if Calendar.current.isDateInToday(self) {
            let lastPart: String = String(format: "\("common.today".localized.lowercased()), %@", timeFormatted())
            return prefixStringKey.isEmpty ? lastPart : String(format: (todayPrefixStringKey ?? prefixStringKey).localized, lastPart)
        } else if Calendar.current.isDateInYesterday(self) {
            let lastPart: String = String(format: "\("common.yesterday".localized.lowercased()), %@", timeFormatted())
            return prefixStringKey.isEmpty ? lastPart : String(format: (yesterdayPrefixStringKey ?? prefixStringKey).localized, lastPart)
        } else {
            return prefixStringKey.isEmpty ? String(format: "%@, %@", displayYear ? dayMonthYearFormatted() : dayMonthFormatted(), timeFormatted()) : String(format: "\(prefixStringKey.localized), %@", dayMonthFormatted(), timeFormatted())
        }
    }
    
    func relativelyFormattedDay(prefixStringKey: String = "myHealthController.notification.update", todayPrefixStringKey: String? = nil, yesterdayPrefixStringKey: String? = nil) -> String {
        if Calendar.current.isDateInToday(self) {
            let lastPart: String = String(format: "\("common.today".localized.lowercased())")
            return String(format: (todayPrefixStringKey ?? prefixStringKey).localized, lastPart)
        } else if Calendar.current.isDateInYesterday(self) {
            let lastPart: String = String(format: "\("common.yesterday".localized.lowercased())")
            return String(format: (yesterdayPrefixStringKey ?? prefixStringKey).localized, lastPart)
        } else {
            return String(format: "\(prefixStringKey.localized)", dayMonthFormatted())
        }
    }
    
    func accessibilityRelativelyFormattedDate(prefixStringKey: String = "myHealthController.notification.update", todayPrefixStringKey: String? = nil, yesterdayPrefixStringKey: String? = nil) -> String {
        let hourComponents: DateComponents = Calendar.current.dateComponents([.hour, .minute], from: self)
        let accessibilityHour: String = DateComponentsFormatter.localizedString(from: hourComponents, unitsStyle: .spellOut) ?? ""
        if Calendar.current.isDateInToday(self) {
            let lastPart: String = String(format: "\("common.today".localized), %@", accessibilityHour)
            return String(format: (todayPrefixStringKey ?? prefixStringKey).localized, lastPart)
        } else if Calendar.current.isDateInYesterday(self) {
            let lastPart: String = String(format: "\("common.yesterday".localized), %@", accessibilityHour)
            return String(format: (yesterdayPrefixStringKey ?? prefixStringKey).localized, lastPart)
        } else {
            let accessibilityDate: String = DateFormatter.localizedString(from: self, dateStyle: .medium, timeStyle: .none)
            return String(format: "\(prefixStringKey.localized), %@", accessibilityDate, accessibilityHour)
        }
    }
    
    
    func relativelyFormattedForWidget() -> String {
        String(format: "\("myHealthController.notification.update".localized), %@", dayMonthFormatted(), timeFormatted())
    }
    
    func agoFormatted() -> String {
        let elapsedTime: Int = Int(Date().timeIntervalSince1970 - timeIntervalSince1970)
        let secondsInADay: Int = 24 * 3600
        switch elapsedTime {
        case 0..<60:
            return "common.justNow".localized
        case 60..<3600:
            // Minutes count.
            return String(format: "common.ago".localized, "")
        case 3600..<secondsInADay:
            // Hours count.
            return String(format: "common.ago".localized, "")
        case secondsInADay..<(7 * secondsInADay):
            // Days count.
            return String(format: "common.ago".localized, "")
        default:
            // Date + hours
            return ""
        }
    }
    #endif
    
    func roundingToBeginningOfDay() -> Date? {
        var components: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)
    }
    
    func roundingToEndOfDay() -> Date? {
        var components: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return Calendar.current.date(from: components)
    }

    func roundingToNoon() -> Date? {
        var components: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        components.hour = 12
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)
    }
    
    func roundingToMidnightPastOne() -> Date {
        var components: DateComponents = Calendar.utc.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        components.hour = 0
        components.minute = 1
        components.second = 0
        return Calendar.utc.date(from: components) ?? self
    }

    func roundingToHour() -> Date? {
        var components: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)
    }

    func dayTimestamp() -> Int { Int(roundingToBeginningOfDay()?.timeIntervalSince1970 ?? 0) }

}

extension Date {
    
    var timeIntervalSince1900: Int {
        return Int(timeIntervalSince1970) + 2208988800
    }
    
    init(timeIntervalSince1900: Int) {
        self.init(timeIntervalSince1970: Double(timeIntervalSince1900 - 2208988800))
    }
    
    func svDateByAddingDays(_ days: Int) -> Date {
        addingTimeInterval(Double(days) * 24.0 * 3600.0)
    }
    
}

// MARK: Date string extenssion
extension String {
    var isLunarDate: Bool {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: self) == nil
    }
}
