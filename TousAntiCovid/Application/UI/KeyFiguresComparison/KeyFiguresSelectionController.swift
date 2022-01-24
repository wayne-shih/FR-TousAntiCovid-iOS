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
import ServerSDK

final class KeyFiguresSelectionController: CVTableViewController {
    
    // MARK: - Constants
    private let didChose: (_ keyFigures: [KeyFigure]) -> ()
    private let didTouchFirstKeyFigure: (_ selectionDidUpdate: @escaping ([KeyFigure]) -> ()) -> ()
    private let didTouchSecondKeyFigure: (_ selectionDidUpdate: @escaping ([KeyFigure]) -> ()) -> ()
    private let didTouchPredifinedCombination: (_ selection: [KeyFigure]) -> ()
    private let didTouchClose: () -> ()
    private let deinitBlock: () -> ()
    
    // MARK: - Variables
    private weak var firstKeyFigureCell: StandardCell?
    private weak var secondKeyFigureCell: StandardCell?
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
         didTouchPredifinedCombination: @escaping (_ selection: [KeyFigure]) -> (),
         didChose: @escaping (_ keyFigures: [KeyFigure]) -> (),
         didTouchClose: @escaping () -> (),
         deinitBlock: @escaping () -> ()) {
        self.selectedKeyFigures = selectedKeyFigures
        self.previousKeyFiguresSelection = selectedKeyFigures
        self.didTouchFirstKeyFigure = didTouchFirstKeyFigure
        self.didTouchSecondKeyFigure = didTouchSecondKeyFigure
        self.didTouchPredifinedCombination = didTouchPredifinedCombination
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
            
            CVSection {
                predefinedCombinationsRows()
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
        let firstButtonTitle: String = selectedKeyFigures.first?.label ?? "???"
        let secondButtonTitle: String = selectedKeyFigures.last?.label ?? "???"
        return [sectionHeaderRow(title: "keyfigures.comparison.keyfiguresChoice.section.title".localized,
                          subtitle: "keyfigures.comparison.keyfiguresChoice.section.subtitle".localized),
        buttonRow(title: firstButtonTitle,
                  image: Asset.Images.icon1.image,
                  separatorLeftInset: Appearance.Cell.leftMargin) { [weak self] in
            self?.didTouchFirstKeyFigure { [weak self] in
                self?.selectedKeyFigures = $0
                self?.reloadUI()
            }
        } willDisplayHandler: { [weak self] cell in
            self?.firstKeyFigureCell = cell as? StandardCell
        },
        buttonRow(title: secondButtonTitle,
                  image: Asset.Images.icon2.image,
                  separatorLeftInset: .zero) { [weak self] in
            self?.didTouchSecondKeyFigure { [weak self] in
                self?.selectedKeyFigures = $0
                self?.reloadUI()
            }
        } willDisplayHandler: { [weak self] cell in
            self?.secondKeyFigureCell = cell as? StandardCell
        }]
    }
    
    func predefinedCombinationsRows() -> [CVRow] {
        var rows: [CVRow] = []
        let combinationsRows: [CVRow]? = ParametersManager.shared.predefinedKeyFiguresSelection?.enumerated().compactMap { index, combination in
            guard let title = combination.titleKey.localizedOrNil else { return nil }
            guard let k1 = KeyFiguresManager.shared.keyFigure(for: combination.keyFigure1Key) else { return nil }
            guard let k2 = KeyFiguresManager.shared.keyFigure(for: combination.keyFigure2Key) else { return nil }
            let isSelected: Bool = selectedKeyFigures == [k1, k2]
            return CVRow(title: title,
                         image: nil,
                         xibName: .standardCell,
                         theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                            topInset: Appearance.Cell.Inset.normal,
                                            bottomInset: Appearance.Cell.Inset.normal,
                                            textAlignment: .natural,
                                            titleFont: { Appearance.Cell.Text.standardFont },
                                            titleColor: Asset.Colors.tint.color,
                                            imageTintColor: Appearance.tintColor,
                                            imageSize: Appearance.Cell.Image.size,
                                            separatorLeftInset: (index < ParametersManager.shared.predefinedKeyFiguresSelection?.count ?? 0) ? Appearance.Cell.leftMargin : nil),
                         selectionAction: { [weak self] _ in
                guard !isSelected else { return }
                self?.selectedKeyFigures = [k1, k2]
                self?.didTouchPredifinedCombination([k1, k2])
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                self?.reloadUI(animated: true, animatedView: nil, completion: {
                    self?.firstKeyFigureCell?.bounceImage()
                    self?.secondKeyFigureCell?.bounceImage()
                })
            },
                         willDisplay: { cell in
                cell.tintColor = Appearance.tintColor
                cell.selectionStyle = isSelected ? .none : .default
                cell.accessoryType = isSelected ? .checkmark : .none
                cell.cvTitleLabel?.accessibilityTraits = .button
            })
        }
        if let combinationsRows = combinationsRows, !combinationsRows.isEmpty {
            rows.append(sectionHeaderRow(title: "keyfigures.comparison.keyfiguresCombination.section.title".localized,
                                         subtitle: "keyfigures.comparison.keyfiguresCombination.section.subtitle".localized))
            rows.append(contentsOf: combinationsRows)
        }
        return rows
    }
    
    func sectionHeaderRow(title: String, subtitle: String) -> CVRow {
        CVRow(title: title,
              subtitle: subtitle,
              xibName: .textCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.normal,
                                 bottomInset: Appearance.Cell.Inset.normal,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.smallHeadTitleFont },
                                 separatorLeftInset: Appearance.Cell.leftMargin))
    }
    
    func buttonRow(title: String, image: UIImage, separatorLeftInset: CGFloat? = nil, handler: @escaping () -> (), willDisplayHandler: ((_ cell: CVTableViewCell) -> ())?) -> CVRow {
        CVRow(title: title,
              image: image,
              xibName: .standardCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.normal,
                                 bottomInset: Appearance.Cell.Inset.normal,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.standardFont },
                                 titleColor: Asset.Colors.tint.color,
                                 imageTintColor: Appearance.tintColor,
                                 imageSize: Appearance.Cell.Image.size,
                                 separatorLeftInset: separatorLeftInset),
              selectionAction: { _ in handler() },
              willDisplay: { cell in
            cell.cvTitleLabel?.accessibilityTraits = .button
            willDisplayHandler?(cell)
        })
    }
}

private extension StandardCell {
    func bounceImage() {
        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut) { [weak self] in
            self?.cvImageView?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        } completion: { _ in
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseIn) { [weak self] in
                self?.cvImageView?.transform = .identity
            } completion: { _ in }
        }
    }
}
