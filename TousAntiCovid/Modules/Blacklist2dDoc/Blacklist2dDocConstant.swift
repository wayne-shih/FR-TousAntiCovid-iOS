// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Blacklist2dDocConstant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/07/2021 - for the TousAntiCovid project.
//

import Foundation

enum Blacklist2dDocConstant {

    static let directoryName: String = "CertList"
    static let baseUrl: String = "https://\(Constant.Server.staticResourcesRootDomain)/json/version-\(Constant.Server.jsonVersion)/\(directoryName)"
    static let filename: String = "2ddoc_list.json"
    static let certListUrl: URL = URL(string: "\(baseUrl)/\(filename)")!

}
