// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class KeyFigureCell: CardCell, Xibbed {
    
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var valueLabel: UILabel!
    @IBOutlet private var departmentLabel: UILabel!

    @IBOutlet private var countryStackView: UIStackView!
    @IBOutlet private var countryLabel: UILabel!
    @IBOutlet private var countryValueLabel: UILabel!
    
    @IBOutlet private var sharingImageView: UIImageView!
    
    @IBOutlet private var valuesContainerStackView: DynamicContentStackView!
    @IBOutlet private var sharingButton: UIButton!
    
    @IBOutlet private var baselineAlignmentConstraint: NSLayoutConstraint?
    
    private var contentSizeCategoryThreashold: UIContentSizeCategory { UIScreen.main.bounds.width >= 375.0 ? .accessibilityMedium : .extraLarge }
    private var isLarge: Bool { UIApplication.shared.preferredContentSizeCategory >= contentSizeCategoryThreashold }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupContent(with: row)
        setupAccessibility(with: row)
    }

    override func capture() -> UIImage? {
        sharingImageView.isHidden = true
        let image: UIImage? = containerView.screenshot()
        sharingImageView.isHidden = false
        return image
    }

    private func addObservers() {
        removeObservers()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changeInPreferredContentSize),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        valuesContainerStackView.threshold = contentSizeCategoryThreashold
        valuesContainerStackView.thresholdAxis = .vertical
        valuesContainerStackView.thresholdAlignment = .leading
        valuesContainerStackView.thresholdSpacing = 20.0
        dateLabel.font = Appearance.Cell.Text.captionTitleFont
        dateLabel.textColor = Appearance.Cell.Text.captionTitleColor
        departmentLabel?.textColor = Appearance.Cell.Text.captionTitleColor
        departmentLabel?.font = Appearance.Cell.Text.captionTitleFont2
        countryLabel?.textColor = Appearance.Cell.Text.captionTitleColor
        countryLabel?.font = Appearance.Cell.Text.captionTitleFont2
        countryValueLabel?.font = Appearance.Cell.Text.titleFontExtraBold
        cvSubtitleLabel?.font = Appearance.Cell.Text.subtitleFont
        valueLabel.font = Appearance.Cell.Text.headTitleFont2
        sharingImageView.tintColor = Appearance.tintColor
        sharingImageView.image = Asset.Images.shareIcon.image
        changeInPreferredContentSize()
    }
    
    private func setupContent(with row: CVRow) {
        guard let keyFigure = row.associatedValue as? KeyFigure else { return }
        valueLabel.textColor = keyFigure.color
        cvTitleLabel?.textColor = keyFigure.color
        countryValueLabel?.textColor = keyFigure.color
        if let departmentKeyFigure = keyFigure.currentDepartmentSpecificKeyFigure, KeyFiguresManager.shared.canShowCurrentlyNeededFile {
            dateLabel.text = departmentKeyFigure.formattedDate
            departmentLabel?.text = departmentKeyFigure.label.uppercased()
            departmentLabel?.isHidden = false
            valueLabel.text = departmentKeyFigure.valueToDisplay.formattingValueWithThousandsSeparatorIfPossible()
            countryLabel?.text = "france".localized.uppercased()
            countryValueLabel.text = keyFigure.valueGlobalToDisplay.formattingValueWithThousandsSeparatorIfPossible()
            countryStackView?.isHidden = false
        } else {
            dateLabel.text = keyFigure.formattedDate
            if KeyFiguresManager.shared.currentFormattedDepartmentNameAndPostalCode == nil || keyFigure.category == .app || !KeyFiguresManager.shared.canShowCurrentlyNeededFile {
                departmentLabel?.isHidden = true
            } else {
                departmentLabel?.text = "common.country.france".localized.uppercased()
                departmentLabel?.isHidden = false
            }
            countryStackView?.isHidden = true
            valueLabel.text = keyFigure.valueGlobalToDisplay.formattingValueWithThousandsSeparatorIfPossible()
        }
    }

    override func setupAccessibility() {}

    private func setupAccessibility(with row: CVRow) {
        guard let keyFigure = row.associatedValue as? KeyFigure else { return }
        accessibilityElements = [dateLabel!]
        if !departmentLabel.isHidden {
            accessibilityElements?.append(departmentLabel!)
            departmentLabel.isAccessibilityElement = true
        }
        accessibilityElements?.append(cvTitleLabel!)
        cvTitleLabel?.isAccessibilityElement = true
        cvTitleLabel?.accessibilityTraits = .button
        if !countryStackView.isHidden {
            accessibilityElements?.append(countryLabel!)
            countryLabel?.isAccessibilityElement = true
            let countryValue: String = countryValueLabel.text?.replacingOccurrences(of: " ", with: "") ?? ""
            countryLabel?.accessibilityLabel = "\(countryLabel?.text ?? ""), \(countryValue))"
        }
        accessibilityElements?.append(cvSubtitleLabel!)
        cvSubtitleLabel?.isAccessibilityElement = true
        accessibilityElements?.append(sharingButton!)
        sharingButton?.isAccessibilityElement = true
        let value: String = valueLabel.text?.replacingOccurrences(of: " ", with: "").accessibilityNumberFormattedString() ?? ""
        cvTitleLabel?.accessibilityLabel = "\(cvTitleLabel?.text ?? ""), \(value)"
        sharingButton.accessibilityLabel = "accessibility.hint.keyFigure.share".localized
        let date: Date = Date(timeIntervalSince1970: Double(keyFigure.extractDate))
        dateLabel.accessibilityLabel = date.accessibilityRelativelyFormattedDate(prefixStringKey: "keyFigures.update")
    }
    
    @IBAction private func didTouchSharingButton(_ sender: Any) {
        currentAssociatedRow?.selectionActionWithCell?(self)
    }
    
    @objc private func changeInPreferredContentSize() {
        if isLarge {
            baselineAlignmentConstraint?.isActive = false
        } else {
            baselineAlignmentConstraint?.isActive = true
        }
    }

}
