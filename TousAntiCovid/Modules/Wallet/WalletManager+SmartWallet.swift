// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletManager+SmartWallet.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/11/2021 - for the TousAntiCovid project.
//

import ServerSDK

// MARK: - ELG and EXP management
extension WalletManager {
    enum WalletState: Int {
        case normal
        case eligibleSoon // At least one certificate associated to a user will be eligible soon
        case eligible // At least one certificate associated to a user is eligible to vaccination
        case expiredSoon // At least one certificate associated to a user will expire soon
        case expired // At least one certificate associated to a user is expired
        
        var severity: Int { rawValue }
    }
    
    var shouldUseSmartWallet: Bool { ParametersManager.shared.smartWalletFeatureActivated && smartWalletActivated }
    var shouldUseSmartWalletNotifications: Bool { shouldUseSmartWallet && ParametersManager.shared.smartWalletNotificationsActivated }
    var smartConfig: SmartWalletConfig { ParametersManager.shared.smartWalletConfiguration }
    
    var walletSmartState: WalletState {
        var states: [WalletState] = [.normal]
        lastRelevantCertificates?.forEach { certificate in
            if isPassExpired(for: certificate) {
                states.append(.expired)
            } else if isPassExpiredSoon(for: certificate) {
                states.append(.expiredSoon)
            } else if isEligibleToVaccination(for: certificate) {
                states.append(.eligible)
            } else if isEligibleToVaccinationSoon(for: certificate) {
                states.append(.eligibleSoon)
            }
        }
        return Set<WalletState>(states).sorted(by: { $0.severity > $1.severity })[0] // Array has at least one element (.normal)
    }
    
    func expiryTimestamp(_ certificate: EuropeanCertificate?) -> Double? {
        guard let certificate = certificate else { return nil }
        // Calculate only on completed vaccins, recovery, positive tests
        guard (certificate.isLastDose == true || certificate.type == .recoveryEurope || certificate.isTestNegative == false) && !certificate.isExpired else { return nil }
        // Calculate only if ageLow+
        guard certificate.userAge >= smartConfig.ages.low else { return nil }
        
        let expDate: Double?
        let expDcc: Double?
        
        // Pivot dates
        let datePivot1: Double = (smartConfig.exp.pivot1Date ?? Date()).timeIntervalSince1970
        let datePivot2: Double = (smartConfig.exp.pivot2Date ?? Date()).timeIntervalSince1970
        let datePivot3: Double = (smartConfig.exp.pivot3Date ?? Date()).timeIntervalSince1970
        let agePivotLow: Double = certificate.userBirthdayTimestamp(for: smartConfig.ages.low) + smartConfig.ages.lowExpDays.daysToSeconds() // 18 years + 5 months
        
        // Cutoffs
        let cutoff: Double = max(datePivot1, min(certificate.userBirthdayTimestamp(for: smartConfig.ages.high), datePivot2))
        let cutoffJanssen: Double = datePivot1 // exception on Janssen
        
        // Expiration DCC
        switch certificate.type {
        case .vaccinationEurope:
            guard let type = certificate.vaccineType else { return nil }
            guard certificate.isLastDose == true else { return nil }
            switch type {
            case .janssen:
                expDcc = max(cutoffJanssen, certificate.alignedTimestamp + smartConfig.exp.vaccJan11DosesNbDays.daysToSeconds())
            default:
                if certificate.dosesTotal == 1 {
                    expDcc = [cutoff,
                              min(datePivot3, certificate.alignedTimestamp + smartConfig.exp.vacc11DosesNbDays.daysToSeconds()),
                              certificate.alignedTimestamp + smartConfig.exp.vacc11DosesNbNewDays.daysToSeconds()].max()
                } else if certificate.dosesTotal == 2 {
                    expDcc = [cutoff,
                              min(datePivot3, certificate.alignedTimestamp + smartConfig.exp.vacc22DosesNbDays.daysToSeconds()),
                              certificate.alignedTimestamp + smartConfig.exp.vacc22DosesNbNewDays.daysToSeconds()].max()
                } else {
                    expDcc = nil
                }
            }
        case .recoveryEurope, .sanitaryEurope:
            expDcc = max(cutoff, certificate.alignedTimestamp + smartConfig.exp.recNbDays.daysToSeconds())
        default:
            expDcc = nil
        }
        
        // Expiration Date
        if let expirationDcc = expDcc {
            expDate = Date(timeIntervalSince1970: max(agePivotLow, expirationDcc)).roundingToMidnightPastOne().timeIntervalSince1970
        } else {
            expDate = nil
        }
        
        return expDate
    }
    
