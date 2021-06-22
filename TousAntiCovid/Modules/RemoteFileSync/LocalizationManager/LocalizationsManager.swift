// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  LocalizationsManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

protocol LocalizationsChangesObserver: AnyObject {
    
    func localizationsChanged()
    
}

final class LocalizationsObserverWrapper: NSObject {
    
    weak var observer: LocalizationsChangesObserver?
    
    init(observer: LocalizationsChangesObserver) {
        self.observer = observer
    }
    
}

final class LocalizationsManager: RemoteFileSyncManager {

    static let shared: LocalizationsManager = LocalizationsManager()
    var strings: [String: String] = [:]
    
    @UserDefault(key: .lastInitialStringsBuildNumber)
    private var lastInitialStringsBuildNumber: String? = nil
    
    @UserDefault(key: .lastStringsUpdateDate)
    private var lastUpdateDate: Date = .distantPast
    
    private var observers: [LocalizationsObserverWrapper] = []
    
    override func canUpdateData() -> Bool {
        let now: Date = Date()
        let lastFetchIsTooOld: Bool = now.timeIntervalSince1970 - lastUpdateDate.timeIntervalSince1970 >= RemoteFileConstant.minDurationBetweenUpdatesInSeconds
        let languageChanged: Bool = lastLanguageCode != Locale.currentAppLanguageCode
        return lastFetchIsTooOld || languageChanged
    }
    
    override func saveUpdatedAt() {
        self.lastUpdateDate = Date()
    }
    
    override func lastBuildNumber() -> String? { lastInitialStringsBuildNumber }
    override func saveLastBuildNumber(_ buildNumber: String) {
        lastInitialStringsBuildNumber = buildNumber
    }
    
    override func workingDirectoryName() -> String { "Strings" }
    
    override func initialFileUrl(for languageCode: String) -> URL {
        Bundle.main.url(forResource: "\(RemoteFileConstant.stringsFilePrefix)-\(languageCode)", withExtension: "json") ?? Bundle.main.url(forResource: "\(RemoteFileConstant.stringsFilePrefix)-\(Constant.defaultLanguageCode)", withExtension: "json")!
    }
    
    override func localFileUrl(for languageCode: String) -> URL {
        let directoryUrl: URL = self.createWorkingDirectoryIfNeeded()
        return directoryUrl.appendingPathComponent("\(RemoteFileConstant.stringsFilePrefix)-\(languageCode).json")
    }
    
    override func remoteFileUrl(for languageCode: String) -> URL {
        URL(string: "\(RemoteFileConstant.baseUrl)/\(RemoteFileConstant.stringsFilePrefix)-\(languageCode).json")!
    }
    
    override func processReceivedData(_ data: Data) -> Bool {
        do {
            guard let stringsDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else { return false }
            strings = stringsDict
            return true
        } catch {
            return false
        }
    }
    
    override func notifyObservers() {
        observers.forEach { $0.observer?.localizationsChanged() }
    }
    
}

extension LocalizationsManager {
    
    func addObserver(_ observer: LocalizationsChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(LocalizationsObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: LocalizationsChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: LocalizationsChangesObserver) -> LocalizationsObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
}

extension String {
    
    var localized: String { LocalizationsManager.shared.strings[self] ?? self }
    var localizedOrEmpty: String { LocalizationsManager.shared.strings[self] ?? "" }
    var localizedOrNil: String? { LocalizationsManager.shared.strings[self] }
    
}
