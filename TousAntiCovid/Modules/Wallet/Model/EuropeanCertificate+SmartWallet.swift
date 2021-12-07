// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  EuropeanCertificate+SmartWallet.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 30/11/2021 - for the TousAntiCovid project.
//

import Foundation

// MARK: - Dates alignement
extension EuropeanCertificate {
    var alignedTimestamp: Double { timestamp.roundToMidnightPastOne() }
    var alignedBirthdate: Double { birthdate.roundToMidnightPastOne() }
    
    var userAge: Int {
        let birthdate: Date = Date(timeIntervalSince1970: alignedBirthdate)
        return Calendar.utc.dateComponents([.year], from: birthdate, to: Date().roundingToMidnightPastOne()).year ?? 0
    }
    
    var formattedName: String { fullName.capitalized }
    
    func userBirthdayTimestamp(for age: Int) -> Double {
        Calendar.utc.date(byAdding: .year, value: age, to: Date(timeIntervalSince1970: alignedBirthdate))?.timeIntervalSince1970 ?? 0
    }
}

// MARK: - Utils
private extension Double {
    func roundToMidnightPastOne() -> Double {
        Date(timeIntervalSince1970: self).roundingToMidnightPastOne().timeIntervalSince1970
    }
}
