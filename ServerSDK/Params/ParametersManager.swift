// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ParametersManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 14/05/2020 - for the TousAntiCovid project.
//


import UIKit
import RobertSDK

public final class ParametersManager: NSObject {
    
    public typealias RequestCompletion = (_ result: Result<(Double), Error>) -> ()
    
    public enum ApiVersion: String {
        case v5
        case v6
    }
    
    public enum CleaStatusApiVersion: String {
        case v1
    }

    public enum CleaReportApiVersion: String {
        case v1
    }
    
    public enum AnalyticsApiVersion: String {
        case v1
    }

    public enum InGroupApiVersion: String {
        case v0
    }
    
    public static let shared: ParametersManager = ParametersManager()
    var url: URL!
    var certificateFiles: [Data]!
    
    public var minHourContactNotif: Int? {
        guard let hour = valueFor(name: "app.minHourContactNotif") as? Double else { return nil }
        return Int(hour)
    }
    public var maxHourContactNotif: Int? {
        guard let hour = valueFor(name: "app.maxHourContactNotif") as? Double else { return nil }
        return Int(hour)
    }

    public var minFilesRefreshInterval: Double? { valueFor(name: "app.minFilesRefreshInterval") as? Double }

    public var displayRecordVenues: Bool { valueFor(name: "app.displayRecordVenues") as? Bool ?? false }
    public var displayAttestation: Bool { valueFor(name: "app.displayAttestation") as? Bool ?? false }
    public var displaySanitaryCertificatesWallet: Bool { valueFor(name: "app.displaySanitaryCertificatesWallet") as? Bool ?? false }
    public var displaySanitaryCertificatesValidation: Bool { valueFor(name: "app.displaySanitaryCertificatesValidation") as? Bool ?? false }
    public var isAnalyticsOn: Bool { valueFor(name: "app.isAnalyticsOn") as? Bool ?? false }
    public var walletTestCertificateValidityThresholds: [Int] { valueFor(name: "app.wallet.testCertificateValidityThresholds") as? [Int] ?? [48, 72] }
    public var walletConversionApiVersion: Int { valueFor(name: "app.wallet.conversionApiVersion") as? Int ?? 1 }
    public var walletConversionPublicKey: (key: String, value: String)? {
        (valueFor(name: "app.wallet.conversionPublicKey") as? [String: String])?.first
    }

    public var displayIsolation: Bool { valueFor(name: "app.displayIsolation") as? Bool ?? false }
    public var isolationMinRiskLevel: Double { valueFor(name: "app.isolationMinRiskLevel") as? Double ?? 4.0 }
    public var ameliUrl: String { valueFor(name: "app.ameliUrl") as? String ?? "https://declare.ameli.fr/tousanticovid/t/%@/" }
    public var ratingsKeyFiguresOpeningThreshold: Int { valueFor(name: "app.ratingsKeyFiguresOpeningThreshold") as? Int ?? 10 }
    public var contagiousSpan: Int { valueFor(name: "app.contagiousSpan") as? Int ?? 10 }
    public var displayVaccination: Bool { valueFor(name: "app.displayVaccination") as? Bool ?? false }
    public var vaccinationCentersCount: Int { valueFor(name: "app.vaccinationCentersCount") as? Int ?? 5 }
    public var isolationDuration: Double { valueFor(name: "app.isolation.duration") as? Double ?? 604800.0 }
    public var isolationCovidDuration: Double { valueFor(name: "app.isolation.durationCovid") as? Double ?? 864000.0 }
    public var postIsolationDuration: Double { valueFor(name: "app.postIsolation.duration") as? Double ?? 604800.0 }
    
    var appAvailability: Bool? { valueFor(name: "app.appAvailability") as? Bool }
    var preSymptomsSpan: Int {
        Int(valueFor(name: "app.preSymptomsSpan") as? Double ?? 2)
    }
    var positiveSampleSpan: Int {
        Int(valueFor(name: "app.positiveSampleSpan") as? Double ?? 7)
    }

    public var minHoursBetweenVisibleNotif: Int {
        guard let hour = valueFor(name: "app.push.minHoursBetweenVisibleNotifications") as? Double else { return 24 }
        return Int(hour)
    }
    public var proximityReactivationReminderHours: [Double] {
        valueFor(name: "app.proximityReactivation.reminderHours") as? [Double] ?? [1.0, 2.0, 4.0, 8.0, 12.0]
        
    }
    private var minStatusRetryDuration: Double? {
        guard let hour = valueFor(name: "app.minStatusRetryDuration") as? Double else { return nil }
        return Double(hour)
    }
    public var minStatusRetryTimeInterval: Double {
        (minStatusRetryDuration ?? 0.5) * 3600.0
    }
    var checkStatusFrequency: Double? { valueFor(name: "app.checkStatusFrequency") as? Double }
    var randomStatusHour: Double? { valueFor(name: "app.randomStatusHour") as? Double }
    public var pushDisplayOnSuccess: Bool { valueFor(name: "app.push.displayOnSuccess") as? Bool ?? false }
    public var pushDisplayAll: Bool { valueFor(name: "app.push.displayAll") as? Bool ?? false }

