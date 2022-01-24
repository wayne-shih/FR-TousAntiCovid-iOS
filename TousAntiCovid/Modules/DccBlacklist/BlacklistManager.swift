// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  BlacklistManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/10/2021 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK
import StorageSDK

protocol BlacklistManager: AnyObject {

    var storageManager: StorageManager? { get set }
    var lastBlacklistVersionNumber: Int { get set }
    var baseUrl: String { get }
    var filename: String { get }
    
    func isBlacklisted(certificate: WalletCertificate) -> Bool
    func updateBlacklist(addedOrUpdated: [String], removed: [String])
    func start(storageManager: StorageManager)
}

// MARK: - Notifications management
extension BlacklistManager {
    func addNotifications() {
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.appDidBecomeActive()
        }
    }
    
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}

private extension BlacklistManager {
    var certListUrl: URL { URL(string: "\(baseUrl)/\(lastBlacklistVersionNumber)/\(filename)")! }

    func appDidBecomeActive() {
        fetchAllCertList()
    }
    
    func updateBlacklistVersion() {
        lastBlacklistVersionNumber += 1
    }
}

// MARK: - All fetching methods
private extension BlacklistManager {
    func fetchAllCertList() {
        fetchCertList { [weak self] success in
            if success {
                self?.fetchAllCertList()
            }
        }
    }

    func fetchCertList(completion: ((_ success: Bool) -> ())?) {
        let dataTask: URLSessionDataTask = URLSessionDataTaskFactory.shared.dataTask(with: URLRequest(url: certListUrl),
                                                                                     session: UrlSessionManager.shared.session) { [weak self] data, response, error in
            guard response?.responseStatusCode == 200 else {
                completion?(false)
                return
            }
            guard let data = data else {
                completion?(false)
                return
            }
            self?.backgroundManagement(data: data) {
                completion?($0)
            }
        }
        dataTask.resume()
    }
    
    func backgroundManagement(data: Data, completion: @escaping (_ success: Bool) -> ()) {
        DispatchQueue.global().async { [weak self] in
            guard let uncompressedData: Data = try? data.gunzipped() else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            guard let blacklistMessage: Blacklist_BlackListMessage = try? .init(serializedData: uncompressedData) else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            let result: (added: [String], removed: [String]) = blacklistMessage.split()
            let removed: [String] = result.removed.map { String($0.dropFirst()) }.filterValidHashes()
            let added: [String] = result.added.filterValidHashes()
            self?.updateBlacklist(addedOrUpdated: added, removed: removed)
            self?.updateBlacklistVersion()
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
}
