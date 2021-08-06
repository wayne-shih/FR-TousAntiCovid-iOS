// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit
import RobertSDK
import StorageSDK
import ServerSDK

protocol VenuesChangesObserver: AnyObject {
    
    func venuesDidUpdate()
    
}

final class VenuesObserverWrapper: NSObject {
    
    weak var observer: VenuesChangesObserver?
    
    init(observer: VenuesChangesObserver) {
        self.observer = observer
    }
    
}

final class VenuesManager: NSObject {
    
    static let shared: VenuesManager = VenuesManager()
    
    var isVenuesRecordingActivated: Bool { ParametersManager.shared.displayRecordVenues }
    
    var venuesQrCodes: [VenueQrCodeInfo] { storageManager?.venuesQrCodes() ?? [] }

    #if !PROD
    @UserDefault(key: .isVenuesTestActivated)
    var isVenuesTestActivated: Bool = false { didSet { NotificationCenter.default.post(name: .statusDataDidChange, object: nil) } }
    #endif

    @UserDefault(key: .cleaLastIteration)
    private var cleaLastIteration: Int?
    
    private var storageManager: StorageManager!
    private var observers: [VenuesObserverWrapper] = []
    private var didAlreadyRetryReport: Bool = false
    
    @UserDefault(key: .didAlreadySeeVenuesRecordingOnboarding)
    private var didAlreadySeeOnboarding: Bool = false
    
    @UserDefault(key: .venuesFeaturedWasActivatedAtLeastOneTime)
    private var venuesFeaturedWasActivatedAtLeastOneTime: Bool = false

    func start(storageManager: StorageManager) {
        self.storageManager = storageManager
        addObserver()
    }
    
    func clearAllData() {
        storageManager.deleteVenuesQrCodeData()
        didAlreadySeeOnboarding = false
        venuesFeaturedWasActivatedAtLeastOneTime = false
    }
    
    func deleteVenueQrCodeInfo(_ venueQrCodeInfo: VenueQrCodeInfo) {
        storageManager.deleteVenueQrCodeInfo(venueQrCodeInfo)
    }
    
    func clearExpiredData() {
        storageManager.deleteExpiredVenuesQrCodeData(durationInSeconds: Double(ParametersManager.shared.venuesRetentionPeriod) * 24.0 * 3600.0)
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(venuesStorageDidUpdate), name: .venueQrCodeDataDidChange, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        clearExpiredData()
        retryReportIfNeeded()
    }
    
    @objc private func venuesStorageDidUpdate() {
        notifyObservers()
    }

}

extension VenuesManager {
    
    func addObserver(_ observer: VenuesChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(VenuesObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: VenuesChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: VenuesChangesObserver) -> VenuesObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
    private func notifyObservers() {
        observers.forEach { $0.observer?.venuesDidUpdate() }
    }
    
}

// MARK: - Deeplinking -
extension VenuesManager {

    func isVenueUrlValid(_ url: URL) -> Bool { parseUrlComponents(url) != nil }
    
    func isVenueUrlExpired(_ url: URL) -> Bool {
        guard let timestamp = parseUrlComponents(url)?.timestamp else { return false }
        let validityDuration: Double = Double(ParametersManager.shared.venuesRetentionPeriod) * 24.0 * 3600.0
        return Date().timeIntervalSince1970 - timestamp >= validityDuration
    }
    
    @discardableResult
    func processVenueUrl(_ url: URL) -> VenueQrCodeInfo? {
        guard let venueQrCodeInfo = getVenueQrCodeInfo(from: url) else { return nil }
        storageManager.saveVenueQrCodeInfo(venueQrCodeInfo)
        cleaLastIteration = nil
        AnalyticsManager.shared.reportAppEvent(.e14)
        return venueQrCodeInfo
    }
    