    public var displayDepartmentLevel: Bool { valueFor(name: "app.keyfigures.displayDepartmentLevel") as? Bool ?? false }
    
    public var qrCodeDeletionHours: Double { valueFor(name: "app.qrCode.deletionHours") as? Double ?? 24.0}
    public var qrCodeExpiredHours: Double { valueFor(name: "app.qrCode.expiredHours") as? Double ?? 1.0}
    public var qrCodeFormattedString: String { valueFor(name: "app.qrCode.formattedString") as? String ?? "Cree le: <creationDate> a <creationHour>;\nNom: <lastname>;\nPrenom: <firstname>;\nNaissance: <dob> a <cityofbirth>;\nAdresse: <address> <zip> <city> <country>;\nSortie: <datetime-day> a <datetime-hour>;\nMotifs: <reason-code>" }
    public var qrCodeFormattedStringDisplayed: String { valueFor(name: "app.qrCode.formattedStringDisplayed") as? String ?? "Créé le <creationDate> à <creationHour>\nNom : <lastname>;\nPrénom : <firstname>;\nNaissance : <dob> à <cityofbirth>\nAdresse : <address> <zip> <city> <country>\nSortie : <datetime-day> à <datetime-hour>\nMotif: <reason-code>" }
    public var qrCodeFooterString: String { valueFor(name: "app.qrCode.footerString") as? String ?? "<firstname> - <datetime-day>, <datetime-hour>\n<reason-shortlabel>" }
    
    public var statusTimeInterval: Double {
        let randomStatusHour: Double = self.randomStatusHour ?? 0.0
        let interval: Double = (self.checkStatusFrequency ?? 0.0) * 3600.0 + (randomStatusHour == 0.0 ? 0.0 : Double.random(in: 0..<randomStatusHour * 3600.0))
        return interval
    }
    public var quarantinePeriod: Int {
        guard let period = valueFor(name: "app.quarantinePeriod") as? Double else { return 7 }
        return Int(period)
    }
    public var venuesTimestampRoundingInterval: Int {
        guard let interval = valueFor(name: "app.venuesTimestampRoundingInterval") as? Double else { return 900 }
        return Int(interval)
    }
    public var venuesRetentionPeriod: Int {
        guard let period = valueFor(name: "app.venuesRetentionPeriod") as? Double else { return 14 }
        return Int(period)
    }
    public var covidPlusNoTracing: Int {
        guard let period = valueFor(name: "app.covidPlusNoTracing") as? Double else { return 60 }
        return Int(period)
    }
    
    public var covidPlusWarning: Int {
        guard let period = valueFor(name: "app.covidPlusWarning") as? Double else { return 14 }
        return Int(period)
    }
    public var venuesSalt: Int {
        guard let period = valueFor(name: "app.venuesSalt") as? Double else { return 1000 }
        return Int(period)
    }

    public var daysAfterCompletion: [DaysAfterCompletionEntry] {
        guard let value = valueFor(name: "app.wallet.vaccin.daysAfterCompletion") as? [[String: Any]] else {
            return []
        }
        do {
            let jsonData: Data = try JSONSerialization.data(withJSONObject: value)
            return try JSONDecoder().decode([DaysAfterCompletionEntry].self, from: jsonData)
        } catch {
            return []
        }
    }

    public var confettiBirthRate: Double { valueFor(name: "app.wallet.confettiBirthRate") as? Double ?? 10.0 }

    var dataRetentionPeriod: Int {
        guard let period = valueFor(name: "app.dataRetentionPeriod") as? Double else { return 14 }
        return Int(period)
    }
    public var bleServiceUuid: String? { valueFor(name: "ble.serviceUUID") as? String }
    public var bleCharacteristicUuid: String? { valueFor(name: "ble.characteristicUUID") as? String }
    public var bleFilteringConfig: String? { valueFor(name: "ble.filterConfig") as? String }
    public var bleFilteringMode: String? { valueFor(name: "ble.filterMode") as? String }

    public var displayCertificateConversion: Bool { valueFor(name: "app.displayCertificateConversion") as? Bool ?? false }

