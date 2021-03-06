// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SymptomsOriginController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 04/05/2020 - for the TousAntiCovid project.
//


import UIKit

final class SymptomsOriginController: CVTableViewController {
    
    var symptomsParams: SymptomsDeclarationParams

    override var isModalInPresentation: Bool {
        get { true }
        set { }
    }
    
    private let didChooseDateBlock: (_ symptomsParams: SymptomsDeclarationParams) -> ()
    private let deinitBlock: () -> ()
    
    init(symptomsParams: SymptomsDeclarationParams, didChooseDateBlock: @escaping (_ symptomsParams: SymptomsDeclarationParams) -> (), deinitBlock: @escaping () -> ()) {
        self.symptomsParams = symptomsParams
        self.didChooseDateBlock = didChooseDateBlock
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "symptomsOriginController.title".localized
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }
    
    deinit {
        LocalizationsManager.shared.removeObserver(self)
        deinitBlock()
    }
    
    override func createSections() -> [CVSection] {
        var rows: [CVRow] = []
        let textRow: CVRow = CVRow(title: "symptomsOriginController.explanation.title".localized,
                                   subtitle: "symptomsOriginController.explanation.subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                                      bottomInset: Appearance.Cell.Inset.large,
                                                      separatorLeftInset: nil),
                                   willDisplay: { cell in
                                    cell.accessibilityHint = (cell.accessibilityHint ?? "") + ".\n" + "accessibility.back.zGesture".localized
                                   })
        rows.append(textRow)

        let noSymptomsRow: CVRow = CVRow(title: "symptomsOriginController.noSymptoms".localized,
                                       xibName: .standardCell,
                                       theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                                          bottomInset: Appearance.Cell.Inset.normal,
                                                          textAlignment: .natural,
                                                          titleFont: { Appearance.Cell.Text.standardFont },
                                                          separatorLeftInset: Appearance.Cell.leftMargin),
                                       selectionAction: { [weak self] _ in
            self?.didSelectOrigin(date: nil)
        })
        rows.append(noSymptomsRow)
        
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
                            self?.didSelectOrigin(date: date)
                         })
        }
        let dontKnowRow: CVRow = CVRow(title: "common.iDontKnow".localized,
                                       xibName: .standardCell,
                                       theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                                          bottomInset: Appearance.Cell.Inset.normal,
                                                          textAlignment: .natural,
                                                          titleFont: { Appearance.Cell.Text.standardFont },
                                                          separatorLeftInset: Appearance.Cell.leftMargin),
                                       selectionAction: { [weak self] _ in
                                        self?.didSelectOrigin(date: nil)
                                       })
        rows.append(contentsOf: originRows)
        rows.append(dontKnowRow)
        return [CVSection(rows: rows)]
    }
    
    private func initUI() {
        tableView.showsVerticalScrollIndicator = false
    }
    
    private func didSelectOrigin(date: Date?) {
        symptomsParams.symptomsDate = date
        didChooseDateBlock(symptomsParams)
    }
    
}

extension SymptomsOriginController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        reloadUI()
    }
    
}
