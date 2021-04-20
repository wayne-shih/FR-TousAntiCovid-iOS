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

enum WalletConstant {
    
    enum Separator: String {
        case group = "<GS>"
        case unit = "<US>"

        var ascii: String {
            switch self {
            case .group:
                return String(UnicodeScalar(UInt8(29)))
            case .unit:
                return String(UnicodeScalar(UInt8(31)))
            }
        }
    }
    
    enum CertificateType: String, CaseIterable {
        case sanitary = "B2"
        
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
                    "F0(?<F0>[A-Z\\d\\s\\/]+)\\x1D?" + // We capture the field F0. It can contain uppercased letters, digits, spaces and slashes. It can also be ended by the GS ASCII char (29) if the field reaches its max length.
                    "F1(?<F1>[A-Z\\s]+)\\x1D?" + // We capture the field F1. It can contain uppercased letters and spaces. It can also be ended by the GS ASCII char (29) if the field reaches its max length.
                    "F2(?<F2>\\d{8})" + // We capture the field F2. It can only contain digits.
                    "F3(?<F3>[FMU]{1})" + // We capture the field F3. It can only contain "F", "M" or "U".
                    "F4(?<F4>[A-Z\\d]{3,7})\\x1D?" + // We capture the field F4. It can contain 3 to 7 uppercased letters and/or digits. It can also be ended by the GS ASCII char (29) if the field reaches its max length.
                    "F5(?<F5>[PNIX]{1})" + // We capture the field F5. It can only contain "P", "N", "I" or "X".
                    "F6(?<F6>\\d{12})" +  // We capture the field F6. It can only contain digits.
                    "\\x1F{1}" + // This character is separating the message from its signature.
                    "[A-Z\\d]{103}$" // This is the message signature.
            }
        }
    }
    
}
