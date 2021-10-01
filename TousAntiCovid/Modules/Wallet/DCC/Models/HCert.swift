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
  case exemptionStatement // Needed for France additions.
}

public enum HCertType: String {
  case test
  case vaccine
  case recovery
  case exemption // Needed for France additions.
  case unknown
}

public enum HCertValidity: String {
  case valid
  case invalid
  case ruleInvalid
}

let attributeKeys: [AttributeKey: [String]] = [
  .firstName: ["nam", "gn"],
  .lastName: ["nam", "fn"],
  .firstNameStandardized: ["nam", "gnt"],
  .lastNameStandardized: ["nam", "fnt"],
  .dateOfBirth: ["dob"],
  .testStatements: ["t"],
  .vaccineStatements: ["v"],
  .recoveryStatements: ["r"],
  .exemptionStatement: ["ex"] // Needed for France additions.
]

public enum InfoSectionStyle {
  case normal
  case fixedWidthFont
}

public enum RuleValidationResult: Int {
  case error = 0
  case passed
  case open
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
  public static var supportedPrefixes = [
      "HC1:",
      WalletConstant.DccPrefix.exemptionCertificate.rawValue,
      WalletConstant.DccPrefix.activityCertificate.rawValue
  ]
  
  static func parsePrefix(_ payloadString: String) -> String {
    var payloadString = payloadString
    Self.supportedPrefixes.forEach({ prefix in
      if payloadString.starts(with: prefix) {
        payloadString = String(payloadString.dropFirst(prefix.count))
      }
    })
    return payloadString
  }
  
  static private func checkHC1PrefixExist(_ payloadString: String?) -> Bool {
    guard let payloadString = payloadString  else { return false }
    var foundPrefix = false
    Self.supportedPrefixes.forEach { prefix in
      if payloadString.starts(with: prefix) { foundPrefix = true }
    }
    return foundPrefix
  }
  
  public init?(from payload: String, errors: ParseErrors? = nil) {
    let payload = payload
    if Self.checkHC1PrefixExist(payload) {
      fullPayloadString = payload
      payloadString = Self.parsePrefix(payload)
    } else {
      fullPayloadString = Self.supportedPrefixes.first ?? ""
      fullPayloadString = fullPayloadString + payload
      payloadString = payload
    }
    let prefix: String = fullPayloadString.replacingOccurrences(of: payloadString, with: "")
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
    issCode = body["1"].string ?? ""
    if body[ClaimKey.hCert.rawValue].exists() {
      body = body[ClaimKey.hCert.rawValue]
    }
    if body[ClaimKey.euDgcV1.rawValue].exists() {
      self.body = body[ClaimKey.euDgcV1.rawValue]
      if !parseBodyV1(errors: errors, schema: schema(for: prefix)) {
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

  func schema(for prefix: String) -> String {
      switch prefix {
      case WalletConstant.DccPrefix.exemptionCertificate.rawValue:
          return exemptionDccSchema
      default:
          return euDgcSchemaV1
      }
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
  
  public var fullPayloadString: String
  public var payloadString: String
  public var cborData: Data
  public var kidStr: String
  public var issCode: String
  public var header: SwiftyJSON.JSON
  public var body: SwiftyJSON.JSON
  public var iat: Date
  public var exp: Date
  public var ruleCountryCode: String?
  
  static let qrLock = NSLock()
  
  public var technicalVerification: HCertValidity = .invalid
  public var issuerInvalidation: RuleValidationResult = .error
  public var destinationAcceptence: RuleValidationResult = .error
  public var travalerAcceptence: RuleValidationResult = .error

  public var fullName: String {
    let first = get(.firstName).string ?? ""
    let last = get(.lastName).string ?? ""
    return "\(first) \(last)"
  }
  
  public var dateOfBirth: String {
    let dob = get(.dateOfBirth).string ?? ""
    return "\(dob)"
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
  var exemptionStatement: ExemptionEntry? { ExemptionEntry(body: SwiftyJSON.JSON(get(.exemptionStatement))) }
  var statements: [HCertEntry] {
      testStatements + vaccineStatements + recoveryStatements + [exemptionStatement].compactMap { $0 }
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
    if statement is TestEntry {
      return .test
    }
    if statement is ExemptionEntry {
        return .exemption
    }
    return .unknown
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
      if !X509.isCertificateValid(cert: key) {
        return false
      }
      if X509.checkisSuitable(cert:key,certType:type) {
          if COSE.verify(_cbor: cborData, with: key.cleaningPEMStrings()) {
          return true
        } else {
          return false
        }
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
