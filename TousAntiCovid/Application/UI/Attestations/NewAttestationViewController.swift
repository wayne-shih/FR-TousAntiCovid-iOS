// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NewAttestationViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK
import PKHUD

final class NewAttestationViewController: CVTableViewController {
    
    private let didTouchSelectFieldItem: (_ items: [AttestationFormFieldItem], _ selectedItem: AttestationFormFieldItem?, _ choiceKey: String, _ didSelectedFieldItem: @escaping (_ fieldValue: AttestationFormFieldItem) -> ()) -> ()
    private let deinitBlock: () -> ()
    
    private let groupedFields: [[AttestationFormField]] = AttestationsManager.shared.formFields
    private var isFirstLoad: Bool = true
    private weak var firstTextField: UITextField?
    private var fieldValues: [String: [String: String]] = [:]
    private var fieldSelectedItems: [String: [String: AttestationFormFieldItem]] = [:]
    private var dobDate: Date = Date().dateByAddingYears(-18)
    private var outingDate: Date = Date()
    private var currentSaveMyData: Bool = false
    
    @UserDefault(key: .saveAttestationFieldsData)
    private var saveMyData: Bool = false
    
    init(didTouchSelectFieldItem: @escaping (_ items: [AttestationFormFieldItem], _ selectedItem: AttestationFormFieldItem?, _ choiceKey: String, _ didSelectedFieldItem: @escaping (_ fieldValue: AttestationFormFieldItem) -> ()) -> (),
         deinitBlock: @escaping () -> ()) {
        self.didTouchSelectFieldItem = didTouchSelectFieldItem
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "newAttestationController.title".localized
        initUI()
        preloadFieldValues()
        reloadUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstLoad {
            isFirstLoad = false
            focusRightField()
        }
    }
    
    deinit {
        deinitBlock()
    }
    
    private func initUI() {
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.keyboardDismissMode = .onDrag
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.cancel".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "newAttestationController.generate".localized, style: .plain, target: self, action: #selector(didTouchGenerateButton))
    }
    
