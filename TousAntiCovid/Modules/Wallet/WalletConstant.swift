// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletConstant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 24/03/2021 - for the TousAntiCovid project.
//

import Foundation
import ServerSDK

enum WalletConstant {
    static let vaccinBoosterDoseNumber: Int = 3
    
    enum Separator: String {
        case group = "<GS>"
        case unit = "<US>"
        case declareCode = "%1E"

        var ascii: String {
            switch self {
            case .group:
                return String(UnicodeScalar(UInt8(29)))
            case .unit:
                return String(UnicodeScalar(UInt8(31)))
            case .declareCode:
                return String(UnicodeScalar(UInt8(30)))
            }
        }
    }

    enum DccPrefix: String {
        case activityCertificate = "HCFR1:"
        case exemptionCertificate = "EX1:"
    }

    enum URLPath: String {
        case wallet = "/app/wallet"
        case wallet2D = "/app/wallet2d"
        case walletDCC = "/app/walletdcc"
    }
    
    enum CertificateType: String, CaseIterable {
        case sanitary = "B2"
        case vaccination = "L1"
        case sanitaryEurope = "test"
        case vaccinationEurope = "vaccine"
        case recoveryEurope = "recovery"
        case activityEurope = "activity"
        case exemptionEurope = "exemption"
        case unknown = "unknown"

        enum Format: String {
            case wallet2DDoc = "DEUX_D_DOC"
            case walletDCC = "DGCA"
            case walletDCCACT = "DCC_ACT"
        }

        var textKey: String {
            switch self {
            case .vaccination:
                return "vaccinCertificate"
            case .sanitary:
                return "testCertificate"
            case .sanitaryEurope:
                return "sanitaryEurope"
            case .vaccinationEurope:
                return "vaccinationEurope"
            case .recoveryEurope:
                return "recoveryEurope"
            case .activityEurope:
                return "activityEurope"
            case .exemptionEurope:
                return "exemptionEurope"
            case .unknown:
                return "vaccinCertificate"
            }
        }
        
        var validationRegex: String {
            switch self {
            case .sanitary:
                return
                    "^[A-Z\\d]{4}" + // Characters 0 to 3 are ignored. They represent the document format version.
                    "(?<authority>[A-Z\\d]{4})" + // Characters 4 to 7 represent the document signing authority.
                    "(?<certificateId>[A-Z\\d]{4})" + // Charatcers 8 to 11 represent the id of the certificate used to sign the document.
                    "[A-Z\\d]{8}" + // Characters 12 to 19 are ignored.
                    "B2" + // Characters 20 and 21 represent the wallet certificate type (sanitary, ...)
                    "[A-Z\\d]{4}" + // Characters 22 to 25 are ignored.
                    "F0(?<F0>[^\\x1D\\x1E]+)[\\x1D\\x1E]" + // We capture the field F0. It must have at least one character.
                    "F1(?<F1>[^\\x1D\\x1E]+)[\\x1D\\x1E]" + // We capture the field F1. It must have at least one character.
                    "F2(?<F2>\\d{8})" + // We capture the field F2. It can only contain digits.
                    "F3(?<F3>[FMU]{1})" + // We capture the field F3. It can only contain "F", "M" or "U".
                    "F4(?<F4>[A-Z\\d]{3,7})\\x1D?" + // We capture the field F4. It can contain 3 to 7 uppercased letters and/or digits. It can also be ended by the GS ASCII char (29) if the field reaches its max length.
                    "F5(?<F5>[PNIX]{1})" + // We capture the field F5. It can only contain "P", "N", "I" or "X".
                    "F6(?<F6>\\d{12})" +  // We capture the field F6. It can only contain digits.
                    "\\x1F{1}" + // This character is separating the message from its signature.
                    "[A-Z\\d\\=]+$" // This is the message signature.
            case .vaccination:
                return
                    "^[A-Z\\d]{4}" + // Characters 0 to 3 are ignored. They represent the document format version.
                    "(?<authority>[A-Z\\d]{4})" + // Characters 4 to 7 represent the document signing authority.
                    "(?<certificateId>[A-Z\\d]{4})" + // Charatcers 8 to 11 represent the id of the certificate used to sign the document.
                    "[A-Z\\d]{8}" + // Characters 12 to 19 are ignored.
                    "L1" + // Characters 20 and 21 represent the wallet certificate type (sanitary, ...)
                    "[A-Z\\d]{4}" + // Characters 22 to 25 are ignored.
                    "L0(?<L0>[^\\x1D\\x1E]+)[\\x1D\\x1E]" + // We capture the field L0. It can contain uppercased letters and spaces. It can also be ended by the GS ASCII char (29) if the field reaches its max length.
                    "L1(?<L1>[^\\x1D\\x1E]+)[\\x1D\\x1E]" + // We capture the field L1. It can contain uppercased letters, digits, spaces and slashes. It can also be ended by the GS ASCII char (29) if the field reaches its max length.
                    "L2(?<L2>\\d{8})" + // We capture the field L2. It can only contain 8 digits.
                    "L3(?<L3>[^\\x1D\\x1E]*)[\\x1D\\x1E]" + // We capture the field L3. It can contain any characters.
                    "L4(?<L4>[^\\x1D\\x1E]+)[\\x1D\\x1E]" + // We capture the field L4. It must have at least one character
                    "L5(?<L5>[^\\x1D\\x1E]+)[\\x1D\\x1E]" + // We capture the field L5. It must have at least one character
                    "L6(?<L6>[^\\x1D\\x1E]+)[\\x1D\\x1E]" + // We capture the field L6. It must have at least one character
                    "L7(?<L7>\\d{1})" + // We capture the field L7. It can contain only one digit.
                    "L8(?<L8>\\d{1})" + // We capture the field L8. It can contain only one digit.
                    "L9(?<L9>\\d{8})" + // We capture the field L9. It can only contain 8 digits.
                    "LA(?<LA>[A-Z\\d]{2})" + // We capture the field LA. It can only contain 2 uppercased letters or digits.
                    "\\x1F{1}" + // This character is separating the message from its signature.
                    "[A-Z\\d\\=]+$" // This is the message signature.
            case .activityEurope, .recoveryEurope, .sanitaryEurope, .vaccinationEurope, .exemptionEurope, .unknown:
                return ""
            }
        }

