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
    static let supportedLanguageCodes: [String] = ["en", "fr"]
    static let maxPushDatesCount: Int = 100
    static let secondsBeforeStatusRetry: Double = 60.0
    static let proximityReactivationHours: [Int] = [1, 2, 4, 8, 12]
    
    @UserDefault(key: .appLanguage)
    static var appLanguage: String? {
        didSet {
            LocalizationsManager.shared.reloadLanguage()
            PrivacyManager.shared.reloadLanguage()
            LinksManager.shared.reloadLanguage()
            KeyFiguresExplanationsManager.shared.reloadLanguage()
        }
    }

    #if targetEnvironment(simulator)
    static let isSimulator: Bool = true
    #else
    static let isSimulator: Bool = false
    #endif

    #if DEBUG
    static let isDebug: Bool = true
    #else
    static let isDebug: Bool = false
    #endif
    
    enum Language {
        static let french: String = "fr"
        static let english: String = "en"
    }
    enum ShortcutItem: String {
        case newAttestation = "home.moreSection.curfewCertificate"
        case venues = "appShortcut.venues"
        case qrScan = "appShortcut.qrScan"
        case favoriteDcc = "appShortcut.favoriteDcc"
    }
    
    enum Server {
        
        static let resourcesRootDomain: String = "app.tousanticovid.gouv.fr"
        static let staticResourcesRootDomain: String = "app-static.tousanticovid.gouv.fr"
        
        static var baseUrl: URL { URL(string: "https://api.tousanticovid.gouv.fr/api/\(ParametersManager.shared.apiVersion.rawValue)")! }
        
        static var cleaReportBaseUrl: URL { URL(string: "https://signal-api.tousanticovid.gouv.fr/api/clea/\(ParametersManager.shared.cleaReportApiVersion.rawValue)")! }
        
        static var analyticsBaseUrl: URL { URL(string: "https://analytics-api.tousanticovid.gouv.fr/api/\(ParametersManager.shared.analyticsApiVersion.rawValue)")! }
        
        static let publicKey: Data = Data(base64Encoded: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEAc9IDt6qJq453SwyWPB94JaLB2VfTAcL43YVtMr3HhDCd22gKaQXIbX1d+tNhfvaKM51sxeaXziPjntUzbTNiw==")!
        
        static var certificates: [Data] { ["certigna-root", "certigna-services"].compactMap { Bundle.main.fileDataFor(fileName: $0, ofType: "pem") } }
        
        static var dccCertsUrl: URL { URL(string: "https://\(staticResourcesRootDomain)/json/version-\(jsonVersion)/Certs/dcc-certs.json")! }
        
        static var convertCertificates: [Data] { ["ISRG-Root-X1", "R3"].compactMap { Bundle.main.fileDataFor(fileName: $0, ofType: "pem") } }
        
        static var convertUrl: URL {
            ParametersManager.shared.walletConversionApiVersion == 2 ?
                URL(string: "https://portail.tacv.myservices-ingroupe.com/api/v2/client/convertor/decode/decodeDocument")! :
                URL(string: "https://portail.tacv.myservices-ingroupe.com/api/client/convertor/decode/decodeDocument")!
        }
        
        static var activityCertificateGenerationUrl: URL? { nil }
        

        static let jsonVersion: Int = 36
        static let baseJsonUrl: String = "https://\(resourcesRootDomain)/json/version-\(jsonVersion)/Config"
        static let configUrl: URL = URL(string: "\(baseJsonUrl)/config.json")!
        

        static func cleaStatusBaseUrl(fallbackUrl: Bool = false) -> URL {
            let defaultCleaUrl: URL = URL(string: ParametersManager.shared.defaultCleaUrl)!
            let baseUrl: URL = fallbackUrl ? defaultCleaUrl : URL(string: ParametersManager.shared.cleaUrl) ?? defaultCleaUrl
            return baseUrl.appendingPathComponent(ParametersManager.shared.cleaStatusApiVersion.rawValue)
        }

    }

}

typealias JSON = [String: Any]
typealias Headers = [String: String]