    public var apiVersion: ApiVersion { ApiVersion(rawValue: valueFor(name: "app.apiVersion") as? String ?? "") ?? .v5 }
    public var cleaStatusApiVersion: CleaStatusApiVersion { CleaStatusApiVersion(rawValue: valueFor(name: "app.cleaStatusApiVersion") as? String ?? "") ?? .v1 }
    public var cleaReportApiVersion: CleaReportApiVersion { CleaReportApiVersion(rawValue: valueFor(name: "app.cleaReportApiVersion") as? String ?? "") ?? .v1 }
    public var analyticsApiVersion: AnalyticsApiVersion { AnalyticsApiVersion(rawValue: valueFor(name: "app.analyticsApiVersion") as? String ?? "") ?? .v1 }

    public var certificateConversionSidepOnlyCode: [String] { valueFor(name: "app.wallet.certificateConversionSidepOnlyCode") as? [String] ?? [] }

    public var inGroupApiVersion: InGroupApiVersion = .v0

    public var cleaUrl: String { cleaUrls.randomElement() ?? defaultCleaUrl }
    public let defaultCleaUrl: String = "https://s3.fr-par.scw.cloud/clea-batch/"

    private var cleaUrls: [String] { valueFor(name: "app.cleaUrls") as? [String] ?? [] }
    private var config: [[String: Any]] = [] {
        didSet { distributeUpdatedConfig() }
    }

    private var receivedData: [String: Data] = [:]
    private var completions: [String: RequestCompletion] = [:]
    
    private lazy var session: URLSession = {
        let backgroundConfiguration: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "fr.gouv.stopcovid.ios.ServerSDK-Config")
        backgroundConfiguration.timeoutIntervalForRequest = ServerConstant.timeout
        backgroundConfiguration.timeoutIntervalForResource = ServerConstant.timeout
        return URLSession(configuration: backgroundConfiguration, delegate: self, delegateQueue: .main)
    }()
    
    public func start() {
        writeInitialFileIfNeeded()
        loadLocalConfig()
    }

    public func getDeviceParametersFor(model: String) -> DeviceParameters? {
        guard let deviceCalibration = valueFor(name: "ble.calibration") as? [[String: Any]] else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: deviceCalibration, options: []) else { return nil }
        let devicesParameters: [DeviceParameters] = (try? JSONDecoder().decode([DeviceParameters].self, from: data)) ?? []
        if let parameters = devicesParameters.filter({ $0.model == model }).first {
            return parameters
        } else if let parameters = devicesParameters.filter({ $0.model == "iPhone" }).first, UIDevice.current.userInterfaceIdiom == .phone {
            return parameters
        } else if let parameters = devicesParameters.filter({ $0.model == "iPad" }).first, UIDevice.current.userInterfaceIdiom == .pad {
            return parameters
        } else if let parameters = devicesParameters.filter({ $0.model == "DEFAULT" }).first {
            return parameters
        } else {
            let txAverage: Double = -15
            let rxAverage: Double = -5
            return DeviceParameters(model: "-", txFactor: txAverage, rxFactor: rxAverage)
        }
    }
    
    public func walletOldCertificateThresholdInDays(certificateType: String) -> Int? {
        guard let dict = valueFor(name: "app.wallet.oldCertificateThresholdInDays") as? [String: Int] else { return nil }
        guard let thresholdValue = dict[certificateType.lowercased()] else { return nil }
        return thresholdValue
    }
    public func walletPublicKey(authority: String, certificateId: String) -> String? {
        guard let allPubKeys = valueFor(name: "app.walletPubKeys") as? [[String: Any]] else { return nil }
        guard let authPubKeysDict = allPubKeys.first(where: { $0["auth"] as? String == authority }) else { return nil }
        guard let authPubKeys = authPubKeysDict["pubKeys"] as? [String: String] else { return nil }
        return authPubKeys[certificateId]
    }
    
    public func fetchConfig(completion: @escaping RequestCompletion) {
        let requestId: String = UUID().uuidString
        completions[requestId] = completion
        var request: URLRequest = URLRequest(url: url)
        let eTag: String? = SVETagManager.shared.eTag(for: url.absoluteString)
        eTag.map { request.addValue($0, forHTTPHeaderField: ServerConstant.Etag.requestHeaderField) }
        let task: URLSessionDataTask = session.dataTask(with: request)
        task.taskDescription = requestId
        task.resume()
    }
    
    private func loadLocalConfig() {
        guard let data = try? Data(contentsOf: localFileUrl()) else { return }
        guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else { return }
        self.config = json["config"] as? [[String: Any]] ?? []
    }
    
    private func valueFor(name: String) -> Any? {
        config.first { $0["name"] as? String == name }?["value"]
    }
    
    private func distributeUpdatedConfig() {
        RBManager.shared.proximitiesRetentionDurationInDays = dataRetentionPeriod
        RBManager.shared.preSymptomsSpan = preSymptomsSpan
        RBManager.shared.positiveSampleSpan = positiveSampleSpan
        RBManager.shared.contagiousSpan = contagiousSpan
        RBManager.shared.covidPlusNoTracingDuration = covidPlusNoTracing
        if RBManager.shared.isProximityActivated {
            RBManager.shared.updateProximityDetectionSettings()
        }
        refreshBackgroundFetchInterval()
    }
    
    private func refreshBackgroundFetchInterval() {
        if let checkStatusFrequency = checkStatusFrequency {
            let randomStatusHour: Double = self.randomStatusHour ?? 0.0
            let interval: Double = checkStatusFrequency * 3600.0 + (randomStatusHour == 0.0 ? 0.0 : Double.random(in: 0..<randomStatusHour * 3600.0))
            UIApplication.shared.setMinimumBackgroundFetchInterval(interval)
        }
    }
    
    private func writeInitialFileIfNeeded() {
        let fileUrl: URL = Bundle(for: ParametersManager.self).url(forResource: url.deletingPathExtension().lastPathComponent, withExtension: url.pathExtension)!
        let destinationFileUrl: URL = createWorkingDirectoryIfNeeded().appendingPathComponent("config.json")
        if !FileManager.default.fileExists(atPath: destinationFileUrl.path) {
            try? FileManager.default.removeItem(at: destinationFileUrl)
            try? FileManager.default.copyItem(at: fileUrl, to: destinationFileUrl)
        }
    }
    
    private func createWorkingDirectoryIfNeeded() -> URL {
        let directoryUrl: URL = FileManager.svLibraryDirectory().appendingPathComponent("config")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }
    
    private func localFileUrl() -> URL {
        createWorkingDirectoryIfNeeded().appendingPathComponent("config.json")
    }
    
}

