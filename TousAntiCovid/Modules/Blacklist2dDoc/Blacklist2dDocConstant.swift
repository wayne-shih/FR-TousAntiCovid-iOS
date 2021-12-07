// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Blacklist2dDocConstant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/07/2021 - for the TousAntiCovid project.
//

enum Blacklist2dDocConstant {
    private static let directoryName: String = "CertList"
    
    static let baseUrl: String = "https://\(Constant.Server.staticResourcesRootDomain)/json/blacklist/v2/\(directoryName)/2ddoc"
    static let filename: String = "2ddoc_list.pb.gz"
}
