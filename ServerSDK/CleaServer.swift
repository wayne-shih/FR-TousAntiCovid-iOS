// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CleaServer.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/11/2020 - for the TousAntiCovid project.
//

import Foundation
import RobertSDK

public final class CleaServer: NSObject {
    
    public static let shared: CleaServer = CleaServer()
    
    private var reportBaseUrl: (() -> URL?)!
    private var statusBaseUrl: (() -> URL?)!

    private lazy var session: URLSession = {
        let backgroundConfiguration: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "fr.gouv.stopcovid.ios.ServerSDK-Warning")
        backgroundConfiguration.waitsForConnectivity = true
        backgroundConfiguration.sessionSendsLaunchEvents = true
        backgroundConfiguration.shouldUseExtendedBackgroundIdleMode = true
        return URLSession(configuration: backgroundConfiguration, delegate: self, delegateQueue: .main)
    }()
    private var receivedData: [String: Data] = [:]
    private var completions: [String: Server.ProcessRequestCompletion] = [:]
    private var requestLoggingHandler: Server.RequestLoggingHandler?
    
    private var pivotDate: Int {
        let pivotDate: Int
        if let reportSymptomsStartDate = RBManager.shared.reportSymptomsStartDate {
            let preSymptomSpan: Int = RBManager.shared.preSymptomsSpan
            pivotDate = reportSymptomsStartDate.svDateByAddingDays(-preSymptomSpan).timeIntervalSince1900
        } else if let reportPositiveTestDate = RBManager.shared.reportPositiveTestDate {
            let positiveSampleSpan: Int = RBManager.shared.positiveSampleSpan
            pivotDate = reportPositiveTestDate.svDateByAddingDays(-positiveSampleSpan).timeIntervalSince1900
        } else {
            let venuesRetentionPeriod: Int = ParametersManager.shared.venuesRetentionPeriod
            pivotDate = Date().svDateByAddingDays(-venuesRetentionPeriod).timeIntervalSince1900
        }
        return pivotDate
    }
    
    public func start(reportBaseUrl: @escaping () -> URL?, statusBaseUrl: @escaping () -> URL?, requestLoggingHandler: @escaping Server.RequestLoggingHandler) {
        self.reportBaseUrl = reportBaseUrl
        self.statusBaseUrl = statusBaseUrl
        self.requestLoggingHandler = requestLoggingHandler
    }

    public func report(token: String, visits: [CleaServerVisit], completion: @escaping (_ error: Error?) -> ()) {
        guard let baseUrl = self.reportBaseUrl() else {
            completion(nil)
            return
        }
        let visits: [RBCleaServerVisit] = visits.map { RBCleaServerVisit.from(visit: $0) }
        let body: RBCleaServerReportBody = RBCleaServerReportBody(pivotDate: pivotDate, visits: visits)
        self.processRequest(url: baseUrl.appendingPathComponent("wreport"), method: .post, token: token, body: body) { result in
            switch result {
            case .success:
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        }
    }

    public func getClusterIndex(completion: @escaping (_ result: Result<CleaServerStatusClusterIndex?, Error>) -> ()) {
        guard let baseUrl = self.statusBaseUrl() else {
            completion(.success(nil))
            return
        }
        self.processRequest(url: baseUrl.appendingPathComponent("clusterIndex.json"), method: .get, body: nil) { result in
            switch result {
            case let .success(data):
                do {
                    let response: RBCleaServerStatusClusterIndex = try JSONDecoder().decode(RBCleaServerStatusClusterIndex.self, from: data)
                    let clusterIndex: CleaServerStatusClusterIndex = CleaServerStatusClusterIndex.from(clusterIndex: response)
                    completion(.success(clusterIndex))
                } catch {
                    completion(.failure(error))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func getAllCleaClusters(for clusterPrefixes: [String], iteration: Int, completion: @escaping (_ result: Result<[CleaServerStatusCluster], Error>) -> ()) {
        let dispatchGroup: DispatchGroup = DispatchGroup()
        var clusters: [RBCleaServerStatusCluster] = []
        var clusterErrors: [Error] = []
        clusterPrefixes.forEach { clusterPrefix in
            dispatchGroup.enter()
            getClusters(iteration: iteration, clusterPrefix: clusterPrefix) { result in
                switch result {
                case let .success(cluster):
                    clusters.append(contentsOf: cluster ?? [])
                case let .failure(error):
                    clusterErrors.append(error)
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            if clusters.isEmpty, let error = clusterErrors.first {
                completion(.failure(error))
            } else {
                let response: [CleaServerStatusCluster] = clusters.map { CleaServerStatusCluster.from(cluster: $0) }
                completion(.success(response))
            }
        }
    }

    private func getClusters(iteration: Int, clusterPrefix: String, completion: @escaping (_ result: Result<[RBCleaServerStatusCluster]?, Error>) -> ()) {
        guard let baseUrl = self.statusBaseUrl() else {
            completion(.success(nil))
            return
        }
        self.processRequest(url: baseUrl.appendingPathComponent("\(iteration)/\(clusterPrefix).json"), method: .get, body: nil) { result in
            switch result {
            case let .success(data):
                do {
                    let response: [RBCleaServerStatusCluster] = try JSONDecoder().decode([RBCleaServerStatusCluster].self, from: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(error))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

extension CleaServer {
    
    private func processRequest(url: URL, method: Server.Method, token: String? = nil, body: RBServerBody?, completion: @escaping (_ result: Result<Data, Error>) -> ()) {
        do {
            let bodyData: Data? = try body?.toData()
            let requestId: String = url.lastPathComponent
            guard completions[requestId] == nil else {
                let error: Error = NSError.svLocalizedError(message: "A request for \"\(requestId)\" is already being treated", code: 0)
                self.requestLoggingHandler?(nil, nil, error)
                completion(.failure(error))
                return
            }
            completions[requestId] = completion
            var request: URLRequest = URLRequest(url: url)
            request.httpMethod = method.rawValue
            if let token = token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            request.setValue("application/json", forHTTPHeaderField: "Content-type")
            request.httpBody = bodyData
            let task: URLSessionDownloadTask = session.downloadTask(with: request)
            task.taskDescription = requestId
            task.resume()
        } catch {
            self.requestLoggingHandler?(nil, nil, error)
            completion(.failure(error))
        }
    }
    
}

extension CleaServer: URLSessionDelegate, URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let requestId: String = task.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        completions[requestId] = nil
        DispatchQueue.main.async {
            if let error = error {
                self.requestLoggingHandler?(task, nil, error)
                completion(.failure(error))
            } else {
                let receivedData: Data = self.receivedData[requestId] ?? Data()
                if task.response?.svIsError == true {
                    let statusCode: Int = task.response?.svStatusCode ?? 0
                    let message: String = receivedData.isEmpty ? "No data received from the server" : (String(data: receivedData, encoding: .utf8) ?? "Unknown error")
                    let error: Error = NSError.svLocalizedError(message: "Uknown error (\(statusCode)). (\(message))", code: statusCode)
                    self.requestLoggingHandler?(task, nil, error)
                    completion(.failure(error))
                } else {
                    self.requestLoggingHandler?(task, receivedData, nil)
                    completion(.success(receivedData))
                }
            }
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let requestId: String = downloadTask.taskDescription ?? ""
        guard completions[requestId] != nil else { return }
        guard let data = try? Data(contentsOf: location) else { return }
        try? FileManager.default.removeItem(at: location)
        receivedData[requestId] = data
    }
    
}