    private func getVenueQrCodeInfo(from url: URL) -> VenueQrCodeInfo? {
        guard let urlComponents = parseUrlComponents(url) else { return nil }
        guard let ltid = extractTlIdFromBase64Url(code: urlComponents.code) else { return nil }
        guard ltid.isUuidCode else { return nil }
        
        let ntpTimestamp: Int
        if let timestamp = urlComponents.timestamp {
            ntpTimestamp = Date(timeIntervalSince1970: timestamp).timeIntervalSince1900
        } else {
            ntpTimestamp = Date().timeIntervalSince1900
        }
        
        let id: String = "\(ltid)\(ntpTimestamp)"
        return VenueQrCodeInfo(id: id,
                           ltid: ltid,
                           ntpTimestamp: ntpTimestamp,
                           base64: urlComponents.code,
                           version: urlComponents.version)
    }
    
    private func parseUrlComponents(_ url: URL) -> (code: String, version: Int, timestamp: Double?)? {
        guard url.host == "tac.gouv.fr" else { return nil }
        
        guard let cleanVenueUrl = URL(string: cleanVenueUrlString(stringUrl: String(url.absoluteString))) else { return nil }
        
        // Values
        guard let code = extractParamFrom(url: cleanVenueUrl, param: "code") else { return nil }
        guard let version = Int(extractParamFrom(url: cleanVenueUrl, param: "v") ?? "") else { return nil }
        let timestamp: Double? = Double(extractParamFrom(url: cleanVenueUrl, param: "t") ?? "")
        
        return (code, version, timestamp)
    }
    
    private func cleanVenueUrlString(stringUrl: String) -> String {
        let cleanStringUrl: String = stringUrl.replacingOccurrences(of: "#", with: "&code=")
        return cleanStringUrl.removingPercentEncoding ?? cleanStringUrl
    }
    
    private func extractParamFrom(url: URL, param: String) -> String? {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        return urlComponents.queryItems?.first(where: { $0.name == param })?.value
    }
    
    func extractTlIdFromBase64Url(code: String) -> String? {
        guard let data = Data(base64Encoded: code.base64urlToBase64()) else { return nil }
        var byteArray: [UInt8] = [UInt8](repeating: 0, count: 16)
        guard data.count > 16 else { return nil }
        data.copyBytes(to: &byteArray, from: Range(NSRange(location: 1, length: 16))!)
        return NSUUID(uuidBytes: byteArray).uuidString.lowercased()
    }
}

// MARK: - Server requests -
extension VenuesManager {

    func report(_ completion: ((_ error: Error?) -> ())? = nil) {
        guard let token = RBManager.shared.reportToken else {
            completion?(nil)
            return
        }
        guard !venuesQrCodes.isEmpty else {
            completion?(nil)
            return
        }
        CleaServer.shared.report(token: token, visits: venuesQrCodes.map { $0.toCleaServerVisit() }) { error in
            if let error = error {
                AnalyticsManager.shared.reportError(serviceName: "wreport", apiVersion: ParametersManager.shared.cleaReportApiVersion, code: (error as NSError).code)
                guard (error as NSError).code != 403 else {
                    self.didAlreadyRetryReport = false
                    self.storageManager.deleteVenuesQrCodeData()
                    RBManager.shared.reportToken = nil
                    completion?(error)
                    return
                }
                if self.didAlreadyRetryReport {
                    self.didAlreadyRetryReport = false
                    completion?(error)
                } else {
                    self.didAlreadyRetryReport = true
                    self.report(completion)
                }
            } else {
                self.didAlreadyRetryReport = false
                self.storageManager.deleteVenuesQrCodeData()
                RBManager.shared.reportToken = nil
                completion?(nil)
            }
        }
    }

    private func retryReportIfNeeded() {
        guard RBManager.shared.reportToken != nil else {
            if RBManager.shared.isImmune, !venuesQrCodes.isEmpty {
                storageManager.deleteVenuesQrCodeData()
            }
            return
        }
        guard !venuesQrCodes.isEmpty else {
            RBManager.shared.reportToken = nil
            return
        }
        report()
    }

}
