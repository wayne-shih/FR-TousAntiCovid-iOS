// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletImagesManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/05/2021 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK

final class WalletImagesManager: NSObject {
    
    enum ImageName: String, CaseIterable {
        case testCertificate = "test-certificate"
        case testCertificateFull = "test-certificate-full"
        case vaccinCertificate = "vaccin-certificate"
        case vaccinCertificateFull = "vaccin-certificate-full"
        case vaccinEuropeCertificate = "vaccin-europe-certificate"
        case vaccinEuropeCertificateFull = "vaccin-europe-certificate-full"
        case testEuropeCertificate = "test-europe-certificate"
        case testEuropeCertificateFull = "test-europe-certificate-full"
        case recoveryEuropeCertificate = "recovery-europe-certificate"
        case recoveryEuropeCertificateFull = "recovery-europe-certificate-full"
    }
    
    static let shared: WalletImagesManager = WalletImagesManager()
    
    @UserDefault(key: .lastMultipleRemoteFilesLanguageCode)
    private var lastLanguageCode: String? = nil {
        didSet {
            guard oldValue != lastLanguageCode else {
                return
            }
            ETagManager.shared.clearAllData()
        }
    }
    private var fileNames: [String] = ImageName.allCases.map { $0.rawValue }
    private var images: [String: UIImage] = [:]
    
    @UserDefault(key: .lastInitialWalletImagesBuildNumber)
    private var lastInitialWalletImagesBuildNumber: String? = nil
    
    @UserDefault(key: .lastWalletImagesUpdateDate)
    private var lastUpdateDate: Date = .distantPast
    
    
    func start() {
        writeInitialFilesIfNeeded()
        loadLocalFiles()
        addObserver()
    }
    
    func image(named: ImageName) -> UIImage? { images[named.rawValue] }
    
    private func workingDirectoryName() -> String { "WalletImages" }
    private func initialFileUrl(fileName: String) -> URL? { Bundle.main.url(forResource: fileName, withExtension: nil) }
    
    @discardableResult
    private func processReceivedData(_ data: Data, fileName: String) -> Bool {
        guard let image = UIImage(data: data) else { return false }
        images[fileName] = image
        return true
    }
    
    private func createWorkingDirectoryIfNeeded() -> URL {
        let directoryUrl: URL = FileManager.libraryDirectory().appendingPathComponent(workingDirectoryName())
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }
    
    private func canUpdateData() -> Bool {
        Date().timeIntervalSince1970 - lastUpdateDate.timeIntervalSince1970 >= WalletImagesConstant.minDurationBetweenUpdatesInSeconds
    }
    private func saveUpdatedAt() { self.lastUpdateDate = Date() }
    private func saveLastBuildNumber(_ buildNumber: String) { lastInitialWalletImagesBuildNumber = buildNumber }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        guard !RemoteFileConstant.useOnlyLocalStrings && canUpdateData() else { return }
        fetchLastFiles()
    }
    
    private func fetchLastFiles() {
        fileNames.forEach { fetchLastFile(with: $0, languageCode: Locale.currentAppLanguageCode) }
    }

    private func fetchLastFile(with name: String, languageCode: String) {
        let fileName: String = self.fileName(baseName: name, languageCode: languageCode)
        let url: URL = WalletImagesConstant.baseUrl.appendingPathComponent(fileName)
        let sesssion: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let dataTask: URLSessionDataTask = sesssion.dataTaskWithETag(with: url) { data, response, error in
            guard let data = data else {
                return
            }
            do {
                let localFileName: String = self.fileName(baseName: name, languageCode: languageCode)
                let localUrl: URL = self.createWorkingDirectoryIfNeeded().appendingPathComponent(localFileName)
                if self.processReceivedData(data, fileName: name) {
                    try data.write(to: localUrl)
                    self.saveUpdatedAt()
                } else {
                    self.loadLocalFile(with: name)
                }
                self.lastLanguageCode = Locale.currentAppLanguageCode
            } catch {}
        }
        dataTask.resume()
    }
    
    private func loadLocalFiles() { fileNames.forEach { loadLocalFile(with: $0) } }
    
    private func loadLocalFile(with name: String) {
        var fileName: String = self.fileName(baseName: name, languageCode: Locale.currentAppLanguageCode)
        var localUrl: URL = createWorkingDirectoryIfNeeded().appendingPathComponent(fileName)
        if !FileManager.default.fileExists(atPath: localUrl.path) {
            fileName = self.fileName(baseName: name, languageCode: Constant.defaultLanguageCode)
            localUrl = createWorkingDirectoryIfNeeded().appendingPathComponent(fileName)
        }
        guard let data = try? Data(contentsOf: localUrl) else { return }
        processReceivedData(data, fileName: name)
    }
    
    private func writeInitialFilesIfNeeded() {
        fileNames.forEach {
            let fileName: String = self.fileName(baseName: $0, languageCode: Locale.currentAppLanguageCode)
            writeInitialFileIfNeeded(fileUrl: initialFileUrl(fileName: fileName) ?? Bundle.main.url(forResource: "\($0)-\(Constant.defaultLanguageCode)", withExtension: "png")!)
        }
    }
    
    private func writeInitialFileIfNeeded(fileUrl: URL) {
        let destinationFileUrl: URL = createWorkingDirectoryIfNeeded().appendingPathComponent(fileUrl.lastPathComponent)
        let currentBuildNumber: String = UIApplication.shared.buildNumber
        let isNewAppVersion: Bool = lastInitialWalletImagesBuildNumber != currentBuildNumber
        if !FileManager.default.fileExists(atPath: destinationFileUrl.path) || RemoteFileConstant.useOnlyLocalStrings || isNewAppVersion {
            try? FileManager.default.removeItem(at: destinationFileUrl)
            try? FileManager.default.copyItem(at: fileUrl, to: destinationFileUrl)
            saveLastBuildNumber(currentBuildNumber)
        }
    }
    
    private func fileName(baseName: String, languageCode: String) -> String { "\(baseName)-\(languageCode).png" }
    
}

extension WalletImagesManager: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning.validateChallenge(challenge, certificateFile: Constant.Server.resourcesCertificate) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
}
