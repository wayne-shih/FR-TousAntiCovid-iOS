// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ETagManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 15/04/2021 - for the TousAntiCovid project.
//

import Foundation

final class ETagManager {
    
    static let shared: ETagManager = ETagManager()
    
    @UserDefault(key: .eTags)
    private var eTags: [String: String]?
    
    func eTag(for url: String) -> String? {
        eTags?["\(url.hash)"]
    }

    func save(eTag: String, for url: String) {
        var eTags: [String: String] = self.eTags ?? [:]
        eTags["\(url.hash)"] = eTag
        self.eTags = eTags
    }
    
    func clearAllData() {
        eTags = nil
    }

}
