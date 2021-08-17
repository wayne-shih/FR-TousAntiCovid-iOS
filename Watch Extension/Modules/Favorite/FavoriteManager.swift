// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  File.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 05/08/2021 - for the TousAntiCovid project.
//

import Foundation
import UIKit

final class FavoriteManager {

    static let shared: FavoriteManager = FavoriteManager()
    var hasFavorite: Bool { qrData != nil }

    @UserDefault(key: .qr)
    var qrData: Data?

}
