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
    private let didTouchCompare: () -> ()
    private let deinitBlock: () -> ()
    private var currentCategory: KeyFigure.Category = .vaccine
    
    init(didTouchReadExplanationsNow: @escaping () -> (),
         didTouchKeyFigure: @escaping(_ keyFigure: KeyFigure) -> (),
         didTouchCompare: @escaping () -> (),
         deinitBlock: @escaping () -> ()) {
        self.didTouchReadExplanationsNow = didTouchReadExplanationsNow
        self.didTouchKeyFigure = didTouchKeyFigure
        self.didTouchCompare = didTouchCompare
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
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        addHeaderView(height: Appearance.TableView.Header.mediumHeight)
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
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                if !KeyFiguresManager.shared.canShowCurrentlyNeededFile {
                    loadingErrorRows()
                }
                compareRow()
                modeSelectionRow()
                let explanations: String = "keyFiguresController.explanations.\(currentCategory.rawValue)".localized
                if !explanations.isEmpty {
                    explanationRows(explanations)
                }
                keyFiguresRows()
            }
        }
    }
    
}

// MARK: - Rows
private extension KeyFiguresController {
    func compareRow() -> CVRow {
        CVRow(title: "keyfigures.comparison.screen.title".localized,
              image: Asset.Images.compare.image,
              xibName: .standardCardCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: .zero,
                                 bottomInset: .zero,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.standardFont },
                                 titleColor: Appearance.Cell.Text.headerTitleColor,
                                 imageTintColor: Appearance.Cell.Text.headerTitleColor),
              selectionAction: { [weak self] _ in
            self?.didTouchCompare()
        })
    }
    
    func loadingErrorRows() -> [CVRow] {
        [CVRow(subtitle: "keyFiguresController.fetchError.message".localized,
              xibName: .cardCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.normal,
                                 bottomInset: .zero,
                                 textAlignment: .center,
                                 maskedCorners: .top),
              selectionAction: { _ in
            HUD.show(.progress)
            KeyFiguresManager.shared.fetchKeyFigures {
                HUD.hide()
            }
        }),
        CVRow(title: "keyFiguresController.fetchError.button".localized,
              xibName: .standardCardCell,
              theme:  CVRow.Theme(backgroundColor: Appearance.Button.Secondary.backgroundColor,
                                  topInset: .zero,
                                  bottomInset: .zero,
                                  textAlignment: .center,
                                  titleFont: { Appearance.Cell.Text.actionTitleFont },
                                  titleColor: Appearance.Button.Secondary.titleColor,
                                  separatorLeftInset: nil,
                                  separatorRightInset: nil,
                                  maskedCorners: .bottom),
              selectionAction: { _ in
            HUD.show(.progress)
            KeyFiguresManager.shared.fetchKeyFigures {
                HUD.hide()
            }
        })]
    }
    
    func explanationRows(_ explanations: String) -> [CVRow] {
        [CVRow(subtitle: explanations,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                 bottomInset: .zero,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.headTitleFont })),
        CVRow(buttonTitle: "common.readMore".localized,
              xibName: .linkButtonCell,
              theme:  CVRow.Theme(topInset: Appearance.Cell.Inset.small,
                                  bottomInset: .zero),
              secondarySelectionAction: { [weak self] in
            self?.didTouchReadExplanationsNow()
        })]
    }
    
    func keyFiguresRows() -> [CVRow] {
        KeyFiguresManager.shared.keyFigures.filter { $0.category == currentCategory && $0.isLabelReady }.map { keyFigure in
            return CVRow(title: keyFigure.label,
                         subtitle: keyFigure.description,
                         xibName: .keyFigureCell,
                         theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                            topInset: Appearance.Cell.Inset.medium,
                                            bottomInset: .zero,
                                            textAlignment: .natural,
                                            subtitleLinesCount: 2),
                         associatedValue: keyFigure,
                         selectionActionWithCell: { [weak self] cell in
                self?.didTouchSharingFor(cell: cell, keyFigure: keyFigure)
            },
                         selectionAction: { [weak self] _ in
                self?.didTouchKeyFigure(keyFigure)
            })
        }
    }
    
    func modeSelectionRow() -> CVRow {
        let allCategories: [KeyFigure.Category] = KeyFigure.Category.allCases
        return CVRow(segmentsTitles: allCategories.map { "keyFiguresController.category.\($0.rawValue)".localized },
                     selectedSegmentIndex: allCategories.firstIndex(of: currentCategory) ?? 0,
                     xibName: .segmentedCell,
                     theme:  CVRow.Theme(backgroundColor: .clear,
                                         topInset: Appearance.Cell.Inset.normal,
                                         bottomInset: Appearance.Cell.Inset.small / 2,
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
}

// MARK: - Actions
private extension KeyFiguresController {
    
    @objc func didTouchLocationButton() {
        KeyFiguresManager.shared.updateLocation(from: self)
    }

    func didTouchSharingFor(cell: CVTableViewCell, keyFigure: KeyFigure) {
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
