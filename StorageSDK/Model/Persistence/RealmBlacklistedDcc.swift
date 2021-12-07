// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RealmBlacklistedDcc.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/10/2021 - for the TousAntiCovid project.
//

import RealmSwift

final class RealmBlacklistedDcc: Object {
    @Persisted(primaryKey: true) var hashString: String // Primary key indexed by default
    
    convenience init(hash: String) {
        self.init()
        hashString = hash
    }
}
