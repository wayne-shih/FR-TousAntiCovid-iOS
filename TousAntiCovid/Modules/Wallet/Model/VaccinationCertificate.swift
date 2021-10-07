// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VaccinationCertificate.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 17/03/2021 - for the TousAntiCovid project.
//

import UIKit
import StorageSDK

final class VaccinationCertificate: WalletCertificate {

    enum FieldName: String, CaseIterable {
        case authority
        case certificateId
        case name = "L0"
        case firstName = "L1"
        case birthDate = "L2" // Can be a lunar date.
        case diseaseName = "L3"
        case prophylacticAgent = "L4"
        case vaccineName = "L5"
        case vaccineMaker = "L6"
        case lastVaccinationStateRank = "L7"
        case completeCycleDosesCount = "L8"
        case lastVaccinationDate = "L9"
        case vaccinationCycleState = "LA"
    }
    
    override var message: Data? { value.components(separatedBy: WalletConstant.Separator.unit.ascii).first?.data(using: .ascii) }
    override var signature: Data? {
        guard let signatureString = value.components(separatedBy: WalletConstant.Separator.unit.ascii).last else { return nil }
        do {
            return try signatureString.decodeBase32(padded: signatureString.hasSuffix("="))
        } catch {
            return nil
        }
    }
    override var isSignatureAlreadyEncoded: Bool { false }
    
    var firstName: String? { fields[FieldName.firstName.rawValue]?.replacingOccurrences(of: "/", with: ",") }
    var name: String? { fields[FieldName.name.rawValue] }
    var birthDateString: String?

    var diseaseName: String? { fields[FieldName.diseaseName.rawValue] }
    var prophylacticAgent: String? { fields[FieldName.prophylacticAgent.rawValue] }
    var vaccineName: String? { fields[FieldName.vaccineName.rawValue] }
    var vaccineMaker: String? { fields[FieldName.vaccineMaker.rawValue] }
    var lastVaccinationStateRank: String? { fields[FieldName.lastVaccinationStateRank.rawValue] }
    var completeCycleDosesCount: String? { fields[FieldName.completeCycleDosesCount.rawValue] }
    
    var lastVaccinationDate: Date?
    var lastVaccinationDateString: String? { parse2DDocDateString(dateString: fields[FieldName.lastVaccinationDate.rawValue]) }

    var vaccinationCycleState: String? {
        guard let cycleState = fields[FieldName.vaccinationCycleState.rawValue] else { return nil }
        return "wallet.proof.vaccinationCertificate.\(FieldName.vaccinationCycleState.rawValue).\(cycleState)".localizedOrNil ?? cycleState
    }
    
    override var timestamp: Double { lastVaccinationDate?.timeIntervalSince1970 ?? 0.0 }


    override var pillTitles: [(text: String, backgroundColor: UIColor)] {
        ["wallet.proof.vaccinationCertificate.pillTitle".localized, vaccinationCycleState].compactMap {
            guard let string = $0 else { return nil }
            return (string, Appearance.tintColor)
        }
    }
    override var shortDescription: String? { [firstName, name].compactMap { $0 }.joined(separator: " ") }
    override var fullDescription: String? {
        var text: String = "wallet.proof.vaccinationCertificate.description".localized
        text = text.replacingOccurrences(of: "<\(FieldName.name.rawValue)>", with: firstName ?? "N/A")
        text = text.replacingOccurrences(of: "<\(FieldName.firstName.rawValue)>", with: name ?? "N/A")
        text = text.replacingOccurrences(of: "<\(FieldName.birthDate.rawValue)>", with: birthDateString ?? "N/A")
        text = text.replacingOccurrences(of: "<\(FieldName.diseaseName.rawValue)>", with: diseaseName ?? "N/A")
        text = text.replacingOccurrences(of: "<\(FieldName.prophylacticAgent.rawValue)>", with: prophylacticAgent ?? "N/A")
        text = text.replacingOccurrences(of: "<\(FieldName.vaccineName.rawValue)>", with: vaccineName ?? "N/A")
        text = text.replacingOccurrences(of: "<\(FieldName.vaccineMaker.rawValue)>", with: vaccineMaker ?? "N/A")
        text = text.replacingOccurrences(of: "<\(FieldName.lastVaccinationStateRank.rawValue)>", with: lastVaccinationStateRank ?? "N/A")
        text = text.replacingOccurrences(of: "<\(FieldName.completeCycleDosesCount.rawValue)>", with: completeCycleDosesCount ?? "N/A")
        text = text.replacingOccurrences(of: "<\(FieldName.lastVaccinationDate.rawValue)>", with: lastVaccinationDateString ?? "N/A")
        text = text.replacingOccurrences(of: "<\(FieldName.vaccinationCycleState.rawValue)>", with: vaccinationCycleState ?? "N/A")
        return text
    }
    
    override init(id: String = UUID().uuidString, value: String, type: WalletConstant.CertificateType) {
        super.init(id: id, value: value, type: type)
        self.fields = parse(value)
        self.birthDateString = parse2DDocDateString(dateString: fields[FieldName.birthDate.rawValue])
        self.lastVaccinationDate = parseLastVaccinationDate()
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
    
    private func parse2DDocDateString(dateString: String?) -> String? {
        guard let dateString = dateString, dateString.count == 8 else { return nil }
        let dayString: String = dateString[0...1]
        let monthString: String = dateString[2...3]
        let yearString: String = dateString[4...7]
        return "\(dayString)/\(monthString)/\(yearString)"
    }
    
    private func parseLastVaccinationDate() -> Date? {
        guard let analysisDateString = fields[FieldName.lastVaccinationDate.rawValue], analysisDateString.count == 8 else { return nil }
        let dayString: String = analysisDateString[0...1]
        let monthString: String = analysisDateString[2...3]
        let yearString: String = analysisDateString[4...7]
        let dateComponents: DateComponents = DateComponents(year: Int(yearString), month: Int(monthString), day: Int(dayString))
        return Calendar.current.date(from: dateComponents)
    }

}
