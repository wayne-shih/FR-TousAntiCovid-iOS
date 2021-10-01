// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UserLanguageController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 19/07/2021 - for the TousAntiCovid project.
//

import UIKit

final class UserLanguageController: CVTableViewController {
    
    private var deinitBlock: (() -> ())?
    
    init(deinitBlock: @escaping () -> ()) {
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }
    
    deinit {
        LocalizationsManager.shared.removeObserver(self)
        deinitBlock?()
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let headerTitleRow: CVRow = CVRow(title: "userLanguageController.subtitle".localized,
                                       xibName: .textCell,
                                       theme: CVRow.Theme(topInset: Appearance.Cell.leftMargin,
                                                          bottomInset: Appearance.Cell.leftMargin,
                                                          textAlignment: .natural,
                                                          titleColor: Appearance.tintColor,
                                                          separatorLeftInset: 0.0,
                                                          separatorRightInset: 0.0))
        rows.append(headerTitleRow)
        let userLanguageRows: [CVRow] = [
            selectableRow(title: "manageDataController.languageFR".localized,
                          isSelected: Locale.currentAppLanguageCode == Constant.Language.french,
                          selectionBlock: {
                            Constant.appLanguage =  Constant.Language.french
                          }),
            selectableRow(title: "manageDataController.languageEN".localized,
                          isSelected: Locale.currentAppLanguageCode == Constant.Language.english,
                          selectionBlock: {
                            Constant.appLanguage = Constant.Language.english
                          })
        ]
        rows.append(contentsOf: userLanguageRows)
        let textRow: CVRow = CVRow(title: "userLanguageController.footer".localized,
                                       xibName: .textCell,
                                       theme: CVRow.Theme(topInset: Appearance.Cell.leftMargin,
                                                          bottomInset: Appearance.Cell.leftMargin,
                                                          textAlignment: .natural,
                                                          titleFont: { Appearance.Cell.Text.subtitleFont },
                                                          titleColor: Appearance.Cell.Text.placeholderColor,
                                                          separatorLeftInset: Appearance.Cell.leftMargin))
        rows.append(textRow)
        let buttonRow: CVRow = CVRow(title: "userLanguageController.button.title".localized,
                                             xibName: .buttonCell,
                                             theme: CVRow.Theme(topInset: 0.0, bottomInset: 0.0, buttonStyle: .primary),
                                             selectionAction: {
                                                if Constant.appLanguage.isNil { Constant.appLanguage = Constant.Language.english }
                                                self.dismiss(animated: true, completion: nil)
                                             })
        rows.append(buttonRow)
        rows.append(.empty)
        return rows
    }
    
    private func selectableRow(title: String, isSelected: Bool, selectionBlock: @escaping () -> ()) -> CVRow {
        CVRow(title: title,
              isOn: isSelected,
              xibName: .selectableCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.leftMargin,
                                 bottomInset: Appearance.Cell.leftMargin,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.standardFont },
                                 separatorLeftInset: Appearance.Cell.leftMargin,
                                 separatorRightInset: 0.0),
              selectionAction: {
                selectionBlock()
              })
    }
    
    private func updateTitle() {
        title = "userLanguageController.title".localized
    }
    
    private func initUI() {
        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont]
    }
    
}

extension UserLanguageController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}

