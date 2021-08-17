// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  OnboardingPrivacyController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class OnboardingPrivacyController: OnboardingController {

    override var bottomButtonTitle: String { "onboarding.privacyController.accept".localized }
    private var isFirstLoad: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        PrivacyManager.shared.addObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstLoad {
            isFirstLoad = false
            if #available(iOS 14.0, *), isOpenedFromOnboarding {
                tableView.setContentOffset(CGPoint(x: 0.0, y: -84.0), animated: false)
            }
        }
    }
    
    deinit {
        PrivacyManager.shared.removeObserver(self)
    }
    
    override func updateTitle() {
        title =  "onboarding.privacyController.title".localized
        super.updateTitle()
    }
    
    override func createCustomLeftBarButtonItem() -> UIBarButtonItem {
        if isOpenedFromOnboarding {
            return UIBarButtonItem.back(target: self, action: #selector(didTouchBackButton))
        } else {
            let barButtonItem: UIBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
            barButtonItem.accessibilityHint = "accessibility.closeModal.zGesture".localized
            return barButtonItem
        }
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = isOpenedFromOnboarding ? [] : [blockSeparatorRow()]
        if isOpenedFromOnboarding {
            let titleRow: CVRow = CVRow.titleRow(title: title) { [weak self] cell in
                self?.navigationChildController?.updateLabel(titleLabel: cell.cvTitleLabel, containerView: cell)
            }
            rows.append(titleRow)
        }
        let sections: [PrivacySection] = PrivacyManager.shared.privacySections
        let sectionsRows: [CVRow] = sections.map { section in
            let sectionRow: CVRow = CVRow(title: section.section,
                                          subtitle: section.description,
                                          xibName: .textCell,
                                          theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                             topInset: Appearance.Cell.leftMargin,
                                                             bottomInset: Appearance.Cell.leftMargin,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Cell.Text.smallHeadTitleFont },
                                                             separatorLeftInset: Appearance.Cell.leftMargin))
            let linkRows: [CVRow] = section.links?.map { link in
                CVRow(title: link.label,
                      xibName: .standardCell,
                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                         topInset: Appearance.Cell.leftMargin,
                                         bottomInset: Appearance.Cell.leftMargin,
                                         textAlignment: .natural,
                                         titleFont: { Appearance.Cell.Text.standardFont },
                                         titleColor: Appearance.tintColor,
                                         separatorLeftInset: Appearance.Cell.leftMargin),
                      selectionAction: {
                        URL(string: link.url)?.openInSafari()
                      }, willDisplay: { cell in
                        cell.cvTitleLabel?.accessibilityTraits = .button
                        cell.accessoryType = .none
                })
            } ?? []
            return [sectionRow] + linkRows + [blockSeparatorRow()]
        }.reduce([], +)
        rows.append(contentsOf: sectionsRows)
        rows.removeLast()
        rows.append(.empty)
        return rows
    }
    
    private func blockSeparatorRow() -> CVRow {
        var row: CVRow = .emptyFor(topInset: 15.0, bottomInset: 15.0)
        row.theme.separatorLeftInset = 0.0
        row.theme.separatorRightInset = 0.0
        return row
    }

}

extension OnboardingPrivacyController: PrivacyChangesObserver {
    
    func privacyChanged() {
        reloadUI()
    }
    
}
