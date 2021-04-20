// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletError.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 30/03/2021 - for the TousAntiCovid project.
//

import Foundation

enum WalletError {
    case parsing
    case signature
    
    var code: Int {
        switch self {
        case .parsing:
            return 1
        case .signature:
            return 2
        }
    }
    
    var error: Error { NSError.localizedError(message: "wallet.proof.error.\(code).message".localized, code: code) }
    
}
