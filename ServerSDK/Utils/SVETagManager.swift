// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SVETagManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 03/06/2021 - for the TousAntiCovid project.
//

import Foundation

public final class SVETagManager {

    public static let shared: SVETagManager = SVETagManager()

    @SVUserDefault(key: "eTags")
    private var eTags: [String: String]?

    @SVUserDefault(key: "lastCacheCleaningDate")
    private var lastCacheCleaningData: Date = Date()
    private var cacheLifeTimeInDays: Int = 10

    func eTag(for url: String) -> String? {
        eTags?["\(url.hash)"]
    }

    func save(eTag: String, data: Data, for url: String) {
        dailyCacheCleaning()
        if let oldETag = eTags?["\(url.hash)"] {
            clearLocalDataFile(eTag: oldETag)
        }
        if saveToLocalDataFile(eTag: eTag, data: data) {
            var eTags: [String: String] = self.eTags ?? [:]
            eTags["\(url.hash)"] = eTag
            self.eTags = eTags
        }
    }

    public func clearAllData() {
        eTags = nil
        clearAllLocaDataFile()
    }

    // MARK: - Data File Management -
    func localDataFile(eTag: String) -> Data? {
        let localUrl: URL = localDataFileUrl(eTag: eTag)
        guard FileManager.default.fileExists(atPath: localUrl.path) else {
            delete(eTag: eTag)
            return nil
        }
        do {
            return try Data(contentsOf: localUrl)
        } catch {
            delete(eTag: eTag)
            return nil
        }
    }

    private func delete(eTag: String) {
        var eTags: [String: String] = self.eTags ?? [:]
        guard let index = eTags.first(where: { $0.value == eTag })?.key else {
            return
        }
        eTags[index] = nil
        self.eTags = eTags
    }

    private func clearAllLocaDataFile() {
        try? FileManager.default.removeItem(at: createWorkingDirectoryIfNeeded())
    }

    private func clearLocalDataFile(eTag: String) {
        try? FileManager.default.removeItem(at: localDataFileUrl(eTag: eTag))
    }

    private func saveToLocalDataFile(eTag: String, data: Data) -> Bool {
        do {
            try data.write(to: localDataFileUrl(eTag: eTag))
            return true
        } catch {
            return false
        }
    }

    private func createWorkingDirectoryIfNeeded() -> URL {
        let directoryUrl: URL = FileManager.svLibraryDirectory().appendingPathComponent("SVETag")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }

    private func localDataFileUrl(eTag: String) -> URL {
        createWorkingDirectoryIfNeeded().appendingPathComponent("\(eTag).data")
    }


    // MARK: - Cache Cleaning Management -
    private func dailyCacheCleaning() {
        guard !Calendar.current.isDateInToday(lastCacheCleaningData) else {
            return
        }
        lastCacheCleaningData = Date()
        let directoryUrl: URL = createWorkingDirectoryIfNeeded()
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryUrl,
                                                                       includingPropertiesForKeys: [.contentModificationDateKey],
                                                                       options: .skipsHiddenFiles)
            let limiteDataFileDate: Date = Date().svDateByAddingDays(-cacheLifeTimeInDays)
            let oldFileURLs: [URL] = try fileURLs.filter {
                (try $0.resourceValues(forKeys: [.contentModificationDateKey])).contentModificationDate ?? .distantPast < limiteDataFileDate
            }
            try oldFileURLs.forEach {
                // Delete DataFile
                try FileManager.default.removeItem(at: $0)

                // Delete ETag saved for URL
                let eTag: String = $0.deletingPathExtension().lastPathComponent
                delete(eTag: eTag)
            }
        } catch {}
    }
}
