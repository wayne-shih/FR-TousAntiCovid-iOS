// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  FileManager+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

extension FileManager {
    
    class func documentsDirectory() -> URL {
        try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }
    
    class func libraryDirectory() -> URL {
        try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }
    
}

// MARK: - System volume info -
extension FileManager {
    
    var totalSpaceFormatted: String {
        totalDiskSpace?.format() ?? "??"
    }
    
    var importantAvailableSpaceFormatted: String {
        importantAvailableDiskSpace?.format() ?? "??"
    }
    
    var opportunisticAvailableSpaceFormatted: String {
        opportunisticAvailableDiskSpace?.format() ?? "??"
    }
    
    private var importantAvailableDiskSpace: Int64? {
        var fileURL: URL = documentsDirectory()
        var capacity: Int64? = nil
        do {
            fileURL.removeAllCachedResourceValues()
            let values: URLResourceValues = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let availableCapacity = values.volumeAvailableCapacityForImportantUsage {
                capacity = Int64(availableCapacity)
            } else {
                print("Capacity is unavailable")
            }
        } catch {
            print(error)
        }
        return capacity
    }
    
    var opportunisticAvailableDiskSpace: Int64? {
        var fileURL: URL = documentsDirectory()
        var capacity: Int64? = nil
        do {
            fileURL.removeAllCachedResourceValues()
            let values: URLResourceValues = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForOpportunisticUsageKey])
            if let availableCapacity = values.volumeAvailableCapacityForOpportunisticUsage {
                capacity = Int64(availableCapacity)
            } else {
                print("Capacity is unavailable")
            }
        } catch {
            print(error)
        }
        return capacity
    }
    
    var totalDiskSpace: Int64? {
        var fileURL: URL = documentsDirectory()
        var capacity: Int64? = nil
        do {
            fileURL.removeAllCachedResourceValues()
            let values: URLResourceValues = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey])
            if let totalCapacity = values.volumeTotalCapacity {
                capacity = Int64(totalCapacity)
            } else {
                print("Total capacity is unavailable")
            }
        } catch {
            print(error)
        }
        return capacity
    }
    
    private func documentsDirectory() -> URL {
        return try! url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }
}

private extension Int64 {
    func format() -> String? {
        let formatter: ByteCountFormatter = .init()
        formatter.allowedUnits = .useAll
        formatter.countStyle = .binary
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: self)
    }
}


