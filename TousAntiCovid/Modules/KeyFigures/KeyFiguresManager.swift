// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFiguresManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK

protocol KeyFiguresChangesObserver: class {
    
    func keyFiguresDidUpdate()
    
}

final class KeyFiguresObserverWrapper: NSObject {
    
    weak var observer: KeyFiguresChangesObserver?
    
    init(observer: KeyFiguresChangesObserver) {
        self.observer = observer
    }
    
}

final class KeyFiguresManager: NSObject {
    
    static let shared: KeyFiguresManager = KeyFiguresManager()
    
    var keyFigures: [KeyFigure] = []
    var featuredKeyFigures: [KeyFigure] { [KeyFigure](keyFigures.filter { $0.isFeatured }.prefix(3)) }
    
    @UserDefault(key: .isOnboardingDone)
    private var isOnboardingDone: Bool = false
    
    private var observers: [KeyFiguresObserverWrapper] = []
    
    func start() {
        loadLocalKeyFigures()
        addObserver()
    }
    
    func fetchKeyFigures() {
        fetchAllFiles()
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        fetchAllFiles()
    }
    
}

// MARK: - All fetching methods -
extension KeyFiguresManager {
    
    private func fetchAllFiles() {
        fetchKeyFiguresFile {
            DispatchQueue.main.async {
                self.notifyObservers()
            }
        }
    }
    
    private func fetchKeyFiguresFile(_ completion: @escaping () -> ()) {
        let session: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let dataTask: URLSessionDataTask = session.dataTask(with: KeyFiguresConstant.jsonUrl) { data, response, error in
            guard let data = data else { return }
            do {
                self.keyFigures = try JSONDecoder().decode([KeyFigure].self, from: data)
                try data.write(to: self.localKeyFiguresUrl())
                DispatchQueue.main.async {
                    completion()
                }
            } catch {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
        dataTask.resume()
    }
    
}

// MARK: - Local files management -
extension KeyFiguresManager {
    
    private func localKeyFiguresUrl() -> URL {
        let directoryUrl: URL = self.createWorkingDirectoryIfNeeded()
        return directoryUrl.appendingPathComponent("keyFigures.json")
    }
    
    private func loadLocalKeyFigures() {
        let localUrl: URL = localKeyFiguresUrl()
        guard FileManager.default.fileExists(atPath: localUrl.path) else { return }
        guard let data = try? Data(contentsOf: localUrl) else { return }
        keyFigures = (try? JSONDecoder().decode([KeyFigure].self, from: data)) ?? []
    }
    
    private func createWorkingDirectoryIfNeeded() -> URL {
        let directoryUrl: URL = FileManager.libraryDirectory().appendingPathComponent("KeyFigures")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }
    
}

extension KeyFiguresManager {
    
    func addObserver(_ observer: KeyFiguresChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(KeyFiguresObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: KeyFiguresChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: KeyFiguresChangesObserver) -> KeyFiguresObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
    private func notifyObservers() {
        observers.forEach { $0.observer?.keyFiguresDidUpdate() }
    }
    
}

extension KeyFiguresManager: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning.validateChallenge(challenge, certificateFile: Constant.Server.resourcesCertificate) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
     
}