extension ParametersManager: URLSessionDelegate, URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let requestId: String = dataTask.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        DispatchQueue.main.async {
            if dataTask.response?.svIsError == true {
                let statusCode: Int = dataTask.response?.svStatusCode ?? 0
                let message: String = data.isEmpty ? "No logs received from the server" : (String(data: data, encoding: .utf8) ?? "Unknown error")
                completion(.failure(NSError.svLocalizedError(message: "Unknown error (\(statusCode)). (\(message))", code: statusCode)))
                self.completions[dataTask.taskDescription ?? ""] = nil
            } else {
                var receivedData: Data = self.receivedData[requestId] ?? Data()
                receivedData.append(data)
                self.receivedData[requestId] = receivedData
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let requestId: String = task.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        DispatchQueue.main.async {
            if let error = error {
                completion(.failure(error))
            } else if task.response?.svIsNotModified == true {
                // Response not updated since last fetch (ETag feature)
                completion(.success((task.response!.serverTime)))
            } else {
                let receivedData: Data = self.receivedData[requestId] ?? Data()
                if task.response!.svIsError == true {
                    let statusCode: Int = task.response?.svStatusCode ?? 0
                    let message: String = receivedData.isEmpty ? "No data received from the server" : (String(data: receivedData, encoding: .utf8) ?? "Unknown error" )
                    completion(.failure(NSError.svLocalizedError(message: "Unknown error (\(statusCode)). (\(message))", code: statusCode)))
                    self.completions[task.taskDescription ?? ""] = nil
                } else {
                    do {
                        let json: [String: Any] = (try JSONSerialization.jsonObject(with: receivedData, options: [])) as? [String: Any] ?? [:]
                        guard !json.isEmpty else {
                            DispatchQueue.main.async {
                                completion(.failure(NSError.svLocalizedError(message: "Malformed json config. Using the last known version instead.", code: 0)))
                            }
                            return
                        }
                        try receivedData.write(to: self.localFileUrl())
                        self.config = json["config"] as? [[String: Any]] ?? []
                        // Save eTag if present
                        if let eTag = task.response?.svETag, let url = task.currentRequest?.url?.absoluteString {
                            // We don't need to persiste received data in ETagsManager
                            SVETagManager.shared.save(eTag: eTag, data: Data(), for: url)
                        }
                        DispatchQueue.main.async {
                            completion(.success((task.response!.serverTime)))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }
            self.completions[task.taskDescription ?? ""] = nil
        }
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning.validateChallenge(challenge, certificateFiles: certificateFiles) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
}
