// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Blacklist2dDocManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/07/2021 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK

protocol Blacklist2dDocChangesObserver: AnyObject {

    func blacklist2dDocDidUpdate()

}

final class Blacklist2dDocObserverWrapper: NSObject {

    weak var observer: Blacklist2dDocChangesObserver?

    init(observer: Blacklist2dDocChangesObserver) {
        self.observer = observer
    }

}

final class Blacklist2dDocManager: NSObject {

    static let shared: Blacklist2dDocManager = Blacklist2dDocManager()

    private var hashes: [String] = []
    private var observers: [Blacklist2dDocObserverWrapper] = []

    @UserDefault(key: .lastInitialBlacklist2dDocBuildNumber)
    private var lastInitialBlacklist2dDocBuildNumber: String? = nil

    func start() {
        writeInitialFileIfNeeded()
        loadLocalCertList()
        addObserver()
    }

    func isBlacklisted(certificate: WalletCertificate) -> Bool {
        guard let uniqueHash = certificate.uniqueHash else { return false }
        return hashes.contains(uniqueHash)
    }

    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func appDidBecomeActive() {
        fetchCertList()
    }

}

// MARK: - All fetching methods -
extension Blacklist2dDocManager {

    private func fetchCertList() {
        let dataTask: URLSessionDataTask = UrlSessionManager.shared.session.dataTaskWithETag(with: Blacklist2dDocConstant.certListUrl) { data, response, error in
            guard let data = data else { return }
            do {
                self.hashes = try JSONDecoder().decode([String].self, from: data)
                try data.write(to: self.localCertListUrl())
            } catch {}
        }
        dataTask.resume()
    }

}

// MARK: - Local files management -
extension Blacklist2dDocManager {

    private func initialFileUrl() -> URL {
        Bundle.main.url(forResource: Blacklist2dDocConstant.filename, withExtension: nil)!
    }

    private func localCertListUrl() -> URL {
        let directoryUrl: URL = self.createWorkingDirectoryIfNeeded()
        return directoryUrl.appendingPathComponent(Blacklist2dDocConstant.filename)
    }

    private func loadLocalCertList() {
        let localUrl: URL = localCertListUrl()
        guard FileManager.default.fileExists(atPath: localUrl.path) else { return }
        guard let data = try? Data(contentsOf: localUrl) else { return }
        hashes = (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private func createWorkingDirectoryIfNeeded() -> URL {
        let directoryUrl: URL = FileManager.libraryDirectory().appendingPathComponent("CertList")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }

    private func writeInitialFileIfNeeded() {
        let fileUrl: URL = initialFileUrl()
        let destinationFileUrl: URL = createWorkingDirectoryIfNeeded().appendingPathComponent(fileUrl.lastPathComponent)
        let currentBuildNumber: String = UIApplication.shared.buildNumber
        let isNewAppVersion: Bool = lastInitialBlacklist2dDocBuildNumber != currentBuildNumber
        if !FileManager.default.fileExists(atPath: destinationFileUrl.path) || isNewAppVersion {
            try? FileManager.default.removeItem(at: destinationFileUrl)
            try? FileManager.default.copyItem(at: fileUrl, to: destinationFileUrl)
            lastInitialBlacklist2dDocBuildNumber = currentBuildNumber
        }
    }

}

extension Blacklist2dDocManager {

    func addObserver(_ observer: Blacklist2dDocChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(Blacklist2dDocObserverWrapper(observer: observer))
    }

    func removeObserver(_ observer: Blacklist2dDocChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }

    private func observerWrapper(for observer: Blacklist2dDocChangesObserver) -> Blacklist2dDocObserverWrapper? {
        observers.first { $0.observer === observer }
    }

    private func notifyObservers() {
        observers.forEach { $0.observer?.blacklist2dDocDidUpdate() }
    }

}
