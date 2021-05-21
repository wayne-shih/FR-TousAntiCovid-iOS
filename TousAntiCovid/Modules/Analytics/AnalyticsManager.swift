// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AnalyticsManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import Foundation
import RealmSwift
import ServerSDK
import RobertSDK

final class AnalyticsManager: NSObject {
    
    static let shared: AnalyticsManager = AnalyticsManager()
    
    @UserDefault(key: .installationUuid)
    private(set) var installationUuid: String = ""

    @UserDefault(key: .isAnalyticsOptIn)
    private(set) var isOptIn: Bool = true

    @UserDefault(key: .lastProximityActivationStartTimestamp)
    var lastProximityActivationStartTimestamp: Double?
    
    var canCountForegroundComeBack: Bool = true
    var appInfos: AnalyticsAppInfo? { getCurrentAppInfo() }
    var healthInfos: AnalyticsHealthInfo? { getCurrentHealthInfo() }
    var appEvents: [AnalyticsAppEvent] { getCurrentAppEvents() }
    var healthEvents: [AnalyticsHealthEvent] { getCurrentHealthEvents() }
    var errors: [AnalyticsError] { getCurrentErrors() }
    
    private typealias ProcessRequestCompletion = (_ result: Result<Data, Error>) -> ()
    private lazy var session: URLSession = {
        let backgroundConfiguration: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "fr.gouv.tousanticovid.ios.Analytics")
        return URLSession(configuration: backgroundConfiguration, delegate: self, delegateQueue: .main)
    }()
    private var receivedData: [String: Data] = [:]
    private var completions: [String: ProcessRequestCompletion] = [:]
    
    func start() {
        if installationUuid.isEmpty {
            installationUuid = UUID().uuidString
        }
        createInfoIfNeeded()
        initProximityStartTimestampIfNeeded()
    }

    func setOptIn(to isOptIn: Bool) {
        self.isOptIn = isOptIn
    }
    
    func sendAnalytics() {
        guard ParametersManager.shared.isAnalyticsOn && isOptIn && !Constant.isDebug else {
            resetAppEvents()
            resetHealthEvents()
            resetErrors()
            return
        }
        sendAppAnalytics { error in
            guard error == nil || (error as NSError?)?.code == 413 else { return }
            self.resetAppEvents()
            self.resetErrors()
        }
        let delay: Double = Double((500...2000).randomElement() ?? 500) / 1000.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.sendHealthAnalytics { error in
                guard error == nil || (error as NSError?)?.code == 413 else { return }
                self.resetHealthEvents()
            }
        }
    }
    
    func reset() {
        resetInfo()
        resetAppEvents()
        resetHealthEvents()
        resetErrors()
        installationUuid = UUID().uuidString
        isOptIn = true
        clearProximityStartTimestamp()
    }
    
    private func generateAppFullJson() -> JSON {
        ["installationUuid": installationUuid,
         "infos": appInfos?.toJson() ?? [:],
         "events": appEvents.compactMap { $0.toJson() },
         "errors": errors.compactMap { $0.toJson() }]
    }
    
    private func generateHealthFullJson() -> JSON {
        ["installationUuid": UUID().uuidString,
         "infos": healthInfos?.toJson() ?? [:],
         "events": healthEvents.compactMap { $0.toJson() },
         "errors": errors.compactMap { $0.toJson() }]
    }
    
    private func generateAppFullJsonString() -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: generateAppFullJson(), options: [.prettyPrinted, .sortedKeys]) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    private func generateHealthFullJsonString() -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: generateHealthFullJson(), options: [.prettyPrinted, .sortedKeys]) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

}

extension AnalyticsManager {
    
    private func sendAppAnalytics(_ completion: @escaping (_ error: Error?) -> ()) {
        updateAppInfo()
        processRequest(url: Constant.Server.analyticsBaseUrl.appendingPathComponent("analytics"), body: self.generateAppFullJson()) { result in
            switch result {
            case .success:
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        }
    }

    private func sendHealthAnalytics(_ completion: @escaping (_ error: Error?) -> ()) {
        updateHealthInfo()
        processRequest(url: Constant.Server.analyticsBaseUrl.appendingPathComponent("analytics"), body: self.generateHealthFullJson()) { result in
            switch result {
            case .success:
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        }
    }

}

extension AnalyticsManager {

    private func processRequest(url: URL, body: JSON, completion: @escaping (_ result: Result<Data, Error>) -> ()) {
        do {
            let bodyData: Data = try JSONSerialization.data(withJSONObject: body, options: [])
            let requestId: String = UUID().uuidString
            completions[requestId] = completion
            var request: URLRequest = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-type")
            if let token = RBManager.shared.analyticsToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            request.httpBody = bodyData
            let task: URLSessionDataTask = session.dataTask(with: request)
            task.taskDescription = requestId
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }

}

extension AnalyticsManager: URLSessionDelegate, URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let requestId: String = dataTask.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        DispatchQueue.main.async {
            if dataTask.response?.isError == true {
                let statusCode: Int = dataTask.response?.responseStatusCode ?? 0
                let message: String? = data.isEmpty ? "No logs received from the server" : String(data: data, encoding: .utf8)
                let error: Error = NSError.localizedError(message: "Uknown error (\(statusCode)). (\(message ?? "N/A"))", code: statusCode)
                completion(.failure(error))
                self.completions[requestId] = nil
            } else {
                var receivedData: Data = self.receivedData[requestId] ?? Data()
                receivedData.append(data)
                self.receivedData[requestId] = receivedData
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let requestId: String = task.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        DispatchQueue.main.async {
            if let error = error {
                completion(.failure(error))
            } else {
                let receivedData: Data = self.receivedData[requestId] ?? Data()
                if task.response?.isError == true {
                    let statusCode: Int = task.response?.responseStatusCode ?? 0
                    let message: String = receivedData.isEmpty ? "No data received from the server" : (String(data: receivedData, encoding: .utf8) ?? "Unknown error")
                    let error: Error = NSError.localizedError(message: "Uknown error (\(statusCode)). (\(message))", code: statusCode)
                    completion(.failure(error))
                } else {
                    completion(.success(receivedData))
                }
            }
            self.completions[requestId] = nil
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning.validateChallenge(challenge, certificateFile: Constant.Server.analyticsCertificate) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
}

extension Realm {

    static func analyticsDb() throws -> Realm {
        return try Realm(configuration: analyticsConfiguration())
    }

    static private func dbsDirectoryUrl() -> URL {
        var directoryUrl: URL = FileManager.libraryDirectory().appendingPathComponent("DBs")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
            try? directoryUrl.addSkipBackupAttribute()
        }
        return directoryUrl
    }

    static private func analyticsConfiguration() -> Realm.Configuration {
        let classes: [Object.Type] = [AnalyticsAppInfo.self,
                                      AnalyticsHealthInfo.self,
                                      AnalyticsError.self,
                                      AnalyticsAppEvent.self,
                                      AnalyticsHealthEvent.self]
        let databaseUrl: URL = dbsDirectoryUrl().appendingPathComponent("analytics.realm")
        let userConfig: Realm.Configuration = Realm.Configuration(fileURL: databaseUrl, schemaVersion: 13, migrationBlock: { _, _ in }, objectTypes: classes)
        return userConfig
    }

}
