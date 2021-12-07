// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Blacklist.pb+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 19/10/2021 - for the TousAntiCovid project.
//

import Foundation

extension Blacklist_BlackListMessage {
    
    func split() -> (added: [String], removed: [String]) {
        let dict: Dictionary = .init(grouping: items) { $0.starts(with: "-") }
        return (dict[false] ?? [], dict[true] ?? [])
    }
}

extension Array where Element == String {
    
    private var validationRegex: String {
        "^[a-zA-Z0-9_]{64}$"
    }
    
    func filterValidHashes() -> [String] {
        self ~> validationRegex
    }
}
