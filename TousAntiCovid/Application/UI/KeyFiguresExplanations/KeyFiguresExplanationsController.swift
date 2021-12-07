// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFiguresExplanationsController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/09/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK

final class KeyFiguresExplanationsController: CVTableViewController {
    
    init() {
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()
        initUI()
        reloadUI()
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    private func updateTitle() {
        title = "keyFiguresExplanationsController.title".localized
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            KeyFiguresExplanationsManager.shared.keyFiguresExplanationsSection.map { section in
                CVSection {
                    sectionRow(section: section)
                    linkRows(links: section.links ?? [])
                } header: {
                    .groupedHeader
                }

            }
        }
    }

    private func initUI() {
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
    }
    
    private func addObservers() {
        LocalizationsManager.shared.addObserver(self)
        LinksManager.shared.addObserver(self)
    }
    
    private func removeObservers() {
        LocalizationsManager.shared.removeObserver(self)
        LinksManager.shared.removeObserver(self)
    }

}

extension KeyFiguresExplanationsController: LocalizationsChangesObserver {
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
}

extension KeyFiguresExplanationsController: LinksChangesObserver {
    func linksChanged() {
        reloadUI()
    }
}

// MARK: - Rows -
private extension KeyFiguresExplanationsController {
    func sectionRow(section: KeyFiguresExplanationsSection) -> CVRow {
        CVRow(title: section.section,
              subtitle: section.description,
              xibName: .textCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.normal,
                                 bottomInset: Appearance.Cell.Inset.normal,
                                 textAlignment: .natural,
                                 separatorLeftInset: (section.links ?? []).isEmpty ? nil : Appearance.Cell.leftMargin))
    }
    
    func linkRows(links: [Link]) -> [CVRow] {
        links.enumerated().map { index, link in
            CVRow(title: link.label,
                  xibName: .standardCell,
                  theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                     topInset: Appearance.Cell.Inset.normal,
                                     bottomInset: Appearance.Cell.Inset.normal,
                                     textAlignment: .natural,
                                     titleFont: { Appearance.Cell.Text.standardFont },
                                     titleColor: Appearance.tintColor,
                                     separatorLeftInset: index + 1 == links.count ? nil : Appearance.Cell.leftMargin,
                                     accessoryType: UITableViewCell.AccessoryType.none),
                  selectionAction: {
                URL(string: link.url)?.openInSafari()
            }, willDisplay: { cell in
                cell.cvTitleLabel?.accessibilityTraits = .button
            })
        }
    }
}
