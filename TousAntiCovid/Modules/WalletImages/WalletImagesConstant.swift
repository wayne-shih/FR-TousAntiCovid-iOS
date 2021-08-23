// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletImagesConstant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/05/2021 - for the TousAntiCovid project.
//

import Foundation

enum WalletImagesConstant {

    static let baseUrl: URL = URL(string: "https://\(Constant.Server.staticResourcesRootDomain)/json/version-\(Constant.Server.jsonVersion)/Wallet")!
    
    static let minDurationBetweenUpdatesInSeconds: Double = 1.0 * 60.0
}
