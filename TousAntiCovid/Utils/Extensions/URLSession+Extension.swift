// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  URLSession+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 13/04/2021 - for the TousAntiCovid project.
//

import Foundation

extension URLSession {
    
    func dataTaskWithETag(with url: URL, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) -> URLSessionDataTask {
        dataTaskWithETag(with: URLRequest(url: url), completionHandler: completionHandler)
    }
    
    func dataTaskWithETag(with request: URLRequest, completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) -> URLSessionDataTask {
        var request: URLRequest = request
        if let url = request.url, let eTag = ETagManager.shared.eTag(for: url.absoluteString) {
            request.addValue(eTag, forHTTPHeaderField: ETagConstant.requestHeaderField)
        }
        return URLSessionDataTaskFactory.shared.dataTask(with: request, session: self) { data, response, error in
            if let url = request.url, let eTag = response?.eTag {
                ETagManager.shared.save(eTag: eTag, for: url.absoluteString)
            }
            if response?.isNotModified == true { // json not modified since last fetch
                completionHandler?(nil, response, nil)
            } else {
                completionHandler?(data, response, error)
            }
        }
    }
}
