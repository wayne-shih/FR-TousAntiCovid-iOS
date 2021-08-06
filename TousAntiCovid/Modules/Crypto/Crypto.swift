// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Crypto.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 26/07/2021 - for the TousAntiCovid project.
//

import Foundation
import SwCrypt

final class Crypto {

    static func generateKeys() throws -> CryptoKeyPair {
        var publicKeySec: SecKey?
        var privateKeySec: SecKey?
        let keyAttributes: CFDictionary = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                                           kSecAttrKeySizeInBits as String: 256] as CFDictionary
        SecKeyGeneratePair(keyAttributes, &publicKeySec, &privateKeySec)
        guard let publicKey = publicKeySec, let privateKey = privateKeySec else {
            throw NSError.localizedError(message: "Impossible to generate a key pair", code: 0)
        }
        let publicKeyData: Data = try publicKey.toDer()
        return CryptoKeyPair(privateKey: privateKey, publicKeyData: publicKeyData)
    }

    static func generateSecret(localPrivateKey: SecKey, remotePublicKey: Data) throws -> Data {
        let publicSecKey: SecKey = try SecKey.publicKeyfromDerData(remotePublicKey)
        var error: Unmanaged<CFError>?
        guard let sharedSecretData = SecKeyCopyKeyExchangeResult(localPrivateKey, .ecdhKeyExchangeStandard, publicSecKey, [:] as CFDictionary, &error) as Data? else {
            throw NSError.localizedError(message: (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "An unknown error occurred creating shared secret", code: 0)
        }
        return sharedSecretData
    }

    static func generateConversionEncryptionKey(sharedSecret: Data) throws -> Data {
        Data([99, 111, 110, 118, 101, 114, 115, 105, 111, 110]).hmac(key: sharedSecret)
    }

    static func encrypt(_ cypher: String, key: Data) throws -> Data {
        guard let cypherData = cypher.data(using: .utf8) else {
            throw NSError.localizedError(message: "Impossible to get data from the cypher", code: 0)
        }
        let iv: Data = try secureRandomData(count: 12)
        return iv + (try CC.cryptAuth(.encrypt, blockMode: .gcm, algorithm: .aes, data: cypherData, aData: Data(), key: key, iv: iv, tagLength: 16))
    }

    static func decrypt(_ base64String: String, key: Data) throws -> String {
        guard let encryptedData = Data(base64Encoded: base64String) else {
            throw NSError.localizedError(message: "Base64 string not properly formatted.", code: 0)
        }
        let iv: Data = Data(encryptedData[0..<12])
        let cypher: Data = Data(encryptedData[12..<encryptedData.count])
        let result: Data = try CC.cryptAuth(.decrypt, blockMode: .gcm, algorithm: .aes, data: cypher, aData: Data(), key: key, iv: iv, tagLength: 16)
        guard let decryptedString = String(data: result, encoding: .utf8) else {
            throw NSError.localizedError(message: "Error when decrypting received DCC.", code: 0)
        }
        return decryptedString
    }

    private static func secureRandomData(count: Int) throws -> Data {
        var bytes: [Int8] = [Int8](repeating: 0, count: count)
        let status: Int32 = SecRandomCopyBytes(
            kSecRandomDefault,
            count,
            &bytes
        )
        if status == errSecSuccess {
            let data = Data(bytes: bytes, count: count)
            return data
        } else {
            return Data()
        }
    }

}
