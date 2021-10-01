// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DccCertificatesManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 10/06/2021 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK

final class DccCertificatesManager {
    
    static let shared: DccCertificatesManager = DccCertificatesManager()
    
    var certs: [String: [String]] = [:]

    @UserDefault(key: .lastInitialCertsBuildNumber)
    private var lastInitialCertsBuildNumber: String? = nil

    func start() {
        writeInitialFileIfNeeded()
        loadLocalCertificates()
        addObserver()
    }

    func certificates(for kidStr: String) -> [String] { certs[kidStr] ?? [] }

    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        guard !RemoteFileConstant.useOnlyLocalStrings else { return }
        fetchCertificatesFile()
    }

}

// MARK: - All fetching methods -
extension DccCertificatesManager {

    private func fetchCertificatesFile(_ completion: (() -> ())? = nil) {
        let dataTask: URLSessionDataTask = UrlSessionManager.shared.session.dataTaskWithETag(with: Constant.Server.dccCertsUrl) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion?()
                }
                return
            }
            do {
                guard let certs = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String]] else {
                    DispatchQueue.main.async { completion?() }
                    return
                }
                self.certs = certs
                try data.write(to: self.localCertificatesUrl())
                DispatchQueue.main.async { completion?() }
            } catch {
                DispatchQueue.main.async { completion?() }
            }
        }
        dataTask.resume()
    }
    
}

// MARK: - Local files management -
extension DccCertificatesManager {

    private func localCertificatesUrl() -> URL {
        let directoryUrl: URL = self.createWorkingDirectoryIfNeeded()
        return directoryUrl.appendingPathComponent("dcc-certs.json")
    }

    private func loadLocalCertificates() {
        let localUrl: URL = localCertificatesUrl()
        guard FileManager.default.fileExists(atPath: localUrl.path) else { return }
        guard let data = try? Data(contentsOf: localUrl) else { return }
        certs = (try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String]]) ?? [:]
    }

    private func writeInitialFileIfNeeded() {
        let fileUrl: URL = Bundle.main.url(forResource: Constant.Server.dccCertsUrl.lastPathComponent, withExtension: nil)!
        let destinationFileUrl: URL = localCertificatesUrl()
        let currentBuildNumber: String = UIApplication.shared.buildNumber
        let isNewAppVersion: Bool = lastInitialCertsBuildNumber != currentBuildNumber
        if !FileManager.default.fileExists(atPath: destinationFileUrl.path) || RemoteFileConstant.useOnlyLocalStrings || isNewAppVersion {
            try? FileManager.default.removeItem(at: destinationFileUrl)
            try? FileManager.default.copyItem(at: fileUrl, to: destinationFileUrl)
            lastInitialCertsBuildNumber = currentBuildNumber
        }
    }

    private func createWorkingDirectoryIfNeeded() -> URL {
        let directoryUrl: URL = FileManager.libraryDirectory().appendingPathComponent("DccCertificates")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }

}
