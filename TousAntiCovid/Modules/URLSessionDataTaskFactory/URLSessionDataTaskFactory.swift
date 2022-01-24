// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  URLSessionDataTaskFactory.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 07/01/2022 - for the TousAntiCovid project.
//

import Foundation

final class URLSessionDataTaskFactory: NSObject {
    static let shared: URLSessionDataTaskFactory = URLSessionDataTaskFactory()

    func backgroundSession(identifier: String, delegate: URLSessionDataDelegate) -> URLSession {
        let backgroundConfiguration: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: identifier)
        backgroundConfiguration.timeoutIntervalForRequest = 30.0
        backgroundConfiguration.timeoutIntervalForResource = 30.0
        backgroundConfiguration.sessionSendsLaunchEvents = true
        backgroundConfiguration.shouldUseExtendedBackgroundIdleMode = true
        backgroundConfiguration.httpShouldUsePipelining = true
        return URLSession(configuration: backgroundConfiguration, delegate: delegate, delegateQueue: .main)
        
    }

    func dataTask(with request: URLRequest, session: URLSession, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return session.dataTask(with: request, completionHandler: completionHandler)
        
    }

    func dataTask(with request: URLRequest, session: URLSession) -> URLSessionDataTask {
        return session.dataTask(with: request)
    }
}
