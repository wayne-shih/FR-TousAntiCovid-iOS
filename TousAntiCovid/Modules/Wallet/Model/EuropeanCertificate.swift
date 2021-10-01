// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  EuropeanCertificate.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/05/2021 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK
import StorageSDK

final class EuropeanCertificate: WalletCertificate {

    override var message: Data? { nil }
    override var signature: Data? { nil }
    override var isSignatureAlreadyEncoded: Bool { false }
    
    var isEligibleToActivityCertificateGeneration: Bool {
        !isTestCertificateTooOld() && !didGenerateAllActivityCertificates && hCert.exp > Date() && dosesNumber == dosesTotal
    }
    var didGenerateAllActivityCertificates: Bool
    var didAlreadyGenerateActivityCertificates: Bool

    private var fullName: String {
        let first: String? = hCert.get(.firstName).string
        let last: String? = hCert.get(.lastName).string
        return [first, last].compactMap { $0?.trimmingCharacters(in: .whitespaces) } .joined(separator: " ")
    }

    override var timestamp: Double {
        var date: Date?
        switch hCert.type {
        case .vaccine:
            date = hCert.vaccineStatements.first?.date
        case .test:
            date = hCert.testStatements.first?.sampleTime
        case .recovery:
            date = hCert.recoveryStatements.first?.validFrom
        case .exemption:
            date = hCert.exemptionStatement?.validFrom
        case .unknown:
            break
        }
        return (date ?? hCert.iat).timeIntervalSince1970
    }

    override var pillTitles: [(text: String, backgroundColor: UIColor)] {
        var pills: [(String, UIColor)] = [(hCert.certTypeString.trimmingCharacters(in: .whitespaces), Appearance.tintColor)]
        if isExpired { pills.append(("wallet.expired.pillTitle".localized, Asset.Colors.error.color)) }
        return pills
    }
    override var shortDescription: String? { fullName }

    override var fullDescription: String? {
        var strings: [String?] = []
        switch hCert.type {
        case .vaccine:
            strings.append(fullDescriptionVaccination(forceEnglishFormat: false))
        case .test:
            strings.append(fullDescriptionTest(forceEnglishFormat: false))
        case .recovery:
            strings.append(fullDescriptionRecovery(forceEnglishFormat: false))
        case .exemption:
            strings.append(fullDescriptionExemption(forceEnglishFormat: false))
        case .unknown:
            break
        }
        strings.append("wallet.proof.europe.foreignCountryWarning.\(countryCode?.lowercased() ?? "")".localizedOrNil)
        return strings.compactMap { $0 } .joined(separator: "\n\n")
    }

    override var uniqueHash: String { "\(countryCode?.uppercased() ?? "")\(hCert.uvci)".sha256() }
    
    var dosesNumber: Int? { hCert.vaccineStatements.first?.doseNumber }
    var dosesTotal: Int? { hCert.vaccineStatements.first?.dosesTotal }

    var isForeignCertificate: Bool { countryCode != "FR" }
    var isExpired: Bool { hCert.exp.timeIntervalSince1970 < Date().timeIntervalSince1970 }

    override var fullDescriptionForFullscreen: String? {
        switch hCert.type {
        case .vaccine:
            return fullDescriptionVaccination(forceEnglishFormat: true)
        case .test:
            return fullDescriptionTest(forceEnglishFormat: true)
        case .recovery:
            return fullDescriptionRecovery(forceEnglishFormat: true)
        case .exemption:
            return fullDescriptionExemption(forceEnglishFormat: true)
        case .unknown:
            return nil
        }
    }

    var medicalProductCode: String? {
        guard let vaccinationEntry = hCert.vaccineStatements.first else { return nil }
        return vaccinationEntry.medicalProduct.trimmingCharacters(in: .whitespaces)
    }
    
    var isLastDose: Bool? {
        guard let vaccinationEntry = hCert.vaccineStatements.first else { return nil }
        return vaccinationEntry.doseNumber == vaccinationEntry.dosesTotal
    }
    
    var isTestNegative: Bool? {
        hCert.testStatements.first?.resultNegative
    }

    var isAutoTest: Bool {
        hCert.testStatements.first?.manufacturer?.lowercased() == "autotest"
    }

    private let hCert: HCert

    private var countryCode: String? {
        let countryCode: String?
        switch hCert.type {
        case .vaccine:
            countryCode = hCert.vaccineStatements.first?.countryCode
        case .test:
            countryCode = hCert.testStatements.first?.countryCode
        case .recovery:
            countryCode = hCert.recoveryStatements.first?.countryCode
        case .exemption:
            countryCode = hCert.exemptionStatement?.countryCode
        case .unknown:
            countryCode = nil
        }
        return ["NC", "WF", "PM", "PF"].contains(countryCode) ? "FR" : countryCode
    }

    init(id: String, value: String, type: WalletConstant.CertificateType, hCert: HCert, didGenerateAllActivityCertificates: Bool, didAlreadyGenerateActivityCertificates: Bool) {
        self.hCert = hCert
        self.didGenerateAllActivityCertificates = didGenerateAllActivityCertificates
        self.didAlreadyGenerateActivityCertificates = didAlreadyGenerateActivityCertificates
        super.init(id: id, value: value, type: type)
    }

