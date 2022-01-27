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

final class EuropeanCertificate: WalletCertificate, Equatable, Hashable {

    override var message: Data? { nil }
    override var signature: Data? { nil }
    override var isSignatureAlreadyEncoded: Bool { false }
    
    var isEligibleToActivityCertificateGeneration: Bool {
        !isTestCertificateTooOld() && !didGenerateAllActivityCertificates && hCert.exp > Date() && dosesNumber == dosesTotal
    }
    var didGenerateAllActivityCertificates: Bool
    var didAlreadyGenerateActivityCertificates: Bool
    
    var fullName: String {
        [firstname, lastname].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.joined(separator: " ")
    }
    
    static func == (lhs: EuropeanCertificate, rhs: EuropeanCertificate) -> Bool {
        lhs.uniqueHash == rhs.uniqueHash
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueHash)
    }
    
    override var isOld: Bool {
        let parentIsOld: Bool = super.isOld
        return parentIsOld || isExpired
    }

    override var timestamp: Double {
        var date: Date?
        switch hCert.type {
        case .vaccine:
            date = hCert.vaccineStatements.first?.date
        case .test:
            date = hCert.testStatements.first?.sampleTime
        case .recovery:
            date = Date(dateString: hCert.recoveryStatements.first?.firstPositiveDate ?? "")
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
    
    override var title: String? {
        let flag: String? = isForeignCertificate ? countryCode?.flag() : nil
        switch hCert.type {
        case .vaccine:
            return [flag, "wallet.proof.europe.vaccine.title".localized].compactMap { $0 }.joined(separator: " ")
        case .test:
            return [flag, "wallet.proof.europe.test.title".localized].compactMap { $0 }.joined(separator: " ")
        case .recovery:
            return [flag, "wallet.proof.europe.recovery.title".localized].compactMap { $0 }.joined(separator: " ")
        case .exemption:
            return [flag, "wallet.proof.europe.exemption.title".localized].compactMap { $0 }.joined(separator: " ")
        case .unknown:
            return nil
        }
    }
    
    override var shortDescriptionForList: String? {
        return [smiley, fullName].compactMap { $0 }.joined(separator: " ")
    }
    
    override var shortDescription: String? { fullName }
    
    lazy var smiley: String? = {
        guard let dccKids = ParametersManager.shared.dccKids, userAge <= dccKids.age else { return nil }
        let emojiIdx: Int = (hCert.dateOfBirth + fullName).androidCommonHash() % dccKids.smileys.count
        return dccKids.smileys[emojiIdx]
    }()
    
    var smartWalletProfileId: String { (firstname ?? lastname ?? "").uppercased() + hCert.dateOfBirth }
    
    var multiPassProfileId: String {
        (hCert.get(.firstNameStandardized).string.orEmpty + hCert.get(.lastNameStandardized).string.orEmpty)
        .replacingOccurrences(of: "[^a-zA-Z]*", with: "", options: [.regularExpression])
        .trimmingCharacters(in: .whitespaces)
        .uppercased() +
        hCert.dateOfBirth
    }

    override var fullDescription: String? {
        var strings: [String?] = []
        switch hCert.type {
        case .vaccine:
            strings.append(fullDescriptionVaccination())
        case .test:
            strings.append(fullDescriptionTest(forceEnglishFormat: false))
        case .recovery:
            strings.append(fullDescriptionRecovery(forceEnglishFormat: false))
        case .exemption:
            strings.append(fullDescriptionExemption(forceEnglishFormat: false))
        case .unknown:
            break
        }
        return strings.compactMap { $0 } .joined(separator: "\n\n")
    }

    override var uniqueHash: String { "\(countryCode?.uppercased() ?? "")\(hCert.uvci)".sha256() }
    
    var dosesNumber: Int? { hCert.vaccineStatements.first?.doseNumber }
    var dosesTotal: Int? { hCert.vaccineStatements.first?.dosesTotal }

    var isForeignCertificate: Bool { countryCode != "FR" }
    var isExpired: Bool {
        switch hCert.type {
        case .exemption:
            return (hCert.exemptionStatement?.validUntil ?? .distantPast).timeIntervalSince1970 < Date().timeIntervalSince1970
        default:
            return hCert.exp.timeIntervalSince1970 < Date().timeIntervalSince1970
        }
    }
    var kid: String { hCert.kidStr }
    var isEphemere: Bool { parentId != nil }

    override var fullDescriptionForFullscreen: String? {
        switch hCert.type {
        case .vaccine:
            return borderDescriptionVaccination()
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
    
    var vaccineType: WalletConstant.VaccineType? {
        guard let medicalProductCode = medicalProductCode else { return nil }
        var vaccineType: WalletConstant.VaccineType?
        WalletConstant.VaccineType.allCases.forEach { type in
            if type.stringValues.contains(medicalProductCode) { vaccineType = type }
        }
        return vaccineType
    }
    
    var medicalProductCode: String? {
        guard let vaccinationEntry = hCert.vaccineStatements.first else { return nil }
        return vaccinationEntry.medicalProduct.trimmingCharacters(in: .whitespaces)
    }
        
    var firstname: String? { hCert.get(.firstName).string ?? hCert.get(.firstNameStandardized).string }
    var lastname: String? { hCert.get(.lastName).string ?? hCert.get(.lastNameStandardized).string }
    var birthdate: Double { Date(dateString: hCert.dateOfBirth)?.timeIntervalSince1970 ?? Date().timeIntervalSince1970 }
    var hasLunarBirthdate: Bool { hCert.dateOfBirth.isLunarDate }

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
    
    override func getAdditionalInfo() -> [AdditionalInfo] {
        var info: [AdditionalInfo] = super.getAdditionalInfo()
        if let foreignWarning = "wallet.proof.europe.foreignCountryWarning.\(countryCode?.lowercased() ?? "")".localizedOrNil {
            info.append(AdditionalInfo(category: .info, fullDescription: foreignWarning))
        }
        if isTestNegative == false && type == .sanitaryEurope {
            info.append(AdditionalInfo(category: .warning, fullDescription: "wallet.proof.europe.test.positiveSidepError".localized))
        }
        if isAutoTest {
            info.append(AdditionalInfo(category: .warning, fullDescription: "wallet.autotest.warning".localized))
        }
        return info
    }

    private func birthDateString(forceEnglishFormat: Bool) -> String? {
        Date(dateString: hCert.dateOfBirth)?.dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat)
    }

    private func fullDescriptionVaccination() -> String? {
        // Still waiting for string format confirmation.
        guard let vaccinationEntry = hCert.vaccineStatements.first else { return nil }
        
        let info: String = "wallet.proof.europe.vaccine.infos"
        let date: String = vaccinationEntry.date.dayShortMonthYearFormatted(timeZoneIndependant: true)
        return info.localized
            .replacingOccurrences(of: "<BIRTHDATE>", with: birthDateString(forceEnglishFormat: false) ?? "")
            .replacingOccurrences(of: "<VACCINE_NAME>", with: l10n("vac.product.\(medicalProductCode ?? "")", or: medicalProductCode))
            .replacingOccurrences(of: "<DATE>", with: date)
    }
    
    private func borderDescriptionVaccination() -> String? {
        // Still waiting for string format confirmation.
        guard let vaccinationEntry = hCert.vaccineStatements.first else { return nil }
        
        let flag: String? = isForeignCertificate ? countryCode?.flag() : nil
        let info: String = "europeanCertificate.fullscreen.englishDescription.vaccine"
        let date: String = vaccinationEntry.date.dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: true)
        return [flag, info.localized].compactMap { $0 }.joined(separator: " ")
            .replacingOccurrences(of: "<FULL_NAME>", with: fullName)
            .replacingOccurrences(of: "<BIRTHDATE>", with: birthDateString(forceEnglishFormat: true) ?? "")
            .replacingOccurrences(of: "<VACCINE_NAME>", with: l10n("vac.product.\(medicalProductCode ?? "")", or: medicalProductCode))
            .replacingOccurrences(of: "<VACCINE_DOSES>", with: "\(hCert.vaccineStatements.first?.doseNumber ?? 0)/\(hCert.vaccineStatements.first?.dosesTotal ?? 0)")
            .replacingOccurrences(of: "<DATE>", with: date)
    }
    
    private func fullDescriptionTest(forceEnglishFormat: Bool) -> String? {
        guard let testEntry = hCert.testStatements.first else { return nil }
        let testResultKey: String = isTestNegative == true ? "negative" : "positive"
        let flag: String? = isForeignCertificate && forceEnglishFormat ? countryCode?.flag() : nil
        let info: String = forceEnglishFormat ? "europeanCertificate.fullscreen.englishDescription.test" : "wallet.proof.europe.test.infos"
        let sampleTimeDate: Date = testEntry.sampleTime
        let date: String = sampleTimeDate.dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat)
        let result: String = forceEnglishFormat ? "wallet.proof.europe.test.englishDescription.\(testResultKey)".localized : "wallet.proof.europe.test.\(testResultKey)".localized
        let analysisCode: String = forceEnglishFormat ? l10n("test.man.englishDescription.\(testEntry.type)", or: testEntry.type) : l10n("test.man.\(testEntry.type)", or: testEntry.type)
        let timestamp: Double = sampleTimeDate.timeIntervalSince1970
        let fromDate: String = Date(timeIntervalSince1970: timestamp + ParametersManager.shared.walletRecoveryValidityThresholdInDays.minSec).dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat)
        let toDate: String = Date(timeIntervalSince1970: timestamp + ParametersManager.shared.walletRecoveryValidityThresholdInDays.maxSec).dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat)
        
        if isTestNegative == false, !forceEnglishFormat {
            return [flag, "wallet.proof.europe.testPositive.infos".localized].compactMap { $0 } .joined(separator: " ")
                .replacingOccurrences(of: "<BIRTHDATE>", with: birthDateString(forceEnglishFormat: forceEnglishFormat) ?? "")
                .replacingOccurrences(of: "<DATE>", with: date)
                .replacingOccurrences(of: "<FROM_DATE>", with: fromDate)
                .replacingOccurrences(of: "<TO_DATE>", with: toDate)
        } else {
            return [flag, info.localized].compactMap { $0 } .joined(separator: " ")
                .replacingOccurrences(of: "<FULL_NAME>", with: fullName)
                .replacingOccurrences(of: "<BIRTHDATE>", with: birthDateString(forceEnglishFormat: forceEnglishFormat) ?? "")
                .replacingOccurrences(of: "<ANALYSIS_CODE>", with: analysisCode)
                .replacingOccurrences(of: "<ANALYSIS_RESULT>", with: result)
                .replacingOccurrences(of: "<FROM_DATE>", with: date)
                .appending("\n\(validityString(forceEnglish: forceEnglishFormat))")
        }
    }
    
    private func fullDescriptionRecovery(forceEnglishFormat: Bool) -> String? {
        guard let recoveryEntry = hCert.recoveryStatements.first else { return nil }
        let firstPositiveDate: Date? = Date(dateString: recoveryEntry.firstPositiveDate)
        let flag: String? = isForeignCertificate && forceEnglishFormat ? countryCode?.flag() : nil
        let info: String = forceEnglishFormat ? "europeanCertificate.fullscreen.englishDescription.recovery" : "wallet.proof.europe.recovery.infos"
        let date: String = firstPositiveDate?.dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat) ?? ""
        let timestamp: Double = firstPositiveDate?.timeIntervalSince1970 ?? 0.0
        let fromDate: String = Date(timeIntervalSince1970: timestamp + ParametersManager.shared.walletRecoveryValidityThresholdInDays.minSec).dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat)
        let toDate: String = Date(timeIntervalSince1970: timestamp + ParametersManager.shared.walletRecoveryValidityThresholdInDays.maxSec).dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat)
        
        if forceEnglishFormat {
            return [flag, info.localized].compactMap { $0 } .joined(separator: " ")
                        .replacingOccurrences(of: "<FULL_NAME>", with: fullName)
                        .replacingOccurrences(of: "<BIRTHDATE>", with: birthDateString(forceEnglishFormat: forceEnglishFormat) ?? "")
                        .replacingOccurrences(of: "<DATE>", with: date)
        } else {
            return [flag, info.localized].compactMap { $0 } .joined(separator: " ")
                .replacingOccurrences(of: "<BIRTHDATE>", with: birthDateString(forceEnglishFormat: forceEnglishFormat) ?? "")
                .replacingOccurrences(of: "<DATE>", with: date)
                .replacingOccurrences(of: "<FROM_DATE>", with: fromDate)
                .replacingOccurrences(of: "<TO_DATE>", with: toDate)
        }
    }

    private func fullDescriptionExemption(forceEnglishFormat: Bool) -> String? {
        guard let exemptionEntry = hCert.exemptionStatement else { return nil }
        let flag: String? = isForeignCertificate && forceEnglishFormat ? countryCode?.flag() : nil
        let info: String = forceEnglishFormat ? "europeanCertificate.fullscreen.englishDescription.exemption" : "wallet.proof.europe.exemption.infos"
        let dateFromStr: String = exemptionEntry.validFrom.dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat)
        let dateUntilStr: String = exemptionEntry.validUntil.dayShortMonthYearFormatted(timeZoneIndependant: true, forceEnglishFormat: forceEnglishFormat)
        return [flag, info.localized].compactMap { $0 } .joined(separator: " ")
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
