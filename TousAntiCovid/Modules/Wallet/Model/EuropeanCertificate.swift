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

final class EuropeanCertificate: WalletCertificate {

    override var message: Data? { nil }
    override var signature: Data? { nil }
    override var isSignatureAlreadyEncoded: Bool { false }

    private var fullName: String { hCert.fullName.uppercased() }
    private var birthDateString: String? {
        guard let dateString = hCert.get(.dateOfBirth).string else { return nil }
        return Date.dateFormatter.date(from: dateString)?.shortDateFormatted() ?? dateString
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
        }
        return (date ?? hCert.iat).timeIntervalSince1970
    }

    override var codeImage: UIImage? { value.qrCode() }
    override var codeImageTitle: String? { nil }

    override var pillTitles: [String] { [hCert.certTypeString.trimmingCharacters(in: .whitespaces)] }
    override var shortDescription: String? { fullName }

    override var fullDescription: String? {
        switch hCert.type {
        case .vaccine:
            return fullDescriptionVaccination
        case .test:
            return fullDescriptionTest
        case .recovery:
            return fullDescriptionRecovery
        }
    }

    private let hCert: HCert

    private var fullDescriptionVaccination: String? {
        // Still waiting for string format confirmation.
        guard let vaccinationEntry = hCert.vaccineStatements.first else { return nil }
        return "wallet.proof.europe.vaccine.description".localized
            .replacingOccurrences(of: "<FULL_NAME>", with: fullName)
            .replacingOccurrences(of: "<BIRTHDATE>", with: birthDateString ?? "")
            .replacingOccurrences(of: "<VACCINE_NAME>", with: l10n("vac.product.\(vaccinationEntry.medicalProduct)", or: vaccinationEntry.medicalProduct) )
            .replacingOccurrences(of: "<DATE>", with: vaccinationEntry.date.shortDateFormatted())
    }

    private var fullDescriptionTest: String? {
        // Still waiting for string format confirmation.
        guard let testEntry = hCert.testStatements.first else { return nil }
        let testResultKey: String = testEntry.resultNegative ? "negative" : "positive"
        return "wallet.proof.europe.test.description".localized
            .replacingOccurrences(of: "<FULL_NAME>", with: fullName)
            .replacingOccurrences(of: "<BIRTHDATE>", with: birthDateString ?? "")
            .replacingOccurrences(of: "<ANALYSIS_CODE>", with: l10n("test.man.\(testEntry.type)", or: testEntry.type))
            .replacingOccurrences(of: "<ANALYSIS_RESULT>", with: "wallet.proof.europe.test.\(testResultKey)".localized)
            .replacingOccurrences(of: "<FROM_DATE>", with: testEntry.sampleTime.shortDateFormatted())
            .appending("\n\(validityString)")
    }

    private var fullDescriptionRecovery: String? {
        // Still waiting for string format confirmation.
        guard let recoveryEntry = hCert.recoveryStatements.first else { return nil }
        return "wallet.proof.europe.recovery.description".localized
            .replacingOccurrences(of: "<FULL_NAME>", with: fullName)
            .replacingOccurrences(of: "<BIRTHDATE>", with: birthDateString ?? "")
            .replacingOccurrences(of: "<FROM_DATE>", with: recoveryEntry.validFrom.shortDateFormatted())
            .replacingOccurrences(of: "<TO_DATE>", with: recoveryEntry.validUntil.shortDateFormatted())
    }

    init(id: String = UUID().uuidString, value: String, type: WalletConstant.CertificateType, hCert: HCert) {
        self.hCert = hCert
        super.init(id: id, value: value, type: type)
    }

}
