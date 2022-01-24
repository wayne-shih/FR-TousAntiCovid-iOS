// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Locale+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

extension Locale {
    
    static var appLocale: Locale { .init(identifier: Locale.currentAppLanguageCode) }

    static var currentAppLanguageCode: String {
        Constant.supportedLanguageCodes.first { $0 == Constant.appLanguage } ?? Constant.supportedLanguageCodes.first { $0 == Locale.current.languageCode } ?? Constant.defaultLanguageCode
    }
    
    static var isCurrentLanguageSupported: Bool {
        Constant.supportedLanguageCodes.contains(Locale.current.languageCode ?? "")
    }
    
}
