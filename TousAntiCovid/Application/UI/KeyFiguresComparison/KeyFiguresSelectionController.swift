// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFiguresSelectionController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 22/11/2021 - for the TousAntiCovid project.
//

import UIKit

final class KeyFiguresSelectionController: CVTableViewController {
    
    // MARK: - Constants
    private let didChose: (_ keyFigures: [KeyFigure]) -> ()
    private let didTouchFirstKeyFigure: (_ selectionDidUpdate: @escaping ([KeyFigure]) -> ()) -> ()
    private let didTouchSecondKeyFigure: (_ selectionDidUpdate: @escaping ([KeyFigure]) -> ()) -> ()
    private let didTouchClose: () -> ()
    private let deinitBlock: () -> ()
    
    // MARK: - Variables
    private var controller: UIViewController { bottomButtonContainerController ?? self }
    private var keyFiguresToChoose: [KeyFigure] { KeyFiguresManager.shared.keyFigures }
    private var previousKeyFiguresSelection: [KeyFigure]
    private var selectedKeyFigures: [KeyFigure] {
        didSet {
            updateBottomBarState()
        }
    }
    
    init(selectedKeyFigures: [KeyFigure],
         didTouchFirstKeyFigure: @escaping (_ selectionDidUpdate: @escaping ([KeyFigure]) -> ()) -> (),
         didTouchSecondKeyFigure: @escaping (_ selectionDidUpdate: @escaping ([KeyFigure]) -> ()) -> (),
         didChose: @escaping (_ keyFigures: [KeyFigure]) -> (),
         didTouchClose: @escaping () -> (),
         deinitBlock: @escaping () -> ()) {
        self.selectedKeyFigures = selectedKeyFigures
        self.previousKeyFiguresSelection = selectedKeyFigures
        self.didTouchFirstKeyFigure = didTouchFirstKeyFigure
        self.didTouchSecondKeyFigure = didTouchSecondKeyFigure
        self.didChose = didChose
        self.didTouchClose = didTouchClose
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        reloadUI()
        updateBottomBarButton()
    }
    
    deinit {
        deinitBlock()
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                keyFiguresSelectionRows()
            } header: {
                .groupedHeader
            }
        }
    }
}

// MARK: - UI
private extension KeyFiguresSelectionController {
    func initUI() {
        controller.title = "keyfigures.comparison.keyfiguresChoice.screen.title".localized
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.cancel".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        controller.navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }
    
    func updateBottomBarButton() {
        bottomButtonContainerController?.updateButton(title: "keyfigures.comparison.keyfiguresChoice.validation.button.title".localized) { [weak self] in
            guard let self = self else { return }
            self.didChose(self.selectedKeyFigures)
            self.dismiss(animated: true, completion: nil)
        }
        updateBottomBarState()
    }
    
    func updateBottomBarState() {
        bottomButtonContainerController?.setBottomBarHidden(selectedKeyFigures == previousKeyFiguresSelection, animated: true)
    }
}

// MARK: - Actions
private extension KeyFiguresSelectionController {
    @objc func didTouchCloseButton() {
        didTouchClose()
    }
}

// MARK: - Rows
private extension KeyFiguresSelectionController {
    func keyFiguresSelectionRows() -> [CVRow] {
        [sectionHeaderRow(title: "keyfigures.comparison.keyfiguresChoice.section.title".localized,
                          subtitle: "keyfigures.comparison.keyfiguresChoice.section.subtitle".localized),
        buttonRow(title: selectedKeyFigures[0].label,
                  image: Asset.Images.icon1.image,
                  separatorLeftInset: Appearance.Cell.leftMargin) { [weak self] in
            self?.didTouchFirstKeyFigure { [weak self] in
                self?.selectedKeyFigures = $0
                self?.reloadUI()
            }
        },
        buttonRow(title: selectedKeyFigures[1].label,
                  image: Asset.Images.icon2.image,
                  separatorLeftInset: .zero) { [weak self] in
            self?.didTouchSecondKeyFigure { [weak self] in
                self?.selectedKeyFigures = $0
                self?.reloadUI()
            }
        }]
    }
    
    func sectionHeaderRow(title: String, subtitle: String) -> CVRow {
        var textRow: CVRow = CVRow(title: title,
                                   subtitle: subtitle,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                                      bottomInset: Appearance.Cell.Inset.normal,
                                                      textAlignment: .natural,
                                                      titleFont: { Appearance.Cell.Text.smallHeadTitleFont },
                                                      separatorLeftInset: Appearance.Cell.leftMargin))
        textRow.theme.backgroundColor = Appearance.Cell.cardBackgroundColor
        return textRow
    }
    
    func buttonRow(title: String, image: UIImage, separatorLeftInset: CGFloat? = nil, isDestuctive: Bool = false, handler: @escaping () -> ()) -> CVRow {
        var buttonRow: CVRow = CVRow(title: title,
                                     image: image,
                                     xibName: .standardCell,
                                     theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                                        bottomInset: Appearance.Cell.Inset.normal,
                                                        textAlignment: .natural,
                                                        titleFont: { Appearance.Cell.Text.standardFont },
                                                        titleColor: isDestuctive ? Asset.Colors.error.color : Asset.Colors.tint.color,
                                                        imageTintColor: Appearance.tintColor,
                                                        imageSize: Appearance.Cell.Image.size,
                                                        separatorLeftInset: separatorLeftInset),
                                     selectionAction: { handler() },
                                     willDisplay: { cell in
            cell.cvTitleLabel?.accessibilityTraits = .button
        })
        buttonRow.theme.backgroundColor = Appearance.Cell.cardBackgroundColor
        return buttonRow
    }
}