    override func toRawCertificate() -> RawWalletCertificate {
        RawWalletCertificate(id: id, value: value, expiryDate: hCert.exp, parentId: nil, didGenerateAllActivityCertificates: didGenerateAllActivityCertificates, didAlreadyGenerateActivityCertificates: didAlreadyGenerateActivityCertificates)
    }

    private func birthDateString(forceEnglishFormat: Bool) -> String? {
        Date(dateString: hCert.dateOfBirth)?.dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat)
    }

    private func fullDescriptionVaccination(forceEnglishFormat: Bool) -> String? {
        // Still waiting for string format confirmation.
        guard let vaccinationEntry = hCert.vaccineStatements.first else { return nil }
        
        let flag: String? = isForeignCertificate && !forceEnglishFormat ? countryCode?.flag() : nil
        let string: String = forceEnglishFormat ? "europeanCertificate.fullscreen.englishDescription.vaccine" : "wallet.proof.europe.vaccine.description"
        let date: String = vaccinationEntry.date.dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat)
        
        return [flag, string.localized].compactMap { $0 } .joined(separator: " ")
            .replacingOccurrences(of: "<FULL_NAME>", with: fullName)
            .replacingOccurrences(of: "<BIRTHDATE>", with: birthDateString(forceEnglishFormat: forceEnglishFormat) ?? "")
            .replacingOccurrences(of: "<VACCINE_NAME>", with: l10n("vac.product.\(medicalProductCode ?? "")", or: medicalProductCode) )
            .replacingOccurrences(of: "<DATE>", with: date)
    }
    
    private func fullDescriptionTest(forceEnglishFormat: Bool) -> String? {
        // Still waiting for string format confirmation.
        guard let testEntry = hCert.testStatements.first else { return nil }
        let testResultKey: String = isTestNegative == true ? "negative" : "positive"
        let flag: String? = isForeignCertificate && !forceEnglishFormat ? countryCode?.flag() : nil
        let string: String = forceEnglishFormat ? "europeanCertificate.fullscreen.englishDescription.test" : "wallet.proof.europe.test.description"
        let fromDate: String = testEntry.sampleTime.dayShortMonthYearTimeFormatted(forceEnglishFormat: forceEnglishFormat)
        
        return [flag, string.localized].compactMap { $0 } .joined(separator: " ")
            .replacingOccurrences(of: "<FULL_NAME>", with: fullName)
            .replacingOccurrences(of: "<BIRTHDATE>", with: birthDateString(forceEnglishFormat: forceEnglishFormat) ?? "")
            .replacingOccurrences(of: "<ANALYSIS_CODE>", with: l10n("test.man.\(testEntry.type)", or: testEntry.type))
            .replacingOccurrences(of: "<ANALYSIS_RESULT>", with: "wallet.proof.europe.test.\(testResultKey)".localized)
            .replacingOccurrences(of: "<FROM_DATE>", with: fromDate)
            .appending("\n\(validityString)")
    }
    
    private func fullDescriptionRecovery(forceEnglishFormat: Bool) -> String? {
        guard let recoveryEntry = hCert.recoveryStatements.first else { return nil }
        let firstPositiveDate: Date? = Date(dateString: recoveryEntry.firstPositiveDate)
        let flag: String? = isForeignCertificate && !forceEnglishFormat ? countryCode?.flag() : nil
        let string: String = forceEnglishFormat ? "europeanCertificate.fullscreen.englishDescription.recovery" : "wallet.proof.europe.recovery.description"
        let date: String = firstPositiveDate?.dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat) ?? ""
        
        return [flag, string.localized].compactMap { $0 } .joined(separator: " ")
            .replacingOccurrences(of: "<FULL_NAME>", with: fullName)
            .replacingOccurrences(of: "<BIRTHDATE>", with: birthDateString(forceEnglishFormat: forceEnglishFormat) ?? "")
            .replacingOccurrences(of: "<DATE>", with: date)
    }

    private func fullDescriptionExemption(forceEnglishFormat: Bool) -> String? {
        guard let exemptionEntry = hCert.exemptionStatement else { return nil }
        let flag: String? = isForeignCertificate && !forceEnglishFormat ? countryCode?.flag() : nil
        let string: String = forceEnglishFormat ? "europeanCertificate.fullscreen.englishDescription.exemption" : "wallet.proof.europe.exemption.description"
        let dateFromStr: String = exemptionEntry.validFrom.dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat)
        let dateUntilStr: String = exemptionEntry.validUntil.dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat)
        return [flag, string.localized].compactMap { $0 } .joined(separator: " ")
            .replacingOccurrences(of: "<FULL_NAME>", with: fullName)
            .replacingOccurrences(of: "<BIRTHDATE>", with: birthDateString(forceEnglishFormat: forceEnglishFormat) ?? "")
            .replacingOccurrences(of: "<FROM_DATE>", with: dateFromStr)
            .replacingOccurrences(of: "<TO_DATE>", with: dateUntilStr)
    }
    
    private func isTestCertificateTooOld() -> Bool {
        guard hCert.testStatements.first?.resultNegative == true else { return false }
        let durationThresholdForEligiblility: Double = Double(ParametersManager.shared.activityPassSkipNegTestHours) * 3600.0
        return timestamp + durationThresholdForEligiblility < Date().timeIntervalSince1970
    }

}
