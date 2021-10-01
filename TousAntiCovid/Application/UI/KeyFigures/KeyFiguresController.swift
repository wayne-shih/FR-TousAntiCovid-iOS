// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFiguresController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/09/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD

final class KeyFiguresController: CVTableViewController {
    
    private let didTouchKeyFigure: (_ keyFigure: KeyFigure) -> ()
    private let didTouchReadExplanationsNow: () -> ()
    private let deinitBlock: () -> ()
    private var currentCategory: KeyFigure.Category = .vaccine
    
    init(didTouchReadExplanationsNow: @escaping () -> (),
         didTouchKeyFigure: @escaping(_ keyFigure: KeyFigure) -> (),
         deinitBlock: @escaping () -> ()) {
        self.didTouchReadExplanationsNow = didTouchReadExplanationsNow
        self.didTouchKeyFigure = didTouchKeyFigure
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "keyFiguresController.title".localized
        initUI()
        reloadUI()
        addObservers()
    }
    
    deinit {
        removeObservers()
        deinitBlock()
    }
    
    private func initUI() {
        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
        updateRightBarButtonItem()
    }
    
    private func updateRightBarButtonItem() {
        if KeyFiguresManager.shared.displayDepartmentLevel {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.Images.location.image, style: .plain, target: self, action: #selector(didTouchLocationButton))
            navigationItem.rightBarButtonItem?.accessibilityLabel = "accessibility.hint.postalCode.button".localized
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    private func addObservers() {
        KeyFiguresManager.shared.addObserver(self)
    }
    
    private func removeObservers() {
        KeyFiguresManager.shared.removeObserver(self)
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        if !KeyFiguresManager.shared.canShowCurrentlyNeededFile {
            rows.append(CVRow(subtitle: "keyFiguresController.fetchError.message".localized,
                              xibName: .cardCell,
                              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                 topInset: 30.0,
                                                 bottomInset: 0.0,
                                                 textAlignment: .center,
                                                 maskedCorners: .top),
                              selectionAction: {
                                HUD.show(.progress)
                                KeyFiguresManager.shared.fetchKeyFigures {
                                    HUD.hide()
                                }
                              }))
            rows.append(CVRow(title: "keyFiguresController.fetchError.button".localized,
                              xibName: .standardCardCell,
                              theme:  CVRow.Theme(backgroundColor: Appearance.Button.Secondary.backgroundColor,
                                                  topInset: 0.0,
                                                  bottomInset: 0.0,
                                                  textAlignment: .center,
                                                  titleFont: { Appearance.Cell.Text.actionTitleFont },
                                                  titleColor: Appearance.Button.Secondary.titleColor,
                                                  separatorLeftInset: nil,
                                                  separatorRightInset: nil,
                                                  maskedCorners: .bottom),
                              selectionAction: {
                                HUD.show(.progress)
                                KeyFiguresManager.shared.fetchKeyFigures {
                                    HUD.hide()
                                }
                              }))
        }
        rows.append(modeSelectionRow())
        let explanations: String = "keyFiguresController.explanations.\(currentCategory.rawValue)".localized
        if !explanations.isEmpty {
            let explanationsRow: CVRow =  CVRow(subtitle: explanations,
                                                xibName: .textCell,
                                                theme: CVRow.Theme(topInset: 20.0,
                                                                   bottomInset: 0.0,
                                                                   textAlignment: .natural,
                                                                   titleFont: { Appearance.Cell.Text.headTitleFont }))
            rows.append(explanationsRow)
        }
        if currentCategory != .app {
            let readNowRow: CVRow = CVRow(buttonTitle: "common.readMore".localized,
                                          xibName: .linkButtonCell,
                                          theme:  CVRow.Theme(topInset: 12.0,
                                                              bottomInset: 0.0),
                                          secondarySelectionAction: { [weak self] in
                                            self?.didTouchReadExplanationsNow()
                                          })
            rows.append(readNowRow)
        }
        let keyFiguresRows: [CVRow] = KeyFiguresManager.shared.keyFigures.filter { $0.category == currentCategory }.compactMap { keyFigure in
            guard keyFigure.isLabelReady else { return nil }
            return CVRow(title: keyFigure.label,
                         subtitle: keyFigure.description,
                         xibName: .keyFigureCell,
                         theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                            topInset: 20.0,
                                            bottomInset: 0.0,
                                            textAlignment: .natural,
                                            subtitleLinesCount: 2),
                         associatedValue: keyFigure,
                         selectionActionWithCell: { [weak self] cell in
                            self?.didTouchSharingFor(cell: cell, keyFigure: keyFigure)
                         },
                         selectionAction: { [weak self] in
                            self?.didTouchKeyFigure(keyFigure)
                         })
        }
        rows.append(contentsOf: keyFiguresRows)
        return rows
    }

    private func modeSelectionRow() -> CVRow {
        let allCategories: [KeyFigure.Category] = KeyFigure.Category.allCases
        return CVRow(segmentsTitles: allCategories.map { "keyFiguresController.category.\($0.rawValue)".localized },
                     selectedSegmentIndex: allCategories.firstIndex(of: currentCategory) ?? 0,
                     xibName: .segmentedCell,
                     theme:  CVRow.Theme(backgroundColor: .clear,
                                         topInset: 30.0,
                                         bottomInset: 4.0,
                                         textAlignment: .natural,
                                         titleFont: { Appearance.SegmentedControl.selectedFont },
                                         subtitleFont: { Appearance.SegmentedControl.normalFont }),
                     segmentsActions: allCategories.map { category in
                        { [weak self] in
                            self?.currentCategory = category
                            self?.reloadUI(animated: true, completion: nil)
                        }
                     })
    }

    @objc private func didTouchLocationButton() {
        KeyFiguresManager.shared.updateLocation(from: self)
    }

    private func didTouchSharingFor(cell: CVTableViewCell, keyFigure: KeyFigure) {
        let sharingText: String
        if let keyFigureDepartment = keyFigure.currentDepartmentSpecificKeyFigure {
            sharingText = String(format: "keyFigure.sharing.department".localized,
                                 keyFigure.label,
                                 keyFigureDepartment.label,
                                 keyFigureDepartment.valueToDisplay,
                                 keyFigure.label,
                                 keyFigure.valueGlobalToDisplay)
        } else {
            sharingText = String(format: "keyFigure.sharing.national".localized,
                                 keyFigure.label,
                                 keyFigure.valueGlobalToDisplay)
        }
        let activityItems: [Any?] = [sharingText, KeyFigureCaptureView.captureKeyFigure(keyFigure)]
        let controller: UIActivityViewController = UIActivityViewController(activityItems: activityItems.compactMap { $0 }, applicationActivities: nil)
        controller.excludedActivityTypes = [.saveToCameraRoll, .print]
        present(controller, animated: true, completion: nil)
    }

}

extension KeyFiguresController: KeyFiguresChangesObserver {

    func keyFiguresDidUpdate() {
        reloadNextToKeyFiguresUpdate()
    }
    
    func postalCodeDidUpdate(_ postalCode: String?) {}
    
    private func reloadNextToKeyFiguresUpdate() {
        updateRightBarButtonItem()
        reloadUI(animated: true)
    }

}
