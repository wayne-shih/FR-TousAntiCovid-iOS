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
        var rBytes: [UInt8] = [UInt8](self[..<(count / 2)])
        var sBytes: [UInt8] = [UInt8](self[(count / 2)...])

        if rBytes.first! >= 0x80 {
            rBytes.insert(0x00, at: 0)
        }
        if sBytes.first! >= 0x80 {
            sBytes.insert(0x00, at: 0)
        }

        let bytes: [UInt8] = (rBytes.encodeAsInteger() + sBytes.encodeAsInteger()).encodeAsSequence()
        
        return Data(bytes)
    }
    
}
