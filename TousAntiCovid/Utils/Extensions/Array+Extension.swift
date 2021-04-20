// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Array+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import Foundation

extension Array {
    
    func item(at index: Int) -> Element? {
        index < count ? self[index] : nil
    }
    
    func max<T: Comparable>(_ keyPath: KeyPath<Element, T>) -> Element? {
        self.max(by: { $0[keyPath: keyPath] < $1[keyPath: keyPath] })
    }
    
    func maxValue<T: Comparable>(_ keyPath: KeyPath<Element, T>) -> T? {
        self.max(by: { $0[keyPath: keyPath] < $1[keyPath: keyPath] })?[keyPath: keyPath]
    }
    
}

extension Array where Element == UInt8 {
    
    func encodeAsInteger() -> [UInt8] {
        var tlvTriplet: [UInt8] = []
        tlvTriplet.append(0x02)
        tlvTriplet.append(contentsOf: lengthField())
        tlvTriplet.append(contentsOf: self)
        return tlvTriplet
    }
    
    func encodeAsSequence() -> [UInt8] {
        var tlvTriplet: [UInt8] = []
        tlvTriplet.append(0x30)
        tlvTriplet.append(contentsOf: lengthField())
        tlvTriplet.append(contentsOf: self)
        return tlvTriplet
    }

    private func lengthField() -> [UInt8] {
        var bytesCount: Int = count
        guard bytesCount >= 128 else { return [UInt8(bytesCount)] }
        
        let lengthBytesCount: Int = Int((log2(Double(bytesCount)) / 8) + 1)
        let firstLengthFieldByte: UInt8 = UInt8(128 + lengthBytesCount)
        
        var lengthField: [UInt8] = []
        (0..<lengthBytesCount).forEach { _ in
            let lengthByte: UInt8 = UInt8(bytesCount & 0xff)
            lengthField.insert(lengthByte, at: 0)
            bytesCount = bytesCount >> 8
        }
        lengthField.insert(firstLengthFieldByte, at: 0)
        
        return lengthField
    }
    
}
