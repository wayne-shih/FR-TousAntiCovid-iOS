// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CryptoKeyPair.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 26/07/2021 - for the TousAntiCovid project.
//

import Foundation

struct CryptoKeyPair {

    let privateKey: SecKey
    let publicKeyData: Data

}
