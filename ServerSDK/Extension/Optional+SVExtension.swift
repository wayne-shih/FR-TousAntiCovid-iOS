// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Optional+SVExtension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 03/06/2021 - for the TousAntiCovid project.
//

import Foundation

protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}
