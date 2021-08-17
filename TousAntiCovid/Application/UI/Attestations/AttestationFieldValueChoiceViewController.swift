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
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.delaysContentTouches = false
        tableView.tintColor = Appearance.tintColor
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let theme: CVRow.Theme = CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                             topInset: 10.0,
                                             bottomInset: 10.0,
                                             textAlignment: .natural,
                                             separatorLeftInset: Appearance.Cell.leftMargin)
        let headerText: String = "attestation.form.\(choiceKey).header".localizedOrEmpty
        if headerText.isEmpty {
            rows.append(.emptyFor(topInset: 10.0, bottomInset: 10.0, showSeparator: true))
        } else {
            let headerRow: CVRow = CVRow(title: headerText,
                                         xibName: .textCell,
                                         theme:  CVRow.Theme(topInset: 20.0,
                                                             bottomInset: 20.0,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Cell.Text.footerFont },
                                                             titleColor: Appearance.Cell.Text.captionTitleColor,
                                                             separatorLeftInset: 0.0,
                                                             separatorRightInset: 0.0))
            rows.append(headerRow)
        }
        rows.append(contentsOf: items.map { item in
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
        })
        let footerText: String = "attestation.form.\(choiceKey).footer".localizedOrEmpty
        if footerText.isEmpty {
            if let lastRow = rows.last {
                var theme: CVRow.Theme = theme
                theme.separatorLeftInset = 0.0
                var row: CVRow = lastRow
                row.theme = theme
                rows.removeLast()
                rows.append(row)
            }
        } else {
            let footerRow: CVRow = CVRow(title: footerText,
                                         xibName: .textCell,
                                         theme:  CVRow.Theme(topInset: 30.0,
                                                             bottomInset: 0.0,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Cell.Text.footerFont },
                                                             titleColor: Appearance.Cell.Text.captionTitleColor,
                                                             separatorLeftInset: 0.0,
                                                             separatorRightInset: 0.0))
            rows.append(footerRow)
        }
        return rows
    }
    
}
