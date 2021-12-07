// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StackLogger.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 10/08/2021 - for the TousAntiCovid project.
//

import UIKit

final class StackLogger {

    static func log(symbols: String, message: String) {
        let log: String = """

        ------------------------------
        --    ℹ️ SYMBOLS LOG ℹ️     --
        ------------------------------
        📦 APP VERSION: \(UIApplication.shared.marketingVersion) (\(UIApplication.shared.buildNumber))
        📱 iOS VERSION: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
        💾 STORAGE Important available: \(FileManager.default.importantAvailableSpaceFormatted)/\(FileManager.default.totalSpaceFormatted)
        💾 STORAGE Opportunistic available: \(FileManager.default.opportunisticAvailableSpaceFormatted)/\(FileManager.default.totalSpaceFormatted)
        💬 MESSAGE: \(message)
        ⚙️ SYMBOLS:
        \(symbols)
        ------------------------------

        """
        writeLogToFile(log)
    }

    static func log(exception: NSException) {
        let name: String = exception.name.rawValue
        let reason: String = exception.reason ?? "N/A"
        let symbols: String = exception.callStackSymbols.joined(separator: "\n")
        let log: String = """

        ------------------------------
        --     💥 EXCEPTION 💥      --
        ------------------------------
        📦 APP VERSION: \(UIApplication.shared.marketingVersion) (\(UIApplication.shared.buildNumber))
        📱 iOS VERSION: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
        💾 STORAGE Important available: \(FileManager.default.importantAvailableSpaceFormatted)/\(FileManager.default.totalSpaceFormatted)
        💾 STORAGE Opportunistic available: \(FileManager.default.opportunisticAvailableSpaceFormatted)/\(FileManager.default.totalSpaceFormatted)
        👤 NAME: \(name)
        💬 REASON: \(reason)
        ⚙️ SYMBOLS:
        \(symbols)
        ------------------------------
        
        """
        writeLogToFile(log)
    }

    static func getLogFilesUrls() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: StackLoggerConstant.directoryUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []
    }

    static func deleteAllLogsFiles() {
        getLogFilesUrls().forEach { try? FileManager.default.removeItem(at: $0) }
    }

}

extension StackLogger {

    private static func logsWorkingDirectory() -> URL {
        let directoryUrl: URL = StackLoggerConstant.directoryUrl
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }
    private static func currentDailyFileUrl() -> URL { logsWorkingDirectory().appendingPathComponent("\(Date().dayTimestamp())") }

    private static func writeLogToFile(_ log: String) {
        guard let data = log.data(using: .utf8) else { return }
        try? data.append(fileURL: currentDailyFileUrl())
        rollFilesIfNeeded()
    }

    private static func rollFilesIfNeeded() {
        let filesUrls: [URL] = getLogFilesUrls()
        guard filesUrls.count > StackLoggerConstant.rollingDaysCount else { return }
        guard let oldestUrl = filesUrls.sorted(by: { Int($0.lastPathComponent) ?? 0 < Int($1.lastPathComponent) ?? 0 }).first else { return }
        try? FileManager.default.removeItem(at: oldestUrl)
    }

}