    func eligibilityTimestamp(_ certificate: EuropeanCertificate?) -> Double? {
        guard let certificate = certificate else { return nil }
        // Calculate only on completed vaccins, recovery, positive tests
        guard (certificate.isLastDose == true || certificate.type == .recoveryEurope || certificate.isTestNegative == false) && !certificate.isExpired else { return nil }
        // Calculate only if ageLow+
        guard certificate.userAge >= smartConfig.ages.low else { return nil }
        
        let elgDate: Double?
        let elgDcc: Double?
        
        // Eligibility DCC
        switch certificate.type {
        case .vaccinationEurope:
            // Is vaccination certificate completed ?
            guard certificate.isLastDose == true else { return nil }
            guard let type = certificate.vaccineType else { return nil }
            switch type {
            case .janssen: elgDcc = certificate.alignedTimestamp + smartConfig.elg.vaccJan11DosesNbDays.daysToSeconds()
            default:
                if (certificate.dosesNumber ?? 0) < WalletConstant.vaccinBoosterDoseNumber {
                    elgDcc = certificate.alignedTimestamp + smartConfig.elg.vacc22DosesNbDays.daysToSeconds()
                } else {
                    elgDcc = nil
                }
            }
        case .recoveryEurope, .sanitaryEurope:
            elgDcc = certificate.alignedTimestamp + smartConfig.elg.recNbDays.daysToSeconds()
        default:
            elgDcc = nil
        }
        
        // Eligibility Date
        if let eligibilityDcc = elgDcc {
            elgDate = Date(timeIntervalSince1970: max(certificate.userBirthdayTimestamp(for: smartConfig.ages.low), eligibilityDcc)).roundingToMidnightPastOne().timeIntervalSince1970
        } else {
            elgDate = nil
        }
        
        return elgDate
    }
    
    func isRelevantCertificate(_ certificate: EuropeanCertificate) -> Bool {
        lastRelevantCertificates?.contains(certificate) == true
    }
    
    func isCertificateOld(_ certificate: WalletCertificate) -> Bool {
        certificate.isOld || (shouldUseSmartWallet && isPassExpired(for: certificate as? EuropeanCertificate))
    }
    
    func passExpirationTimestamp(for certificate: EuropeanCertificate?) -> Double? {
        guard let cert = certificate else { return nil }
        guard let timestamp = expiryTimestamp(cert) else { return nil }
        return timestamp <= Date().timeIntervalSince1970 ? timestamp : nil
    }
    
    func isPassExpired(for certificate: EuropeanCertificate?) -> Bool {
        passExpirationTimestamp(for: certificate) != nil
    }
    
    func passExpirationSoonTimestamp(for certificate: EuropeanCertificate) -> Double? {
        guard let expiryTimestamp = expiryTimestamp(certificate) else { return nil }
        let now: Date = Date()
        let expiryDate: Date = Date(timeIntervalSince1970: expiryTimestamp)
        if let dateWithThreshold = Calendar.utc.date(byAdding: .day, value: -smartConfig.exp.displayExpDays, to: expiryDate) {
            return dateWithThreshold <= now && now < expiryDate ? expiryTimestamp : nil
        } else {
            return nil
        }
    }
    
    func isPassExpiredSoon(for certificate: EuropeanCertificate) -> Bool {
        passExpirationSoonTimestamp(for: certificate) != nil
    }
    
    func passEligibilityTimestamp(for certificate: EuropeanCertificate) -> Double? {
        guard let timestamp = eligibilityTimestamp(certificate) else { return nil }
        return timestamp <= Date().timeIntervalSince1970 ? timestamp : nil
    }
    
    func isEligibleToVaccination(for certificate: EuropeanCertificate) -> Bool {
        passEligibilityTimestamp(for: certificate) != nil
    }
    
    func passEligibleSoonTimestamp(for certificate: EuropeanCertificate) -> Double? {
        guard let eligibilityTimestamp = eligibilityTimestamp(certificate) else { return nil }
        let now: Date = Date()
        let eligibilityDate: Date = Date(timeIntervalSince1970: eligibilityTimestamp)
        if let dateWithThreshold = Calendar.utc.date(byAdding: .day, value: -smartConfig.elg.displayElgDays, to: eligibilityDate) {
            return dateWithThreshold <= now && now < eligibilityDate ? eligibilityTimestamp : nil
        } else {
            return nil
        }
    }
    
