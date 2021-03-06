// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ConversionServer.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 24/06/2021 - for the TousAntiCovid project.
//

import Foundation

public final class ConversionServer: NSObject {
    public static let shared: ConversionServer = ConversionServer()

    private var convertUrl: (() -> URL)!
    private var requestLoggingHandler: Server.RequestLoggingHandler?
    private var session: URLSession!

    private override init() { super.init() }

    public func start(session: URLSession, convertUrl: @escaping () -> URL, requestLoggingHandler: @escaping Server.RequestLoggingHandler) {
        self.session = session
        self.convertUrl = convertUrl
        self.requestLoggingHandler = requestLoggingHandler
    }

    public func convertCertificate(encodedCertificate: String, fromFormat: String, toFormat: String, completion: @escaping (Result<String, Error>) -> ()) {
        let body: ConversionServerConvertBody = ConversionServerConvertBody(chainEncoded: encodedCertificate, source: fromFormat, destination: toFormat)
        let bodyData: Data? = try? JSONEncoder().encode(body)
        var urlRequest: URLRequest = URLRequest(url: convertUrl())
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = bodyData ?? Data()

        let dataTask: URLSessionDataTask = session.dataTask(with: urlRequest) { data, response, error in
            self.requestLoggingHandler?(urlRequest, response, data, error)
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(error ?? NSError.svLocalizedError(message: "common.error.unknown".lowercased(), code: 0)))
                }
                return
            }
            if (200...299).contains(response?.svStatusCode ?? 0) {
                let newCertificate: String = String(decoding: data, as: UTF8.self)
                DispatchQueue.main.async {
                    completion(.success(newCertificate))
                }
            } else {
                let decodedError: Error? = self.decodeError(data: data, statusCode: response?.svStatusCode)
                DispatchQueue.main.async {
                    completion(.failure(decodedError ?? error ?? NSError.svLocalizedError(message: "common.error.unknown".lowercased(), code: 0)))
                }
            }
        }
        dataTask.resume()
    }

    public func convertCertificateV2(encodedCertificate: String, fromFormat: String, toFormat: String, keyId: String, key: String, completion: @escaping (Result<String, Error>) -> ()) {
        guard let url = URL(string: "\(convertUrl().absoluteString)?publicKey=\(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)&keyAlias=\(keyId)") else {
            completion(.failure(NSError.svLocalizedError(message: "Impossible to create the convertCertificateV2 service URL", code: 0)))
            return
        }
        let body: ConversionServerConvertBody = ConversionServerConvertBody(chainEncoded: encodedCertificate, source: fromFormat, destination: toFormat)
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
                let newCertificate: String = String(decoding: data, as: UTF8.self)
                DispatchQueue.main.async {
                    completion(.success(newCertificate))
                }
            } else {
                let decodedError: Error? = self.decodeError(data: data, statusCode: response?.svStatusCode)
                DispatchQueue.main.async {
                    completion(.failure(decodedError ?? error ?? NSError.svLocalizedError(message: NSLocalizedString("common.error.unknown", comment: ""), code: 0)))
                }
            }
        }
        dataTask.resume()
    }

    private func decodeError(data: Data, statusCode: Int?) -> Error? {
        do {
            let inGroupError: InGroupError = try JSONDecoder().decode(InGroupError.self, from: data)
            let formattedError: NSError = NSError(domain: "Server-SDK", code: statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: inGroupError.msgError, "codeError": inGroupError.codeError])
            return formattedError
        } catch _ {
            return nil
        }
    }
}
