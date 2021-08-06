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
    // 150 bytes
    static let derHeaderData: Data = Data([0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00])
    static let privateDerHeaderData: Data = Data([0x30, 0x81, 0x93, 0x02, 0x01, 0x00, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x04, 0x79, 0x30, 0x77, 0x02, 0x01, 0x01, 0x04, 0x20])
    
    static func publicKeyfromDerData(_ data: Data) throws -> SecKey {
        guard data.count > SecKey.derHeaderData.count else {
            throw NSError.localizedError(message: "Malformed der key data provided.", code: 0)
        }
        let keyData: Data = data[SecKey.derHeaderData.count..<data.count]
        let publicAttributes: CFDictionary = [kSecAttrKeyType: kSecAttrKeyTypeEC,
                                              kSecAttrKeyClass: kSecAttrKeyClassPublic,
                                              kSecAttrKeySizeInBits: 256] as CFDictionary
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(keyData as CFData, publicAttributes, &error) else {
            throw NSError.localizedError(message: (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "An unknown error occurred creating SecKey from provided data", code: 0)
        }
        return secKey
    }

    func toDer() throws -> Data {
        var error: Unmanaged<CFError>?
        guard let keyDataSec1 = SecKeyCopyExternalRepresentation(self, &error) as Data? else {
            throw NSError.localizedError(message: (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "An unknown error occurred exporting key data", code: 0)
        }
        return SecKey.derHeaderData + keyDataSec1
    }

    func toPrivateDer() throws -> Data {
        var error: Unmanaged<CFError>?
        guard let keyDataSec1 = SecKeyCopyExternalRepresentation(self, &error) as Data? else {
            throw NSError.localizedError(message: (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "An unknown error occurred exporting key data", code: 0)
        }
        return SecKey.privateDerHeaderData + keyDataSec1
    }

    func exportData() throws -> Data {
        var error: Unmanaged<CFError>?
        guard let keyDataSec1 = SecKeyCopyExternalRepresentation(self, &error) as Data? else {
            throw NSError.localizedError(message: (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "An unknown error occurred exporting key data", code: 0)
        }
        return keyDataSec1
    }
    
}