    func isEligibleToVaccinationSoon(for certificate: EuropeanCertificate) -> Bool {
        passEligibleSoonTimestamp(for: certificate) != nil
    }
    
    func eligibleSoonDescription(for certificate: EuropeanCertificate) -> String? {
        guard let timestamp = passEligibleSoonTimestamp(for: certificate) else { return nil }
        let date: Date = Date(timeIntervalSince1970: timestamp)
        return description(for: localizationKey(for: "smartWallet.elegibility.soon.info", and: certificate), and: date)
        
    }
    
    func eligibilityDescription(for certificate: EuropeanCertificate) -> String? {
        guard let timestamp = passEligibilityTimestamp(for: certificate) else { return nil }
        let date: Date = Date(timeIntervalSince1970: timestamp)
        return description(for: localizationKey(for: "smartWallet.elegibility.info", and: certificate), and: date)
        
    }
    
    func expirationSoonDescription(for certificate: EuropeanCertificate) -> String? {
        guard let timestamp = passExpirationSoonTimestamp(for: certificate) else { return nil }
        let date: Date = Date(timeIntervalSince1970: timestamp)
        return description(for: localizationKey(for: "smartWallet.expiration.soon.warning", and: certificate), and: date)
        
    }
    
    func expirationDescription(for certificate: EuropeanCertificate) -> String? {
        guard let timestamp = passExpirationTimestamp(for: certificate) else { return nil }
        let date: Date = Date(timeIntervalSince1970: timestamp)
        return description(for: localizationKey(for: "smartWallet.expiration.error", and: certificate), and: date)
        
    }
}

// MARK: Smart notifications
extension WalletManager {
    private var notifyDelayThreshold: Double {
        12*3600
        
    } // 12 hours
    private var calculationDelayThreshold: Double {
        3600
        
    } // 12 hours
    private var today: Double { Date().roundingToMidnightPastOne().timeIntervalSince1970 }
    private var now: Double { Date().timeIntervalSince1970 }
    private var expiringSoonRanges: [Range<Int>] { [(-21 ..< -10), (-6 ..< -3), (-1 ..< 0)] }
    private var eligibleSoonRanges: [Range<Int>] { [(-15 ..< 0)] }
    
    var smartNotificationIdPrefix: String { "SmartWalletNotification" }
    
    enum NotificationType: String {
        case eligibility
        case eligible
        case expiry
    }
    
    func showSmartNotificationIfNeeded() {
        // Check last time we made the calculation. If to recent -> skip
        guard abs(smartWalletLastNotificationCalculationTimestamp - Date().timeIntervalSince1970) >= calculationDelayThreshold else { return }
        let todayTimestamp: Double = Date().roundingToMidnightPastOne().timeIntervalSince1970
        let expiringSoonCertificates: [(certificate: EuropeanCertificate, expiryTimestamp: Double, range: Range<Int>)] = lastRelevantCertificates?.compactMap {
            guard isPassExpiredSoon(for: $0) else { return nil }
            guard let expiryTimestamp = expiryTimestamp($0) else { return nil }
            let diffDays: Int = (todayTimestamp - expiryTimestamp).secondsToDays()
            guard let range = expiringSoonRanges.first(where: { $0.contains(diffDays) }) else { return nil }
            return ($0, expiryTimestamp, range)
        } ?? []
        
        if !expiringSoonCertificates.isEmpty {
            guard let expiringCertificate = expiringSoonCertificates.sorted(by: { $0.expiryTimestamp < $1.expiryTimestamp }).first else { return }
            let id: String = notificationId(type: .expiry, hash: expiringCertificate.certificate.uniqueHash, range: expiringCertificate.range)
            sendSmartNotificationIfNeeded(for: .expiry, with: id, args: [expiringCertificate.certificate.formattedName])
            // Update last calculation timestamp
            smartWalletLastNotificationCalculationTimestamp = Date().timeIntervalSince1970
            return
        }
        
        let eligibleSoonCertificates: [(certificate: EuropeanCertificate, eligibilityTimestamp: Double, range: Range<Int>)] = lastRelevantCertificates?.compactMap {
            guard isEligibleToVaccinationSoon(for: $0) else { return nil }
            guard let eligibilityTimestamp = eligibilityTimestamp($0) else { return nil }
            let diffDays: Int = (todayTimestamp - eligibilityTimestamp).secondsToDays()
            guard let range = eligibleSoonRanges.first(where: { $0.contains(diffDays) }) else { return nil }
            return ($0, eligibilityTimestamp, range)
        } ?? []
        
        if !eligibleSoonCertificates.isEmpty {
            guard let expiringCertificate = expiringSoonCertificates.sorted(by: { $0.expiryTimestamp < $1.expiryTimestamp }).first else { return }
            let id: String = notificationId(type: .expiry, hash: expiringCertificate.certificate.uniqueHash, range: expiringCertificate.range)
            sendSmartNotificationIfNeeded(for: .expiry, with: id, args: [expiringCertificate.certificate.formattedName])
            // Update last calculation timestamp
            smartWalletLastNotificationCalculationTimestamp = Date().timeIntervalSince1970
            return
        }
        
        let eligibleCertificates: [(certificate: EuropeanCertificate, eligibilityTimestamp: Double)] = lastRelevantCertificates?.compactMap {
            guard isEligibleToVaccination(for: $0) else { return nil }
            guard let eligibilityTimestamp = eligibilityTimestamp($0) else { return nil }
            return ($0, eligibilityTimestamp)
        } ?? []
        if !eligibleCertificates.isEmpty {
            guard let eligibleCertificate = eligibleCertificates.sorted(by: { $0.eligibilityTimestamp < $1.eligibilityTimestamp }).first else { return }
            let id: String = notificationId(type: .eligible, hash: eligibleCertificate.certificate.uniqueHash, range: nil)
            sendSmartNotificationIfNeeded(for: .eligible, with: id, args: [eligibleCertificate.certificate.formattedName])
            // Update last calculation timestamp
            smartWalletLastNotificationCalculationTimestamp = Date().timeIntervalSince1970
        }
    }
}

