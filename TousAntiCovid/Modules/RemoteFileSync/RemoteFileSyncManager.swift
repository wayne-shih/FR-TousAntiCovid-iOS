// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RemoteFileSyncManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 15/04/2020 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK

class RemoteFileSyncManager {
    
    @UserDefault(key: .lastRemoteFileLanguageCode)
    var lastLanguageCode: String? = nil  {
        didSet {
            guard oldValue != lastLanguageCode else { return }
            ETagManager.shared.clearAllData()
        }
    }
    
    func start() {
        writeInitialFileIfNeeded()
        loadLocalFile()
        addObserver()
    }
    
    func reloadLanguage() {
        writeInitialFileIfNeeded()
        loadLocalFile()
        notifyObservers()
        fetchLastFile(languageCode: Locale.currentAppLanguageCode)
    }
    
    func workingDirectoryName() -> String { fatalError("Must be overriden") }
    func initialFileUrl(for languageCode: String) -> URL { fatalError("Must be overriden") }
    func localFileUrl(for languageCode: String) -> URL { fatalError("Must be overriden") }
    func remoteFileUrl(for languageCode: String) -> URL { fatalError("Must be overriden") }
    
    func notifyObservers() {}
    
    @discardableResult func processReceivedData(_ data: Data) -> Bool { fatalError("Must be overriden") }
    
    func createWorkingDirectoryIfNeeded() -> URL {
        let directoryUrl: URL = FileManager.libraryDirectory().appendingPathComponent(workingDirectoryName())
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }
    
    func canUpdateData() -> Bool { fatalError("Must be overriden") }
    func saveUpdatedAt() { fatalError("Must be overriden") }
    func lastBuildNumber() -> String? { fatalError("Must be overriden") }
    func saveLastBuildNumber(_ buildNumber: String) { fatalError("Must be overriden") }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        guard !RemoteFileConstant.useOnlyLocalStrings && canUpdateData() else { return }
        fetchLastFile(languageCode: Locale.currentAppLanguageCode)
    }
    
    private func fetchLastFile(languageCode: String) {
        let url: URL = remoteFileUrl(for: languageCode)
        let dataTask: URLSessionDataTask = UrlSessionManager.shared.session.dataTaskWithETag(with: url) { data, response, error in
            guard let data = data else {
                return
            }
            do {
                let localUrl: URL = self.localFileUrl(for: languageCode)
                if self.processReceivedData(data) {
                    try data.write(to: localUrl)
                    self.saveUpdatedAt()
                } else {
                    self.loadLocalFile()
                }
                self.lastLanguageCode = Locale.currentAppLanguageCode
                DispatchQueue.main.async { self.notifyObservers() }
            } catch {}
        }
        dataTask.resume()
    }
    
    private func loadLocalFile() {
        var localUrl: URL = localFileUrl(for: Locale.currentAppLanguageCode)
        if !FileManager.default.fileExists(atPath: localUrl.path) {
            localUrl = localFileUrl(for: Constant.defaultLanguageCode)
        }
        guard let data = try? Data(contentsOf: localUrl) else { return }
        processReceivedData(data)
    }
    
    private func writeInitialFileIfNeeded() {
        let fileUrl: URL = initialFileUrl(for: Locale.currentAppLanguageCode)
        let destinationFileUrl: URL = createWorkingDirectoryIfNeeded().appendingPathComponent(fileUrl.lastPathComponent)
        let currentBuildNumber: String = UIApplication.shared.buildNumber
        let isNewAppVersion: Bool = lastBuildNumber() != currentBuildNumber
        let languageChanged: Bool = lastLanguageCode != Locale.currentAppLanguageCode
        if !FileManager.default.fileExists(atPath: destinationFileUrl.path) || RemoteFileConstant.useOnlyLocalStrings || isNewAppVersion || languageChanged {
            try? FileManager.default.removeItem(at: destinationFileUrl)
            try? FileManager.default.copyItem(at: fileUrl, to: destinationFileUrl)
            saveLastBuildNumber(currentBuildNumber)
        }
    }
    
}
