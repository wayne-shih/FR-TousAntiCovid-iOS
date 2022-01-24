// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  PositiveTestController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 07/11/2020 - for the TousAntiCovid project.
//

import UIKit

final class PositiveTestController: CVTableViewController {
    
    var symptomsParams: SymptomsDeclarationParams
    
    override var isModalInPresentation: Bool {
        get { true }
        set { }
    }
    
    private let didChooseDateBlock: (_ symptomsParams: SymptomsDeclarationParams) -> ()
    
    init(symptomsParams: SymptomsDeclarationParams, didChooseDateBlock: @escaping (_ symptomsParams: SymptomsDeclarationParams) -> ()) {
        self.symptomsParams = symptomsParams
        self.didChooseDateBlock = didChooseDateBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "positiveTestController.title".localized
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }
    
    deinit {
        LocalizationsManager.shared.removeObserver(self)
    }
    
    override func createSections() -> [CVSection] {
        var rows: [CVRow] = []
        let textRow: CVRow = CVRow(title: "positiveTestController.explanation.title".localized,
                                   subtitle: "positiveTestController.explanation.subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                                      bottomInset: Appearance.Cell.Inset.large,
                                                      separatorLeftInset: nil),
                                   willDisplay: { cell in
                                    cell.accessibilityHint = (cell.accessibilityHint ?? "") + ".\n" + "accessibility.back.zGesture".localized
                                   })
        rows.append(textRow)

        
        let noDateRow: CVRow = CVRow(title: "positiveTestController.noDate".localized,
                                       xibName: .standardCell,
                                       theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                                          bottomInset: Appearance.Cell.Inset.normal,
                                                          textAlignment: .natural,
                                                          titleFont: { Appearance.Cell.Text.standardFont },
                                                          separatorLeftInset: Appearance.Cell.leftMargin),
                                       selectionAction: { [weak self] _ in
            self?.didSelectPositiveTestDate(date: nil)
        })
        rows.append(noDateRow)
        
        let today: Date = Date()
        let originRows: [CVRow] = (0...14).map { day in
            let title: String
            switch day {
            case 0:
                title = "common.today".localized
            case 1:
                title = "common.yesterday".localized
            default:
                title = String(format: "common.daysAgo".localized, day)
            }
            let date: Date = today.dateByAddingDays(-day)
            return CVRow(title: title,
                         subtitle: date.fullDayMonthFormatted().capitalized,
                         xibName: .standardCell,
                         theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                            bottomInset: Appearance.Cell.Inset.normal,
                                            textAlignment: .natural,
                                            titleFont: { Appearance.Cell.Text.standardFont },
                                            separatorLeftInset: Appearance.Cell.leftMargin),
                         selectionAction: { [weak self] _ in
                self?.didSelectPositiveTestDate(date: date)
            })
        }
        rows.append(contentsOf: originRows)
        return [CVSection(rows: rows)]
    }
    
    private func initUI() {
        tableView.showsVerticalScrollIndicator = false
    }
    
    private func didSelectPositiveTestDate(date: Date?) {
        symptomsParams.positiveTestDate = date
        didChooseDateBlock(symptomsParams)
    }
    
}

extension PositiveTestController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        reloadUI()
    }
    
}
