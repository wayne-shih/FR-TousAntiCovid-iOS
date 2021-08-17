// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Data+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 07/05/2020 - for the TousAntiCovid project.
//


import Foundation
import CommonCrypto

extension Data {
    
    var bytes: [UInt8] { [UInt8](self) }
    
    mutating func wipe() {
        guard let range = Range(NSMakeRange(0, count)) else { return }
        resetBytes(in: range)
    }
    
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: fileURL, options: .atomic)
        }
    }
    
    func derEncodedSignature() throws -> Data {
        guard count != 0 && count % 2 == 0 else { throw NSError.localizedError(message: "Invalid signature", code: 0) }
        let rBytes: [UInt8] = [UInt8](self[..<(count / 2)]).trimmingUselessInitialZeroIfNeeded().prefixingWithZeroIfNegativeInteger()
        let sBytes: [UInt8] = [UInt8](self[(count / 2)...]).trimmingUselessInitialZeroIfNeeded().prefixingWithZeroIfNegativeInteger()
        let bytes: [UInt8] = (rBytes.encodeAsInteger() + sBytes.encodeAsInteger()).encodeAsSequence()
        return Data(bytes)
    }

    func hmac(key: Data) -> Data {
        let string: UnsafePointer<UInt8> = (self as NSData).bytes.bindMemory(to: UInt8.self, capacity: self.count)
        let stringLength = self.count
        let keyString: [CUnsignedChar] = [UInt8](key)
        let keyLength: Int = key.bytes.count
        var result = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyString, keyLength, string, stringLength, &result)
        return Data(result)
    }

    func sha256() -> String { digest().hexString }

    private func digest() -> Data {
        let digestLength: Int = Int(CC_SHA256_DIGEST_LENGTH)
        var hash: [UInt8] = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256((self as NSData).bytes, UInt32(count), &hash)
        return NSData(bytes: hash, length: digestLength) as Data
    }

}