    private func focusRightField() {
        if AttestationsManager.shared.getAttestationFieldValues().isEmpty {
            firstTextField?.becomeFirstResponder()
        }
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true)
    }
    
    @objc private func didTouchGenerateButton() {
        if areFieldsValid() {
            showGenerateAlert()
        } else {
            showAlert(title: "newAttestationController.missingInfo.alert.title".localized,
                      message: "newAttestationController.missingInfo.alert.message".localized,
                      okTitle: "common.ok".localized)
        }
    }

    private func preloadFieldValues() {
        fieldValues = AttestationsManager.shared.getAttestationFieldValues()
        let now: Date = Date()
        let day: String = now.dayMonthYearFormatted()
        let hour: String = now.shortTimeFormatted()
        fieldValues["datetime"] = ["datetime": "\(day), \(hour)"]
        fieldValues["datetime-day"] = ["datetime-day": day]
        fieldValues["datetime-hour"] = ["datetime-hour": hour]
        if let dobTimestampString = fieldValues["dob-timestamp"]?["dob-timestamp"], let dobTimestamp = Double(dobTimestampString) {
            dobDate = Date(timeIntervalSince1970: Double(dobTimestamp))
        }
        currentSaveMyData = saveMyData
    }

    private func areFieldsValid() -> Bool {
        var areAllFieldsFilledIn: Bool = true
        groupedFields.joined().forEach { field in
            if fieldValues[field.dataKeyValue] == nil {
                areAllFieldsFilledIn = false
            }
        }
        return areAllFieldsFilledIn
    }

    private func showGenerateAlert() {
        showAlert(title: "newAttestationController.generate.alert.title".localized,
                  message: "newAttestationController.generate.alert.message".localized,
                  okTitle: "newAttestationController.generate.alert.validate".localized,
                  cancelTitle: "common.cancel".localized, handler: { [weak self] in
                    self?.generate()
                  })
    }

    private func generate() {
        HUD.show(.progress)
        DispatchQueue.main.async {
            let now: Date = Date()
            self.fieldValues["creationDate"] = ["creationDate": now.dayMonthYearFormatted()]
            self.fieldValues["creationHour"] = ["creationHour": now.shortTimeFormatted()]
            
            let reasonDict: [String: String] = self.fieldValues["reason"] ?? [:]
            var reasonCode: String = ""
            var shortLabel: String?
            reasonDict.forEach { key, value in
                if key.hasSuffix("-code") {
                    reasonCode = value.components(separatedBy: ".")[safe: 1] ?? ""
                } else if key.hasSuffix("-shortlabel") {
                    shortLabel = value
                }
            }
            self.fieldValues["reason"]?["reason-code"] = reasonCode
            self.fieldValues["reason"]?["reason-shortlabel"] = shortLabel
            
            guard let qrCodeString = AttestationsManager.shared.generateQRCode(for: self.fieldValues) else {
                self.showGenerationErrorAlert()
                return
            }
            guard let qrCode = qrCodeString.qrCode() else {
                self.showGenerationErrorAlert()
                return
            }
            guard let qrCodeData = UIGraphicsImageRenderer(size: qrCode.size, format: qrCode.imageRendererFormat).image(actions: { _ in
                UIImage(ciImage: qrCode.ciImage!).draw(in: CGRect(origin: .zero, size: qrCode.size))
            }).pngData() else {
                self.showGenerationErrorAlert()
                return
            }
            guard let qrCodeDisplayableString = AttestationsManager.shared.generateQRCodeDisplayableString(for: self.fieldValues) else {
                self.showGenerationErrorAlert()
                return
            }
            guard let qrCodeFooter = AttestationsManager.shared.generateQRCodeFooter(for: self.fieldValues) else {
                self.showGenerationErrorAlert()
                return
            }

            AttestationsManager.shared.saveAttestation(timestamp: Int(self.outingDate.timeIntervalSince1970), qrCode: qrCodeData, footer: qrCodeFooter, qrCodeString: qrCodeDisplayableString, reason: reasonCode)
            self.saveFieldValuesIfNeeded()
            HUD.hide()
            self.dismiss(animated: true)
        }
    }
    
    private func showGenerationErrorAlert() {
        showAlert(title: "newAttestationController.generate.error.alert.title".localized,
                  message: "newAttestationController.generate.error.alert.message".localized,
                  okTitle: "common.ok".localized)
    }
    
    private func saveFieldValuesIfNeeded() {
        guard currentSaveMyData else { return }
        saveMyData = currentSaveMyData
        fieldValues.forEach { dataKey, value in
            guard !dataKey.contains("datetime") && !dataKey.contains("reason") && !dataKey.contains("creationDate") && !dataKey.contains("creationHour") else { return }
            value.forEach { key, value in
                AttestationsManager.shared.saveAttestationFieldValueForKey(key, dataKey: dataKey, value: value)
            }
        }
    }
    
    override func createSections() -> [CVSection] {
        let headerText: String = "newAttestationController.header".localizedOrEmpty
        if headerText.isEmpty {
            addHeaderView(height: Appearance.TableView.Header.largeHeight)
        }
        return makeSections {
            CVSection {
                if !headerText.isEmpty {
                    titleRow(title: headerText)
                }
                fieldsRows()
                switchRow()
                footerRow()
            }
        }
    }

    // MARK: - Rows -
    private func titleRow(title: String) -> CVRow {
        CVRow(title: title,
              xibName: .textCell,
              theme:  CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                  bottomInset: Appearance.Cell.Inset.medium,
                                  textAlignment: .natural,
                                  titleFont: { Appearance.Cell.Text.footerFont },
                                  titleColor: Appearance.Cell.Text.captionTitleColor,
                                  separatorLeftInset: .zero,
                                  separatorRightInset: .zero),
              willDisplay: { cell in
            cell.accessibilityElements = []
            cell.accessibilityElementsHidden = true
            cell.isAccessibilityElement = false
        })
    }

    private func fieldsRows() -> [CVRow] {
        let theme: CVRow.Theme = CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                             topInset: Appearance.Cell.Inset.small,
                                             bottomInset: Appearance.Cell.Inset.small,
                                             textAlignment: .natural,
                                             titleFont: { .regular(size: 12.0) },
                                             titleColor: Appearance.Cell.Text.subtitleColor,
                                             subtitleFont: { .regular(size: 17.0) },
                                             subtitleColor: Appearance.Cell.Text.titleColor,
                                             separatorLeftInset: Appearance.Cell.leftMargin)

        var fieldTag: Int = 1000
        let fieldsRows: [[CVRow]] = groupedFields.map { fields in
            var rows: [CVRow] = fields.map { field in
                let row: CVRow
                switch field.type {
                case .date:
                    row = CVRow(title: field.name,
                                subtitle: fieldValues[field.dataKeyValue]?[field.key],
                                placeholder: field.placeholder,
                                xibName: .dateCell,
                                theme: self.defaultRowTheme(),
                                associatedValue: fieldTag,
                                maximumDate: field.key == "dob" ? Date() : nil,
                                initialDate: field.key == "dob" ? dobDate : nil,
                                datePickerMode: .date,
                                willDisplay: { [weak self] cell in
                        guard let self = self else { return }
                        (cell as? DateCell)?.datePicker.date = self.dobDate
                        (cell as? DateCell)?.cvSubtitleLabel?.text = self.fieldValues[field.dataKeyValue]?[field.key]
                    },
                                valueChanged: { [weak self] value in
                        guard let value = value as? Date else { return }
                        self?.fieldValues[field.key] = [field.key: value.dayMonthYearFormatted()]
                        self?.fieldValues["\(field.key)-timestamp"] = ["\(field.key)-timestamp": "\(value.timeIntervalSince1970)"]
                    }, displayValueForValue: { value -> String? in
                        guard let value = value as? Date else { return nil }
                        return value.dayMonthYearFormatted()
                    })
                case .dateTime:
                    row = CVRow(title: field.name,
                                subtitle: fieldValues[field.dataKeyValue]?[field.key],
                                placeholder: field.placeholder,
                                xibName: .dateCell,
                                theme: self.defaultRowTheme(),
                                associatedValue: fieldTag,
                                minimumDate: field.key == "datetime" ? Date() : nil,
                                initialDate: field.key == "datetime" ? Date() : nil,
                                datePickerMode: .dateAndTime,
                                willDisplay: { [weak self] cell in
                        guard let self = self else { return }
                        (cell as? DateCell)?.datePicker.date = self.outingDate
                        (cell as? DateCell)?.cvSubtitleLabel?.text = self.fieldValues[field.dataKeyValue]?[field.key]
                    },
                                valueChanged: { [weak self] value in
                        guard let value = value as? Date else { return }
                        if field.key == "datetime" {
                            self?.outingDate = value
                        }
                        let day: String = value.dayMonthYearFormatted()
                        let hour: String = value.shortTimeFormatted()
                        self?.fieldValues[field.key] = [field.key: "\(day), \(hour)"]
                        self?.fieldValues["\(field.key)-timestamp"] = ["\(field.key)-timestamp": "\(value.timeIntervalSince1970)"]
                        self?.fieldValues["\(field.key)-day"] = ["\(field.key)-day": day]
                        self?.fieldValues["\(field.key)-hour"] = ["\(field.key)-hour": hour]
                    }, displayValueForValue: { value -> String? in
                        guard let value = value as? Date else { return nil }
                        return "\(value.dayMonthYearFormatted()), \(value.shortTimeFormatted())"
                    })
                case .list:
                    let selectedListItem: AttestationFormFieldItem? = fieldSelectedItems[field.dataKeyValue]?[field.key]
                    row = CVRow(title: field.name,
                                subtitle: selectedListItem?.shortLabel ?? "-",
                                xibName: .textCell,
                                theme: self.listRowTheme(fieldDataKey: field.dataKeyValue),
                                selectionAction: { [weak self] in
                        self?.didTouchSelectFieldItem(field.items ?? [], self?.fieldSelectedItems[field.dataKeyValue]?[field.key], field.key) { selectedItem in
                            self?.fieldSelectedItems[field.dataKeyValue] = [field.key: selectedItem]
                            self?.fieldValues[field.dataKeyValue] = ["\(field.key)": selectedItem.code,
                                                                     "\(field.key)-code": selectedItem.code,
                                                                     "\(field.key)-shortlabel": selectedItem.shortLabel]
                            self?.reloadUI()
                        }
                    }, willDisplay: { [weak self] cell in
                        cell.cvSubtitleLabel?.textColor = self?.fieldSelectedItems[field.dataKeyValue]?[field.key] == nil ? Appearance.Cell.Text.placeholderColor : Appearance.Cell.Text.subtitleColor
                        cell.cvSubtitleLabel?.accessibilityHint = cell.cvTitleLabel?.text?.removingEmojis()
                        cell.cvSubtitleLabel?.accessibilityTraits = .button
                        cell.accessibilityElements = [cell.cvSubtitleLabel].compactMap { $0 }
                    })
                default:
                    row = CVRow(title: field.name,
                                subtitle: fieldValues[field.dataKeyValue]?[field.key],
                                placeholder: field.placeholder,
                                xibName: .standardTextFieldCell,
                                theme: self.defaultRowTheme(),
                                associatedValue: fieldTag,
                                textFieldKeyboardType: field.type.keyboardType,
                                textFieldContentType: field.contentType?.textContentType,
                                textFieldCapitalizationType: field.type.capitalizationType,
                                willDisplay: { [weak self] cell in
                        guard let self = self else { return }
                        if self.firstTextField == nil {
                            self.firstTextField = (cell as? StandardTextFieldCell)?.cvTextField
                        }
                        if let defaultValue = field.defaultValue, self.fieldValues[field.dataKeyValue]?[field.key] == nil {
                            self.fieldValues[field.dataKeyValue] = [field.key: defaultValue]
                        }
                        (cell as? StandardTextFieldCell)?.cvTextField.text = self.fieldValues[field.dataKeyValue]?[field.key]
                    }, valueChanged: { [weak self] value in
                        if let value = value as? String, !value.isEmpty {
                            self?.fieldValues[field.dataKeyValue] = [field.key: value]
                        } else {
                            self?.fieldValues[field.dataKeyValue] = nil
                        }
                    }, didValidateValue: { [weak self] _, cell in
                        guard let fieldTag = (cell as? StandardTextFieldCell)?.cvTextField.tag else { return }
                        self?.tableView.viewWithTag(fieldTag + 1)?.becomeFirstResponder()
                    })
                }
                fieldTag += 1
                return row
            }
            if let lastRow = rows.last {
                var theme: CVRow.Theme = theme
                theme.separatorLeftInset = .zero
                var row: CVRow = lastRow
                row.theme = theme
                rows.removeLast()
                rows.append(row)
            }
            rows.append(.emptyFor(topInset: Appearance.Cell.Inset.small,
                                  bottomInset: Appearance.Cell.Inset.small,
                                  showSeparator: true)
            )
            return rows
        }
        return fieldsRows.flatMap { $0 }
    }

    private func switchRow() -> CVRow {
        CVRow(title: "newAttestationController.saveMyData".localized,
              isOn: currentSaveMyData,
              xibName: .standardSwitchCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.small,
                                 bottomInset: Appearance.Cell.Inset.small,
                                 textAlignment: .left,
                                 titleFont: { Appearance.Cell.Text.standardFont },
                                 separatorLeftInset: .zero,
                                 separatorRightInset: .zero),
              willDisplay: { [weak self] cell in
            guard let self = self else { return }
            (cell as? StandardSwitchCell)?.cvSwitch.isOn = self.currentSaveMyData
            let generateAction: UIAccessibilityCustomAction = UIAccessibilityCustomAction(
                name: "accessibility.attestation.generate".localized,
                target: self,
                selector: #selector(self.didTouchGenerateButton)
            )
            cell.accessibilityCustomActions = [generateAction]
        }, valueChanged: { [weak self] value in
            guard let isOn = value as? Bool else { return }
            self?.currentSaveMyData = isOn
        })
    }

    private func footerRow() -> CVRow {
        CVRow(title: "newAttestationController.footer".localized,
              xibName: .textCell,
              theme:  CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                  bottomInset: .zero,
                                  textAlignment: .natural,
                                  titleFont: { Appearance.Cell.Text.footerFont },
                                  titleColor: Appearance.Cell.Text.captionTitleColor))
    }
    
    private func defaultRowTheme() -> CVRow.Theme {
        return CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                           topInset: Appearance.Cell.Inset.small,
                           bottomInset: Appearance.Cell.Inset.small,
                           textAlignment: .natural,
                           titleFont: { .regular(size: 12.0) },
                           titleColor: Appearance.Cell.Text.subtitleColor,
                           subtitleFont: { .regular(size: 17.0) },
                           subtitleColor: Appearance.Cell.Text.titleColor,
                           separatorLeftInset: Appearance.Cell.leftMargin)
    }
    
    private func listRowTheme(fieldDataKey: String) -> CVRow.Theme {
        return CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                           topInset: Appearance.Cell.Inset.small,
                           bottomInset: Appearance.Cell.Inset.small,
                           textAlignment: .natural,
                           titleFont: { .regular(size: 12.0) },
                           titleColor: Appearance.Cell.Text.subtitleColor,
                           subtitleFont: { .regular(size: 17.0) },
                           subtitleColor: Appearance.Cell.Text.placeholderColor,
                           separatorLeftInset: Appearance.Cell.leftMargin)
    }
    
}
