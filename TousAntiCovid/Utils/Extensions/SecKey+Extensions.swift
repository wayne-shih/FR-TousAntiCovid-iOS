// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SecKey+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/03/2021 - for the TousAntiCovid project.
//

import Foundation

extension SecKey {
    
    static let derHeader: Data = Data([0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00])
    
    static func publicKeyfromDer(data: Data) throws -> SecKey {
        guard data.count > SecKey.derHeader.count else {
            throw NSError.localizedError(message: "Malformed der key data provided.", code: 0)
        }
        let keyData: Data = data[SecKey.derHeader.count..<data.count]
        let publicAttributes: CFDictionary = [kSecAttrKeyType: kSecAttrKeyTypeEC,
                                              kSecAttrKeyClass: kSecAttrKeyClassPublic,
                                              kSecAttrKeySizeInBits: 256] as CFDictionary
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(keyData as CFData, publicAttributes, &error) else {
            throw NSError.localizedError(message: (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "An unknown error occurred creating SecKey from provided data", code: 0)
        }
        return secKey
    }
    
}
