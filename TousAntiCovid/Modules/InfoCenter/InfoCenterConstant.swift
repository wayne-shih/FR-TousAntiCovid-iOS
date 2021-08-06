// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  InfoCenterConstant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import Foundation

enum InfoCenterConstant {

    static let directoryName: String = "InfoCenter"
    static let baseUrl: String = "https://\(Constant.Server.staticResourcesRootDomain)/json/version-\(Constant.Server.jsonVersion)/\(directoryName)"
    static let tagsUrl: URL = URL(string: "\(baseUrl)/info-tags.json")!
    static let infoCenterUrl: URL = URL(string: "\(baseUrl)/info-center.json")!
    static let lastUpdatedAtUrl: URL = URL(string: "\(baseUrl)/info-center-lastupdate.json")!
    
}
