// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Server.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/04/2020 - for the TousAntiCovid project.
//

import Foundation
import RobertSDK

public final class Server: NSObject, RBServer {
    
    enum Method: String {
        case get = "GET"
        case post = "POST"
    }
    
    public typealias RequestLoggingHandler = (_ task: URLSessionTask?, _ responseData: Data?, _ error: Error?) -> ()
    typealias ProcessRequestCompletion = (_ result: Result<Data, Error>) -> ()
    
    public let publicKey: Data
    private let baseUrl: () -> URL
    private let certificateFile: Data
    private let deviceTimeNotAlignedToServerTimeDetected: () -> ()
    
    private lazy var session: URLSession = {
        let backgroundConfiguration: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "fr.gouv.stopcovid.ios.ServerSDK")
        backgroundConfiguration.timeoutIntervalForRequest = ServerConstant.timeout
        backgroundConfiguration.timeoutIntervalForResource = ServerConstant.timeout
        backgroundConfiguration.waitsForConnectivity = true
        backgroundConfiguration.sessionSendsLaunchEvents = true
        backgroundConfiguration.shouldUseExtendedBackgroundIdleMode = true
        return URLSession(configuration: backgroundConfiguration, delegate: self, delegateQueue: .main)
    }()
    private var receivedData: [String: Data] = [:]
    private var completions: [String: ProcessRequestCompletion] = [:]
    private let requestLoggingHandler: RequestLoggingHandler
    
    public init(baseUrl: @escaping () -> URL, publicKey: Data, certificateFile: Data, configUrl: URL, configCertificateFile: Data, deviceTimeNotAlignedToServerTimeDetected: @escaping () -> (), requestLoggingHandler: @escaping RequestLoggingHandler) {
        self.baseUrl = baseUrl
        self.publicKey = publicKey
        self.certificateFile = certificateFile
        self.deviceTimeNotAlignedToServerTimeDetected = deviceTimeNotAlignedToServerTimeDetected
        self.requestLoggingHandler = requestLoggingHandler
        ParametersManager.shared.url = configUrl
        ParametersManager.shared.certificateFile = configCertificateFile
    }
    
    public func register(captcha: String, captchaId: String, publicKey: String, completion: @escaping (_ result: Result<RBRegisterResponse, Error>) -> ()) {
        ParametersManager.shared.fetchConfig { configResult in
            switch configResult {
            case let .success(serverTime):
                let nowTimeStamp: Double = Date().timeIntervalSince1970
                if abs(nowTimeStamp - serverTime) > ServerConstant.maxClockShiftToleranceInSeconds {
                    self.deviceTimeNotAlignedToServerTimeDetected()
                    completion(.failure(NSError.deviceTime))
                } else {
                    self.processRegister(captcha: captcha, captchaId: captchaId, publicKey: publicKey, completion: completion)
                }
            case let .failure(error):
                print(error)
                self.processRegister(captcha: captcha, captchaId: captchaId, publicKey: publicKey, completion: completion)
            }
        }
    }
    
    public func status(epochId: Int, ebid: String, time: String, mac: String, completion: @escaping (_ result: Result<RBStatusResponse, Error>) -> ()) {
        ParametersManager.shared.fetchConfig { configResult in
            switch configResult {
            case let .success(serverTime):
                let nowTimeStamp: Double = Date().timeIntervalSince1970
                if abs(nowTimeStamp - serverTime) > ServerConstant.maxClockShiftToleranceInSeconds {
                    self.deviceTimeNotAlignedToServerTimeDetected()
                    completion(.failure(NSError.deviceTime))
                } else {
                    let body: RBServerStatusBody = RBServerStatusBody(epochId: epochId,
                                                                      ebid: ebid,
                                                                      time: time,
                                                                      mac: mac,
                                                                      pushInfo: RBServerPushInfo(token: RBManager.shared.pushToken ?? "",
                                                                                                 locale: Locale.current.identifier,
                                                                                                 timezone: TimeZone.current.identifier))
                    self.processRequest(url: self.baseUrl().appendingPathComponent("status"), method: .post, body: body) { result in
                        switch result {
                        case let .success(data):
                            do {
                                let response: RBServerStatusResponse = try JSONDecoder().decode(RBServerStatusResponse.self, from: data)
                                let transformedResponse: RBStatusResponse = RBStatusResponse(riskLevel: response.riskLevel,
                                                                                             lastContactDate: response.lastContactDate,
                                                                                             lastRiskScoringDate: response.lastRiskScoringDate,
                                                                                             message: response.message,
                                                                                             tuples: response.tuples,
                                                                                             declarationToken: response.declarationToken,
                                                                                             analyticsToken: response.analyticsToken)
                                completion(.success(transformedResponse))
                            } catch {
                                completion(.failure(error))
                            }
                        case let .failure(error):
                            completion(.failure(error))
                        }
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    public func report(code: String, helloMessages: [RBLocalProximity], completion: @escaping (_ result: Result<String, Error>) -> ()) {
        ParametersManager.shared.fetchConfig { configResult in
            switch configResult {
            case let .success(serverTime):
                let nowTimeStamp: Double = Date().timeIntervalSince1970
                if abs(nowTimeStamp - serverTime) > ServerConstant.maxClockShiftToleranceInSeconds {
                    self.deviceTimeNotAlignedToServerTimeDetected()
                    completion(.failure(NSError.deviceTime))
                } else {
                    let contacts: [RBServerContact] = self.prepareContactsReport(from: helloMessages)
                    let body: RBServerReportBody = RBServerReportBody(token: code, contacts: contacts)
                    self.processRequest(url: self.baseUrl().appendingPathComponent("report"), method: .post, body: body) { result in
                        switch result {
                        case let .success(data):
                            do {
                                if data.isEmpty {
                                    completion(.failure(NSError.svLocalizedError(message: "Empty data received", code: 0)))
                                } else {
                                    let response: RBServerReportResponse = try JSONDecoder().decode(RBServerReportResponse.self, from: data)
                                    if response.success != false {
                                        completion(.success(response.reportValidationToken))
                                    } else {
                                        completion(.failure(NSError.svLocalizedError(message: response.message ?? "An unknown error occurred", code: 0)))
                                    }
                                }
                            } catch {
                                completion(.failure(error))
                            }
                        case let .failure(error):
                            completion(.failure(error))
                        }
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    public func deleteExposureHistory(epochId: Int, ebid: String, time: String, mac: String, completion: @escaping (_ error: Error?) -> ()) {
        ParametersManager.shared.fetchConfig { configResult in
            switch configResult {
            case let .success(serverTime):
                let nowTimeStamp: Double = Date().timeIntervalSince1970
                if abs(nowTimeStamp - serverTime) > ServerConstant.maxClockShiftToleranceInSeconds {
                    self.deviceTimeNotAlignedToServerTimeDetected()
                    completion(NSError.deviceTime)
                } else {
                    let body: RBServerDeleteExposureBody = RBServerDeleteExposureBody(epochId: epochId, ebid: ebid, time: time, mac: mac)
                    self.processRequest(url: self.baseUrl().appendingPathComponent("deleteExposureHistory"), method: .post, body: body) { result in
                        switch result {
                        case let .success(data):
                            do {
                                if data.isEmpty {
                                    completion(nil)
                                } else {
                                    let response: RBServerStandardResponse = try JSONDecoder().decode(RBServerStandardResponse.self, from: data)
                                    if response.success != false {
                                        completion(nil)
                                    } else {
                                        completion(NSError.svLocalizedError(message: response.message ?? "An unknown error occurred", code: 0))
                                    }
                                }
                            } catch {
                                completion(error)
                            }
                        case let .failure(error):
                            completion(error)
                        }
                    }
                }
            case let .failure(error):
                completion(error)
            }
        }
    }
    
    public func unregister(epochId: Int, ebid: String, time: String, mac: String, completion: @escaping (_ error: Error?) -> ()) {
        ParametersManager.shared.fetchConfig { configResult in
            switch configResult {
            case let .success(serverTime):
                let nowTimeStamp: Double = Date().timeIntervalSince1970
                if abs(nowTimeStamp - serverTime) > ServerConstant.maxClockShiftToleranceInSeconds {
                    self.deviceTimeNotAlignedToServerTimeDetected()
                    completion(NSError.deviceTime)
                } else {
                    let body: RBServerUnregisterBody = RBServerUnregisterBody(epochId: epochId,
                                                                              ebid: ebid,
                                                                              time: time,
                                                                              mac: mac,
                                                                              pushToken: RBManager.shared.pushToken ?? "")
                    self.processRequest(url: self.baseUrl().appendingPathComponent("unregister"), method: .post, body: body) { result in
                        switch result {
                        case let .success(data):
                            do {
                                if data.isEmpty {
                                    completion(nil)
                                } else {
                                    let response: RBServerStandardResponse = try JSONDecoder().decode(RBServerStandardResponse.self, from: data)
                                    if response.success != false {
                                        completion(nil)
                                    } else {
                                        completion(NSError.svLocalizedError(message: response.message ?? "An unknown error occurred", code: 0))
                                    }
                                }
                            } catch {
                                completion(error)
                            }
                        case let .failure(error):
                            completion(error)
                        }
                    }
                }
            case let .failure(error):
                completion(error)
            }
        }
    }
    
    private func processRegister(captcha: String, captchaId: String, publicKey: String, completion: @escaping (_ result: Result<RBRegisterResponse, Error>) -> ()) {
        let body: RBServerRegisterBody = RBServerRegisterBody(captcha: captcha,
                                                              captchaId: captchaId,
                                                              clientPublicECDHKey: publicKey,
                                                              pushInfo: RBServerPushInfo(token: RBManager.shared.pushToken ?? "",
                                                                                         locale: Locale.current.identifier,
                                                                                         timezone: TimeZone.current.identifier))
        self.processRequest(url: self.baseUrl().appendingPathComponent("register"), method: .post, body: body) { result in
            switch result {
            case let .success(data):
                do {
                    let response: RBServerRegisterResponse = try JSONDecoder().decode(RBServerRegisterResponse.self, from: data)
                    
                    let rootJson: [String: Any] = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] ?? [:]
                    let config: [[String: Any]] = rootJson["config"] as? [[String: Any]] ?? []
                    
                    let transformedResponse: RBRegisterResponse = RBRegisterResponse(tuples: response.tuples,
                                                                                     timeStart: response.timeStart,
                                                                                     config: config)
                    completion(.success(transformedResponse))
                } catch {
                    completion(.failure(error))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
}

extension Server {
    
    private func prepareContactsReport(from helloMessages: [RBLocalProximity]) -> [RBServerContact] {
        var dict: [String: [RBLocalProximity]] = [:]
        helloMessages.forEach {
            var helloMessages: [RBLocalProximity] = dict[$0.ebid] ?? []
            helloMessages.append($0)
            dict[$0.ebid] = helloMessages
        }
        return dict.keys.compactMap {
            guard let helloMessages: [RBLocalProximity] = dict[$0] else { return nil }
            guard let ecc = helloMessages.first?.ecc else { return nil }
            let contactIds: [RBServerContactId] = helloMessages.map {
                RBServerContactId(timeCollectedOnDevice: $0.timeCollectedOnDevice,
                                  timeFromHelloMessage: $0.timeFromHelloMessage,
                                  mac: $0.mac,
                                  rssiRaw: $0.rssiRaw,
                                  rssiCalibrated: $0.rssiCalibrated)
            }
            return RBServerContact(ebid: $0, ecc: ecc, ids: contactIds)
        }
    }
    
}

extension Server {
    
    private func processRequest(url: URL, method: Method, body: RBServerBody, completion: @escaping (_ result: Result<Data, Error>) -> ()) {
        do {
            let bodyData: Data = try body.toData()
            let requestId: String = url.lastPathComponent
            guard completions[requestId] == nil else {
                let error: Error = NSError.svLocalizedError(message: "A request for \"\(requestId)\" is already being treated", code: 0)
                self.requestLoggingHandler(nil, nil, error)
                completion(.failure(error))
                return
            }
            completions[requestId] = completion
            var request: URLRequest = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-type")
            request.httpBody = bodyData
            let task: URLSessionDownloadTask = session.downloadTask(with: request)
            task.taskDescription = requestId
            task.resume()
        } catch {
            self.requestLoggingHandler(nil, nil, error)
            completion(.failure(error))
        }
    }
    
}

extension Server: URLSessionDelegate, URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let requestId: String = task.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        DispatchQueue.main.async {
            if let error = error {
                self.requestLoggingHandler(task, nil, error)
                completion(.failure(error))
            } else {
                let receivedData: Data = self.receivedData[requestId] ?? Data()
                if task.response?.svIsError == true {
                    let statusCode: Int = task.response?.svStatusCode ?? 0
                    let message: String = receivedData.isEmpty ? "No data received from the server" : (String(data: receivedData, encoding: .utf8) ?? "Unknown error")
                    let error: Error = NSError.svLocalizedError(message: "Uknown error (\(statusCode)). (\(message))", code: statusCode)
                    self.requestLoggingHandler(task, nil, error)
                    completion(.failure(error))
                } else {
                    self.requestLoggingHandler(task, receivedData, nil)
                    completion(.success(receivedData))
                }
            }
            self.completions[requestId] = nil
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let requestId: String = downloadTask.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        guard let data = try? Data(contentsOf: location) else { return }
        try? FileManager.default.removeItem(at: location)
        DispatchQueue.main.async {
            if downloadTask.response?.svIsError == true {
                let statusCode: Int = downloadTask.response?.svStatusCode ?? 0
                let message: String? = data.isEmpty ? "No logs received from the server" : String(data: data, encoding: .utf8)
                let error: Error = NSError.svLocalizedError(message: "Uknown error (\(statusCode)). (\(message ?? "N/A"))", code: statusCode)
                self.requestLoggingHandler(downloadTask, nil, error)
                completion(.failure(error))
                self.completions[requestId] = nil
            } else {
                self.receivedData[requestId] = data
            }
        }
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning.validateChallenge(challenge, certificateFile: certificateFile) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
}
