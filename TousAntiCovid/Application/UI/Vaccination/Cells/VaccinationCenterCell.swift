// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VaccinationCenterCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 27/01/2021 - for the TousAntiCovid project.
//

import UIKit

final class VaccinationCenterCell: CardCell, Xibbed {

    @IBOutlet private var addressLabel: UILabel!
    @IBOutlet private var openingDateTitleLabel: UILabel!
    @IBOutlet private var openingDateLabel: UILabel!
    @IBOutlet private var openingTimeLabel: UILabel!

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
        setupContent(with: row)
        setupAccessibility(with: row)
    }

    private func setupUI(with row: CVRow) {
        guard let vaccinationCenter = row.associatedValue as? VaccinationCenter else { return }
        addressLabel.font = Appearance.Cell.Text.subtitleFont
        addressLabel.textColor = Appearance.Cell.Text.subtitleColor
        openingDateTitleLabel.isHidden = vaccinationCenter.availabilityTimestamp == nil && (vaccinationCenter.planning ?? "").isEmpty
        openingDateTitleLabel.font = Appearance.Cell.Text.accessoryFont
        openingDateTitleLabel.textColor = Appearance.Cell.Text.captionTitleColor
        openingDateLabel.isHidden = vaccinationCenter.availabilityTimestamp == nil
        openingDateLabel?.textColor = Appearance.Cell.Text.titleColor
        openingDateLabel?.font = Appearance.Cell.Text.subtitleFont
        openingTimeLabel.isHidden = (vaccinationCenter.planning ?? "").isEmpty
        openingTimeLabel?.textColor = Appearance.Cell.Text.titleColor
        openingTimeLabel?.font = Appearance.Cell.Text.subtitleFont
    }

    private func setupContent(with row: CVRow) {
        guard let vaccinationCenter = row.associatedValue as? VaccinationCenter else { return }
        cvTitleLabel?.text = vaccinationCenter.name
        cvSubtitleLabel?.text = vaccinationCenter.modalities
        addressLabel.text = getDisplayAddress(vaccinationCenter: vaccinationCenter)
        openingDateTitleLabel.text = "vaccinationCenterCell.openingDate.title".localized
        if let openingDate = vaccinationCenter.availabilityTimestamp {
            let date: Date = Date(timeIntervalSince1970: openingDate)
            openingDateLabel.text = "\("vaccinationCenterCell.openingDate.from".localized) \(date.shortDateFormatted(timeZoneIndependant: true))"
        } else {
            openingDateLabel.text = nil
        }
        openingTimeLabel.text = vaccinationCenter.planning
    }

    private func getDisplayAddress(vaccinationCenter: VaccinationCenter) -> String {
        let firstLineAddress: String = [vaccinationCenter.streetNumber, vaccinationCenter.streetName].filter { !$0.isEmpty } .joined(separator: ", ")
        let secondLineAddress: String = [vaccinationCenter.postalCode, vaccinationCenter.locality].filter { !$0.isEmpty } .joined(separator: " ")
       return [firstLineAddress, secondLineAddress].filter { !$0.isEmpty } .joined(separator: "\n")
    }

    override func setupAccessibility() {}

    private func setupAccessibility(with row: CVRow) {
        guard let vaccinationCenter = row.associatedValue as? VaccinationCenter else { return }
        var openingDateHint: String? = nil
        if let availabilityTimestamp = vaccinationCenter.availabilityTimestamp {
            let openingDate: Date = Date(timeIntervalSince1970: availabilityTimestamp)
            openingDateHint = openingDate.accessibilityRelativelyFormattedDate(prefixStringKey: "vaccinationCenterCell.openingDate.from")
        }
        accessibilityLabel = cvTitleLabel?.text?.removingEmojis()
        accessibilityHint = [addressLabel?.text, openingDateTitleLabel?.text, openingDateHint, openingTimeLabel?.text].compactMap { $0 }.joined(separator: ".\n").removingEmojis()
        accessibilityTraits = currentAssociatedRow?.selectionAction != nil ? .button : .staticText
        accessibilityElements = []
        isAccessibilityElement = true
        containerView.isAccessibilityElement = false
        cvAccessoryLabel?.isAccessibilityElement = false
        cvTitleLabel?.isAccessibilityElement = false
        cvSubtitleLabel?.isAccessibilityElement = false
        cvImageView?.isAccessibilityElement = false
        cvImageView?.accessibilityTraits = []
        cvImageView?.isUserInteractionEnabled = false
        addressLabel?.isAccessibilityElement = false
        openingDateTitleLabel?.isAccessibilityElement = false
        openingDateLabel?.isAccessibilityElement = false
        openingTimeLabel?.isAccessibilityElement = false
    }
}
