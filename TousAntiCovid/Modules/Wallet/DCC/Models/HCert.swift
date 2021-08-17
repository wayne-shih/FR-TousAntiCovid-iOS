/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-app-core-ios
 * ---
 * Copyright (C) 2021 T-Systems International GmbH and all other contributors
 * ---
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ---license-end
 */
//
//  HCert.swift
//
//
//  Created by Yannick Spreen on 4/19/21.
//

import Foundation
import SwiftyJSON

enum ClaimKey: String {
    case hCert = "-260"
    case euDgcV1 = "1"
}

enum AttributeKey: String {
    case firstName
    case lastName
    case firstNameStandardized
    case lastNameStandardized
    case gender
    case dateOfBirth
    case testStatements
    case vaccineStatements
    case recoveryStatements
}

public enum HCertType: String {
    case test
    case vaccine
    case recovery
}

public enum HCertValidity: String {
    case valid
    case invalid
}

let attributeKeys: [AttributeKey: [String]] = [
    .firstName: ["nam", "gn"],
    .lastName: ["nam", "fn"],
    .firstNameStandardized: ["nam", "gnt"],
    .lastNameStandardized: ["nam", "fnt"],
    .dateOfBirth: ["dob"],
    .testStatements: ["t"],
    .vaccineStatements: ["v"],
    .recoveryStatements: ["r"]
]

public enum InfoSectionStyle {
    case normal
    case fixedWidthFont
}

public struct HCertConfig {
    public var prefetchAllCodes = false
    public var checkSignatures = true
}

public struct HCert {
    public enum ParseError {
        case base45
        case prefix
        case zlib
        case cbor
        case json(error: String)
        case version
    }
    public class ParseErrors {
        var errors: [ParseError] = []
    }

    public static var debugPrintJsonErrors = true
    public static var config = HCertConfig()
    public static var publicKeyStorageDelegate: PublicKeyStorageDelegate?
    public static let supportedPrefixes = [
        "HC1:"
    ]

    static func parsePrefix(_ payloadString: String, errors: ParseErrors?) -> String {
        var payloadString = payloadString
        var foundPrefix = false
        for prefix in Self.supportedPrefixes {
            if payloadString.starts(with: prefix) {
                payloadString = String(payloadString.dropFirst(prefix.count))
                foundPrefix = true
                break
            }
        }
        if !foundPrefix {
            errors?.errors.append(.prefix)
        }
        return payloadString
    }

    public init?(from payload: String, errors: ParseErrors? = nil) {
        payloadString = Self.parsePrefix(payload, errors: errors)

        guard
            let compressed = try? payloadString.fromBase45()
        else {
            errors?.errors.append(.base45)
            return nil
        }

        cborData = decompress(compressed)
        if cborData.isEmpty {
            errors?.errors.append(.zlib)
        }
        guard
            let headerStr = CBOR.header(from: cborData)?.toString(),
            let bodyStr = CBOR.payload(from: cborData)?.toString(),
            let kid = CBOR.kid(from: cborData)
        else {
            errors?.errors.append(.cbor)
            return nil
        }
        kidStr = KID.string(from: kid)
        header = SwiftyJSON.JSON(parseJSON: headerStr)
        var body = SwiftyJSON.JSON(parseJSON: bodyStr)
        iat = Date(timeIntervalSince1970: Double(body["6"].int ?? 0))
        exp = Date(timeIntervalSince1970: Double(body["4"].int ?? 0))
        if body[ClaimKey.hCert.rawValue].exists() {
            body = body[ClaimKey.hCert.rawValue]
        }
        if body[ClaimKey.euDgcV1.rawValue].exists() {
            self.body = body[ClaimKey.euDgcV1.rawValue]
            if !parseBodyV1(errors: errors) {
                return nil
            }
        } else {
            print("Wrong EU_DGC Version!")
            errors?.errors.append(.version)
            return nil
        }
        findValidity()

        #if os(iOS)
        if Self.config.prefetchAllCodes {
            prefetchCode()
        }
        #endif
    }

    mutating func findValidity() {
        validityFailures = []
        if !cryptographicallyValid {
            validityFailures.append(l10n("hcert.err.crypto"))
        }
        if exp < HCert.clock {
            validityFailures.append(l10n("hcert.err.exp"))
        }
        if iat > HCert.clock {
            validityFailures.append(l10n("hcert.err.iat"))
        }
        if statement == nil {
            return validityFailures.append(l10n("hcert.err.empty"))
        }
        validityFailures.append(contentsOf: statement.validityFailures)
    }

    func get(_ attribute: AttributeKey) -> SwiftyJSON.JSON {
        var object = body
        for key in attributeKeys[attribute] ?? [] {
            object = object[key]
        }
        return object
    }

    public var certTypeString: String {
        type.l10n + (statement == nil ? "" : " \(statement.typeAddon)")
    }

    public var payloadString: String
    public var cborData: Data
    public var kidStr: String
    public var header: SwiftyJSON.JSON
    public var body: SwiftyJSON.JSON
    public var iat: Date
    public var exp: Date

    static let qrLock = NSLock()

    public var fullName: String {
        let first = get(.firstName).string ?? ""
        let last = get(.lastName).string ?? ""
        return "\(first) \(last)"
    }

    public var dateOfBirth: Date? {
        guard let dateString = get(.dateOfBirth).string else {
            return nil
        }
        return Date(dateString: dateString)
    }

    var testStatements: [TestEntry] {
        return get(.testStatements)
            .array?
            .compactMap {
                TestEntry(body: $0)
            } ?? []
    }
    var vaccineStatements: [VaccinationEntry] {
        return get(.vaccineStatements)
            .array?
            .compactMap {
                VaccinationEntry(body: $0)
            } ?? []
    }
    var recoveryStatements: [RecoveryEntry] {
        return get(.recoveryStatements)
            .array?
            .compactMap {
                RecoveryEntry(body: $0)
            } ?? []
    }
    var statements: [HCertEntry] {
        testStatements + vaccineStatements + recoveryStatements
    }
    public var statement: HCertEntry! {
        statements.last
    }
    public var type: HCertType {
        if statement is VaccinationEntry {
            return .vaccine
        }
        if statement is RecoveryEntry {
            return .recovery
        }
        return .test
    }
    public var validityFailures = [String]()
    public var isValid: Bool {
        validityFailures.isEmpty
    }
    public var cryptographicallyValid: Bool {
        if !Self.config.checkSignatures {
            return true
        }
        guard
            let delegate = Self.publicKeyStorageDelegate
        else {
            return false
        }
        for key in delegate.getEncodedPublicKeys(for: kidStr) {
            if COSE.verify(_cbor: cborData, with: key) {
                return true
            }
        }
        return false
    }
    public var validity: HCertValidity {
        return isValid ? .valid : .invalid
    }
    public var certHash: String {
        CBOR.hash(from: cborData)
    }
    public var uvci: String {
        statement?.uvci ?? "empty"
    }
    public var keyPair: SecKey! {
        Enclave.loadOrGenerateKey(with: uvci)
    }

    public static var clock: Date {
        clockOverride ?? Date()
    }
    public static var clockOverride: Date?
}