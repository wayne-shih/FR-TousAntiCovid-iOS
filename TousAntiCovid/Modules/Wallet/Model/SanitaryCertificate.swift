// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SanitaryCertificate.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 17/03/2021 - for the TousAntiCovid project.
//

import StorageSDK
import UIKit

final class SanitaryCertificate: WalletCertificate {

    enum FieldName: String, CaseIterable {
        case authority
        case certificateId
        case firstName = "F0"
        case name = "F1"
        case birthDate = "F2"
        case gender = "F3"
        case analysisCode = "F4"
        case analysisResult = "F5"
        case analysisDate = "F6"
    }

    override var message: Data? { value.components(separatedBy: WalletConstant.Separator.unit.ascii).first?.data(using: .ascii) }
    override var signature: Data? {
        guard let signatureString = value.components(separatedBy: WalletConstant.Separator.unit.ascii).last else { return nil }
        do {
            return try signatureString.decodeBase32(padded: signatureString.hasSuffix("="))
        } catch {
            print(error)
            return nil
        }
    }
    override var isSignatureAlreadyEncoded: Bool { false }

    var firstName: String? { fields[FieldName.firstName.rawValue]?.replacingOccurrences(of: "/", with: ",") }
    var name: String? { fields[FieldName.name.rawValue] }
    var birthDateString: String?
    var gender: String? {
        guard let gender = fields[FieldName.gender.rawValue] else { return nil }
        return "wallet.proof.sanitaryCertificate.\(FieldName.gender.rawValue).\(gender)".localized
    }
    var analysisDate: Date?
    var analysisDateString: String? { analysisDate?.dayShortMonthYearTimeFormatted() }
    var analysisRawCode: String? { fields[FieldName.analysisCode.rawValue] }
    var analysisCode: String? {
        guard let code = fields[FieldName.analysisCode.rawValue] else { return nil }
        guard let codeDisplayString: String = "wallet.proof.sanitaryCertificate.loinc.\(code)".localizedOrNil else { return "LOINC: \(code)" }
        return String(format: codeDisplayString, code)
    }
    var analysisResult: String? {
        guard let result = fields[FieldName.analysisResult.rawValue] else { return nil }
        return "wallet.proof.sanitaryCertificate.\(FieldName.analysisResult.rawValue).\(result)".localized
    }

    override var timestamp: Double { analysisDate?.timeIntervalSince1970 ?? 0.0 }

    override var title: String? { "wallet.proof.sanitaryCertificate.title".localized }    
    override var pillTitles: [(text: String, backgroundColor: UIColor)] { [("wallet.proof.sanitaryCertificate.pillTitle".localized, Appearance.tintColor)] }
    override var shortDescription: String? { [firstName, name].compactMap { $0 }.joined(separator: " ") }
    override var fullDescription: String? {
        var text: String = "wallet.proof.sanitaryCertificate.infos".localized
        text = text.replacingOccurrences(of: "<\(FieldName.birthDate.rawValue)>", with: birthDateString ?? "N/A")
        text = text.replacingOccurrences(of: "<\(FieldName.gender.rawValue)>", with: gender ?? "N/A")
        text = text.replacingOccurrences(of: "<\(FieldName.analysisCode.rawValue)>", with: analysisCode ?? "N/A")
        text = text.replacingOccurrences(of: "<\(FieldName.analysisDate.rawValue)>", with: analysisDateString ?? "N/A")
        text = text.replacingOccurrences(of: "<\(FieldName.analysisResult.rawValue)>", with: analysisResult ?? "N/A")
        
        text += "\n"
        text += validityString(forceEnglish: false)
        
        return text
    }
    
    override init(id: String = UUID().uuidString, value: String, type: WalletConstant.CertificateType) {
        super.init(id: id, value: value, type: type)
        self.fields = parse(value)
        self.birthDateString = parseBirthDate()
        self.analysisDate = parseAnalysisDate()
    }

    func parse(_ value: String) -> [String: String] {
        var captures: [String: String] = [:]
        guard let regex = try? NSRegularExpression(pattern: type.validationRegex) else { return captures }
        let matches: [NSTextCheckingResult] = regex.matches(in: value, options: [], range: NSRange(location: 0, length: value.count))
        guard let match = matches.first else { return captures }
        
        FieldName.allCases.forEach {
            let matchRange: NSRange = match.range(withName: $0.rawValue)
            guard let substringRange = Range(matchRange, in: value) else { return }
            let capture = String(value[substringRange])
            switch $0 {
            case .authority:
                authority = capture
            case .certificateId:
                certificateId = capture
            default:
                captures[$0.rawValue] = capture
            }
        }
        
        return captures
    }
    
    private func parseBirthDate() -> String? {
        guard let birthDateString = fields[FieldName.birthDate.rawValue], birthDateString.count == 8 else { return nil }
        let dayString: String = birthDateString[0...1]
        let monthString: String = birthDateString[2...3]
        let yearString: String = birthDateString[4...7]
        return "\(dayString)/\(monthString)/\(yearString)"
    }
    
    private func parseAnalysisDate() -> Date? {
        guard let analysisDateString = fields[FieldName.analysisDate.rawValue], analysisDateString.count == 12 else { return nil }
        let dayString: String = analysisDateString[0...1]
        let monthString: String = analysisDateString[2...3]
        let yearString: String = analysisDateString[4...7]
        let hourString: String = analysisDateString[8...9]
        let minuteString: String = analysisDateString[10...11]
        let dateComponents: DateComponents = DateComponents(year: Int(yearString), month: Int(monthString), day: Int(dayString), hour: Int(hourString), minute: Int(minuteString))
        return Calendar.current.date(from: dateComponents)
    }

}
