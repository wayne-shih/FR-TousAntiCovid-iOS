// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletAdditionalInfo.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 30/11/2021 - for the TousAntiCovid project.
//

import Foundation
import UIKit

struct AdditionalInfo {
    enum Category {
        case error
        case warning
        case info
        
        var backgroundColor: UIColor {
            switch self {
            case .info: return Asset.Colors.smartWalletInfo.color
            case .warning: return Asset.Colors.bottomWarning.color
            case .error: return Asset.Colors.error.color
            }
        }
    }
    
    var category: Category
    var fullDescription: String
    
    init(category: Category, fullDescription: String) {
        self.category = category
        self.fullDescription = fullDescription
    }
    
    init?(category: Category, fullDescription: String?) {
        guard let fullDescription = fullDescription else { return nil }
        self.init(category: category, fullDescription: fullDescription)
    }
}