// MARK: Smart notifications private functions
private extension WalletManager {
    // We have to save the id of the notification, to know, next time, if we already sent a notification for this certificate in this range period. We also save the timestamp of the last send, to repeat the operation only after notifDelayThreshold seconds
    func saveSentNotification(id: String) {
        smartWalletSentNotificationsIds.append(id)
        smartWalletLastNotificationTimestamp = Date().timeIntervalSince1970
    }
    
    func sendSmartNotificationIfNeeded(for type: NotificationType, with id: String, args: [String]) {
        // Check if we have already sent a notification less than notifDelayThreshold seconds ago
        guard abs(smartWalletLastNotificationTimestamp.distance(to: now)) >= notifyDelayThreshold else { return }
        // Check if we have already sent a notification for this certificate and range period
        guard !smartWalletSentNotificationsIds.contains(id) else { return }
        // trigger notification
        NotificationsManager.shared.triggerWalletSmartNotification(type: type, id: id, args: args) { [weak self] success in
            // if notification was delivered -> save id for next time comparison
            if success { self?.saveSentNotification(id: id) }
        }
    }
    
    // Identifier to identify previous notification
    func notificationId(type: NotificationType, hash: String, range: Range<Int>?) -> String {
        "\(smartNotificationIdPrefix)_\(type.rawValue)_\(hash)_\(abs(range?.lowerBound ?? 0))_\(abs(range?.upperBound ?? 0))"
    }
    
    func localizationKey(for prefix: String, and certificate: EuropeanCertificate) -> String? {
        let localizationKey: String
        switch certificate.type {
        case .vaccinationEurope:
            if let medicalProductCode = certificate.medicalProductCode,
                [prefix, certificate.type.rawValue, medicalProductCode].joined(separator: ".").localizedOrNil != nil {
                localizationKey = [prefix, certificate.type.rawValue, medicalProductCode].joined(separator: ".")
            } else {
                localizationKey = [prefix, certificate.type.rawValue].joined(separator: ".")
            }
        case .recoveryEurope, .sanitaryEurope:
            localizationKey = [prefix, certificate.type.rawValue].joined(separator: ".")
        default: return nil
        }
        return localizationKey
    }
    
    func description(for localizationKey: String?, and date: Date) -> String? {
        guard let localizationKey = localizationKey else { return nil }
        return String(format: localizationKey.localized, date.dayShortMonthYearFormatted(timeZoneIndependant: true))
    }
}

// MARK: - Format date
extension Expiration {
    var pivot1Date: Date? { Date(dateString: pivot1) }
    var pivot2Date: Date? { Date(dateString: pivot2) }
    var pivot3Date: Date? { Date(dateString: pivot3) }
}

// MARK: - Util
private extension Int {
    func daysToSeconds() -> Double { Double(self*24*3600) }
}
