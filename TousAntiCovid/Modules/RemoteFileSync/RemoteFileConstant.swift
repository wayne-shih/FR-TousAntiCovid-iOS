// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RemoteFileConstant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/05/2020 - for the TousAntiCovid project.
//


import Foundation
import ServerSDK

enum RemoteFileConstant {

    static let baseUrl: String = "https://\(Constant.Server.staticResourcesRootDomain)/json/version-\(Constant.Server.jsonVersion)/Strings"
    static let stringsFilePrefix: String = "strings"
    
    static let useOnlyLocalStrings: Bool = ProcessInfo.processInfo.environment["LOCAL_STRINGS"] == "YES"
    static let minDurationBetweenUpdatesInSeconds: Double = ParametersManager.shared.minFilesRefreshInterval ?? 60.0
    
}
