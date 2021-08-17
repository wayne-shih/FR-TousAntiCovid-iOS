// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DccBlacklistManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/07/2021 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK

protocol DccBlacklistChangesObserver: AnyObject {

    func dccBlacklistDidUpdate()

}

final class DccBlacklistObserverWrapper: NSObject {

    weak var observer: DccBlacklistChangesObserver?

    init(observer: DccBlacklistChangesObserver) {
        self.observer = observer
    }

}

final class DccBlacklistManager: NSObject {

    static let shared: DccBlacklistManager = DccBlacklistManager()

    private var hashes: [String] = []
    private var observers: [DccBlacklistObserverWrapper] = []

    @UserDefault(key: .lastInitialDccBlacklistBuildNumber)
    private var lastInitialDccBlacklistBuildNumber: String? = nil

    func start() {
        writeInitialFileIfNeeded()
        loadLocalCertList()
        addObserver()
    }

    func isBlacklisted(certificate: WalletCertificate) -> Bool {
        guard let cert = certificate as? EuropeanCertificate else { return false }
        return hashes.contains(cert.uniqueHash)
    }

    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func appDidBecomeActive() {
        fetchCertList()
    }

}

// MARK: - All fetching methods -
extension DccBlacklistManager {

    private func fetchCertList() {
        let session: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let dataTask: URLSessionDataTask = session.dataTaskWithETag(with: DccBlacklistConstant.certListUrl) { data, response, error in
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
extension DccBlacklistManager {

    private func initialFileUrl() -> URL {
        Bundle.main.url(forResource: DccBlacklistConstant.filename, withExtension: nil)!
    }

    private func localCertListUrl() -> URL {
        let directoryUrl: URL = self.createWorkingDirectoryIfNeeded()
        return directoryUrl.appendingPathComponent(DccBlacklistConstant.filename)
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
        let isNewAppVersion: Bool = lastInitialDccBlacklistBuildNumber != currentBuildNumber
        if !FileManager.default.fileExists(atPath: destinationFileUrl.path) || isNewAppVersion {
            try? FileManager.default.removeItem(at: destinationFileUrl)
            try? FileManager.default.copyItem(at: fileUrl, to: destinationFileUrl)
            lastInitialDccBlacklistBuildNumber = currentBuildNumber
        }
    }

}

extension DccBlacklistManager {

    func addObserver(_ observer: DccBlacklistChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(DccBlacklistObserverWrapper(observer: observer))
    }

    func removeObserver(_ observer: DccBlacklistChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }

    private func observerWrapper(for observer: DccBlacklistChangesObserver) -> DccBlacklistObserverWrapper? {
        observers.first { $0.observer === observer }
    }

    private func notifyObservers() {
        observers.forEach { $0.observer?.dccBlacklistDidUpdate() }
    }

}

extension DccBlacklistManager: URLSessionDelegate {

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning.validateChallenge(challenge, certificateFiles: Constant.Server.resourcesCertificates) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

}
