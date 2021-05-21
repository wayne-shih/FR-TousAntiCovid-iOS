// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Constant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK

enum Constant {
    
    static let appStoreId: String = "1511279125"
    static let defaultLanguageCode: String = "en"
    static let maxPushDatesCount: Int = 100
    static let secondsBeforeStatusRetry: Double = 60.0
    static let proximityReactivationHours: [Int] = [1, 2, 4, 8, 12]
    
    #if DEBUG
    static let isDebug: Bool = true
    #else
    static let isDebug: Bool = false
    #endif
    
    enum ShortcutItem: String {
        case newAttestation = "home.moreSection.curfewCertificate"
        case venues = "appShortcut.venues"
    }
    
    enum Server {
        
        static let resourcesRootDomain: String = "app.tousanticovid.gouv.fr"
        
        static var baseUrl: URL { URL(string: "https://api.tousanticovid.gouv.fr/api/\(ParametersManager.shared.apiVersion.rawValue)")! }

        static var cleaReportBaseUrl: URL { URL(string: "https://signal-api.tousanticovid.gouv.fr/api/clea/\(ParametersManager.shared.cleaReportApiVersion.rawValue)")! }
        static var cleaStatusBaseUrl: URL { URL(string: "https://s3.fr-par.scw.cloud/clea-batch/\(ParametersManager.shared.cleaStatusApiVersion.rawValue)")! }

        static var analyticsBaseUrl: URL { URL(string: "https://analytics-api.tousanticovid.gouv.fr/api/\(ParametersManager.shared.analyticsApiVersion.rawValue)")! }

        static let publicKey: Data = Data(base64Encoded: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEAc9IDt6qJq453SwyWPB94JaLB2VfTAcL43YVtMr3HhDCd22gKaQXIbX1d+tNhfvaKM51sxeaXziPjntUzbTNiw==")!

        static var certificate: Data { Bundle.main.fileDataFor(fileName: "api.tousanticovid.gouv.fr", ofType: "pem") ?? Data() }

        
        static var analyticsCertificate: Data { Bundle.main.fileDataFor(fileName: "analytics-api.tousanticovid.gouv.fr", ofType: "pem") ?? Data() }

        static var resourcesCertificate: Data { Bundle.main.fileDataFor(fileName: Constant.Server.resourcesRootDomain, ofType: "pem") ?? Data() }

        static let jsonVersion: Int = 32
        static let baseJsonUrl: String = "https://\(Constant.Server.resourcesRootDomain)/json/version-\(jsonVersion)/Config"
        static let configUrl: URL = URL(string: "\(baseJsonUrl)/config.json")!

    }
    
}

typealias JSON = [String: Any]
typealias Headers = [String: String]
