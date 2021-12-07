// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DccBlacklistConstant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/07/2021 - for the TousAntiCovid project.
//

enum DccBlacklistConstant {
    private static let directoryName: String = "CertList"
    
    static let baseUrl: String = "https://\(Constant.Server.staticResourcesRootDomain)/json/blacklist/v2/\(directoryName)/dcc"
    static let filename: String = "certlist.pb.gz"

}
