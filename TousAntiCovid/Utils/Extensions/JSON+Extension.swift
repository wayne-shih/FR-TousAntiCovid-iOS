// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  JSON+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 15/02/2021 - for the TousAntiCovid project.
//

import Foundation

extension JSON {
    
    func prettyPrinted() -> String? {
        let jsonData: Data
        if #available(iOS 13.0, *) {
            guard let data = try? JSONSerialization.data(withJSONObject: self, options: [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]) else { return nil }
            jsonData = data
        } else {
             guard let data = try? JSONSerialization.data(withJSONObject: self, options: [ .prettyPrinted]) else { return nil }
            jsonData = data
        }
        return String(data: jsonData, encoding: .utf8)
    }
    
}

extension Headers {
    
    func prettyPrinted() -> String? {
        let jsonData: Data
        if #available(iOS 13.0, *) {
            guard let data = try? JSONSerialization.data(withJSONObject: self, options: [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]) else { return nil }
            jsonData = data
        } else {
            guard let data = try? JSONSerialization.data(withJSONObject: self, options: [ .prettyPrinted]) else { return nil }
            jsonData = data
        }
        return String(data: jsonData, encoding: .utf8)
    }
    
}
