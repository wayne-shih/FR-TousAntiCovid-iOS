// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  URLSessionManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 31/08/2021 - for the TousAntiCovid project.
//

import Foundation
import ServerSDK

final class UrlSessionManager: NSObject {

    static let shared: UrlSessionManager = UrlSessionManager()

    lazy var session: URLSession = {
        let session: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        session.configuration.httpShouldUsePipelining = true
        return session
    }()

}

extension UrlSessionManager: URLSessionDelegate {

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let certificates: [Data] = challenge.protectionSpace.host.hasSuffix("tacv.myservices-ingroupe.com") ? Constant.Server.convertCertificates : Constant.Server.certificates
        CertificatePinning.validateChallenge(challenge, certificateFiles: certificates) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }



}
