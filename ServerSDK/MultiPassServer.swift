// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MultiPassServer.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/01/2022 - for the TousAntiCovid project.
//

import Foundation

public final class MultiPassServer {

    public static let shared: MultiPassServer = MultiPassServer()

    private var serverUrl: (() -> URL?)!
    private var requestLoggingHandler: Server.RequestLoggingHandler?
    private var session: URLSession!

    private var multiPassMaxCertCount: Int = ParametersManager.shared.multiPassConfiguration.maxDcc

    private init() {}

    public func start(session: URLSession, serverUrl: @escaping () -> URL?, requestLoggingHandler: @escaping Server.RequestLoggingHandler) {
        self.session = session
        self.serverUrl = serverUrl
        self.requestLoggingHandler = requestLoggingHandler
    }

    public func generateMultiPassDcc(encodedCertificates: [String], publicKey: String, completion: @escaping (Result<String, Error>) -> ()) {
        guard encodedCertificates.count <= multiPassMaxCertCount else {
            completion(.failure(NSError.svLocalizedError(message: "Certificates count exceeds max authorized by config", code: 0)))
            return
        }
        guard let url = serverUrl() else {
            completion(.failure(NSError.svLocalizedError(message: "No server URL for light dcc generation.", code: 0)))
            return
        }
        let body: MultiPassBody = .init(publicKey: publicKey, certificates: encodedCertificates)
        let bodyData: Data? = try? body.toData()
        var urlRequest: URLRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = bodyData ?? Data()

        let dataTask: URLSessionDataTask = session.dataTask(with: urlRequest) { data, response, error in
            self.requestLoggingHandler?(urlRequest, response, data, error)
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(error ?? NSError.svLocalizedError(message: NSLocalizedString("common.error.unknown", comment: ""), code: 0)))
                }
                return
            }
            if (200...299).contains(response?.svStatusCode ?? 0) {
                do {
                    let transformResponse: MultiPassResponse = try MultiPassResponse.from(data: data)
                    DispatchQueue.main.async { completion(.success(transformResponse.response)) }
                } catch {
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            } else {
                do {
                    let errorResponse: MultiPassErrorResponse = try MultiPassErrorResponse.from(data: data)
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "", code: errorResponse.status, userInfo: ["codes": errorResponse.errors?.map { $0.code } ?? []])))
                    }
                } catch {
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }
        }
        dataTask.resume()
    }

}