        var headerDetectionRegex: String {
            switch self {
            case .sanitary:
                return
                    "^[A-Z\\d]{4}" + // Characters 0 to 3 are ignored. They represent the document format version.
                    "(?<authority>[A-Z\\d]{4})" + // Characters 4 to 7 represent the document signing authority.
                    "(?<certificateId>[A-Z\\d]{4})" + // Charatcers 8 to 11 represent the id of the certificate used to sign the document.
                    "[A-Z\\d]{8}" + // Characters 12 to 19 are ignored.
                    "B2" // Characters 20 and 21 represent the wallet certificate type (sanitary, ...)
            case .vaccination:
                return
                    "^[A-Z\\d]{4}" + // Characters 0 to 3 are ignored. They represent the document format version.
                    "(?<authority>[A-Z\\d]{4})" + // Characters 4 to 7 represent the document signing authority.
                    "(?<certificateId>[A-Z\\d]{4})" + // Charatcers 8 to 11 represent the id of the certificate used to sign the document.
                    "[A-Z\\d]{8}" + // Characters 12 to 19 are ignored.
                    "L1" // Characters 20 and 21 represent the wallet certificate type (sanitary, ...)
            case .activityEurope, .recoveryEurope, .sanitaryEurope, .vaccinationEurope, .exemptionEurope, .unknown:
                return ""
            }
        }

        var format: Format {
            switch self {
            case .sanitary, .vaccination:
                return .wallet2DDoc
            case .sanitaryEurope, .vaccinationEurope, .recoveryEurope, .exemptionEurope, .unknown:
                return .walletDCC
            case .activityEurope:
                return .walletDCCACT
            }
        }
    }
    
    enum VaccineType: CaseIterable {
        case arnm
        case janssen
        case astraZeneca
        
        var stringValues: [String] {
            let vaccineTypes: Vaccins? = ParametersManager.shared.vaccinTypes
            switch self {
            case .arnm: return vaccineTypes?.arnm ?? ["EU/1/20/1528", "EU/1/20/1507", "Covidshield", "Covid-19-recombinant", "R-COVI"]
            case .janssen: return vaccineTypes?.janssen ?? ["EU/1/20/1525"]
            case .astraZeneca: return vaccineTypes?.astraZeneca ?? ["EU/1/21/1529"]
            }
        }
    }
}
