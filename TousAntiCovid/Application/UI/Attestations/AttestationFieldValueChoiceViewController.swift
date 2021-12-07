// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AttestationFieldValueChoiceViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class AttestationFieldValueChoiceViewController: CVTableViewController {
    
    private let items: [AttestationFormFieldItem]
    private var selectedItem: AttestationFormFieldItem?
    private let choiceKey: String
    private let didSelectFieldItem: (_ fieldValue: AttestationFormFieldItem) -> ()
    
    init(items: [AttestationFormFieldItem], selectedItem: AttestationFormFieldItem?, choiceKey: String, didSelectFieldItem: @escaping (_ fieldValue: AttestationFormFieldItem) -> ()) {
        self.items = items
        self.selectedItem = selectedItem
        self.choiceKey = choiceKey
        self.didSelectFieldItem = didSelectFieldItem
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "attestation.form.\(choiceKey).title".localized
        initUI()
        reloadUI()
    }
    
    private func initUI() {
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.delaysContentTouches = false
        tableView.tintColor = Appearance.tintColor
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    override func createSections() -> [CVSection] {
        let headerText: String = "attestation.form.\(choiceKey).header".localizedOrEmpty
        let theme: CVRow.Theme = CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                             topInset: Appearance.Cell.Inset.small,
                                             bottomInset: Appearance.Cell.Inset.small,
                                             textAlignment: .natural,
                                             separatorLeftInset: Appearance.Cell.leftMargin)
        if headerText.isEmpty {
            addHeaderView(height: Appearance.TableView.Header.largeHeight)
        }
        return makeSections {
            CVSection {
                if !headerText.isEmpty {
                    titleRow(title: headerText)
                }
                let footerText: String = "attestation.form.\(choiceKey).footer".localizedOrEmpty
                itemRows(theme: theme, withoutFooterRow: footerText.isEmpty)
                if !footerText.isEmpty {
                    footerRow(title: footerText)
                }
            }
        }
    }

    private func titleRow(title: String) -> CVRow {
        CVRow(title: title,
              xibName: .textCell,
              theme:  CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                  bottomInset: Appearance.Cell.Inset.medium,
                                  textAlignment: .natural,
                                  titleFont: { Appearance.Cell.Text.footerFont },
                                  titleColor: Appearance.Cell.Text.captionTitleColor,
                                  separatorLeftInset: .zero,
                                  separatorRightInset: .zero))
    }

    private func itemRows(theme: CVRow.Theme, withoutFooterRow: Bool) -> [CVRow] {
        var rows: [CVRow] = items.map { item in
            CVRow(title: item.shortLabel,
                  subtitle: item.longLabel,
                  xibName: .textWithoutStackCell,
                  theme: theme,
                  selectionAction: { [weak self] in
                self?.didSelectFieldItem(item)
            }, willDisplay: { [weak self] cell in
                cell.accessoryType = item.code == self?.selectedItem?.code ? .checkmark : .none
                cell.contentView.isAccessibilityElement = true
                cell.accessibilityElements = [cell.contentView]
                cell.cvTitleLabel?.isAccessibilityElement = false
                cell.cvSubtitleLabel?.isAccessibilityElement = false
                cell.contentView.accessibilityLabel = "\(cell.cvTitleLabel?.text ?? ""). \(cell.cvSubtitleLabel?.text ?? "")"
                cell.contentView.accessibilityTraits = .button
            })
        }
        if withoutFooterRow, let lastRow = rows.last {
            var theme: CVRow.Theme = theme
            theme.separatorLeftInset = .zero
            var row: CVRow = lastRow
            row.theme = theme
            rows.removeLast()
            rows.append(row)
        }
        return rows
    }

    private func footerRow(title: String) -> CVRow {
        CVRow(title: title,
              xibName: .textCell,
              theme:  CVRow.Theme(topInset: Appearance.Cell.Inset.large,
                                  bottomInset: .zero,
                                  textAlignment: .natural,
                                  titleFont: { Appearance.Cell.Text.footerFont },
                                  titleColor: Appearance.Cell.Text.captionTitleColor,
                                  separatorLeftInset: .zero,
                                  separatorRightInset: .zero))
    }
}
