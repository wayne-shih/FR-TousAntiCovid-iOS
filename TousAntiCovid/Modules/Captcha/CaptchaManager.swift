// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CaptchaManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK

final class CaptchaManager {

    static let shared: CaptchaManager = CaptchaManager()
    
    enum Method: String {
        case get = "GET"
        case post = "POST"
    }
    
    enum CaptchaType: String {
        case image = "IMAGE"
        case audio = "AUDIO"
    }
    
    func generateCaptchaImage(_ completion: @escaping (_ result: Result<Captcha, Error>) -> ()) {
        generate(captchaType: .image) { result in
            switch result {
            case let .success(response):
                self.getCaptchaImage(id: response.id) { result in
                    switch result {
                    case let .success(captchaData):
                        guard let image = UIImage(data: captchaData) else {
                            completion(.failure(NSError.localizedError(message: "Malformed Captcha image data", code: 0)))
                            return
                        }
                        completion(.success(Captcha(id: response.id, image: image, audio: nil)))
                    case let .failure(error):
                        completion(.failure(error))
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func generateCaptchaAudio(_ completion: @escaping (_ result: Result<Captcha, Error>) -> ()) {
        generate(captchaType: .audio) { result in
            switch result {
            case let .success(response):
                self.getCaptchaAudio(id: response.id) { result in
                    switch result {
                    case let .success(captchaData):
                        completion(.success(Captcha(id: response.id, image: nil, audio: captchaData)))
                    case let .failure(error):
                        completion(.failure(error))
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func generate(captchaType: CaptchaType, completion: @escaping (_ result: Result<CaptchaGenerationResponse, Error>) -> ()) {
        let generateBody: CaptchaGenerationBody = CaptchaGenerationBody(type: captchaType.rawValue, locale: Locale.current.languageCode ?? Constant.defaultLanguageCode)
        self.processRequest(url: CaptchaConstant.Url.create, method: .post, body: generateBody) { result in
            switch result {
            case let .success(data):
                do {
                    let response: CaptchaGenerationResponse = try CaptchaGenerationResponse.from(data: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(error))
                }
            case let .failure(error):
                AnalyticsManager.shared.reportError(serviceName: "captcha", apiVersion: ParametersManager.shared.apiVersion, code: (error as NSError).code)
                completion(.failure(error))
            }
        }
    }
    
    private func getCaptchaImage(id: String, completion: @escaping (_ result: Result<Data, Error>) -> ()) {
        processRequest(url: CaptchaConstant.Url.getImage(id: id), method: .get) { result in
            switch result {
            case let .success(data):
                completion(.success(data))
            case let .failure(error):
                AnalyticsManager.shared.reportError(serviceName: "captchaImage", apiVersion: ParametersManager.shared.apiVersion, code: (error as NSError).code)
                completion(.failure(error))
            }
        }
    }
    
    private func getCaptchaAudio(id: String, completion: @escaping (_ result: Result<Data, Error>) -> ()) {
        processRequest(url: CaptchaConstant.Url.getAudio(id: id), method: .get) { result in
            switch result {
            case let .success(data):
                completion(.success(data))
            case let .failure(error):
                AnalyticsManager.shared.reportError(serviceName: "captchaAudio", apiVersion: ParametersManager.shared.apiVersion, code: (error as NSError).code)
                completion(.failure(error))
            }
        }
    }

    private func processRequest(url: URL, method: Method, body: CaptchaServerBody? = nil, completion: @escaping (_ result: Result<Data, Error>) -> ()) {
        do {
            var request: URLRequest = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-type")
            if let body = body {
                let bodyData: Data = try body.toData()
                request.httpBody = bodyData
            }
            let task: URLSessionDataTask = URLSessionDataTaskFactory.shared.dataTask(with: request, session: UrlSessionManager.shared.session) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        guard let data = data else {
                            completion(.failure(NSError.localizedError(message: "No data for Captcha", code: 0)))
                            return
                        }
                        completion(.success(data))
                    }
                }
            }
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }

}
