// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFiguresChoiceController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 19/11/2021 - for the TousAntiCovid project.
//

import UIKit

final class KeyFiguresChoiceController: CVTableViewController {
    
    enum SelectionMode: Int {
        case keyFigure1
        case keyFigure2
        
        var controllerTitle: String {
            switch self {
            case .keyFigure1: return "keyfigures.comparison.keyfiguresList.screen.title1".localized
            case .keyFigure2: return "keyfigures.comparison.keyfiguresList.screen.title2".localized
            }
        }
        
        var controllerHeader: String {
            switch self {
            case .keyFigure1: return "keyfigures.comparison.keyfiguresList.screen.header1".localized
            case .keyFigure2: return "keyfigures.comparison.keyfiguresList.screen.header2".localized
            }
        }
    }
    
    private let keyFigures: [KeyFigure]
    private let selectedKeyFigures: [KeyFigure]
    private let didChose: (_ keyFigure: KeyFigure) -> ()
    private let deinitBlock: () -> ()
    private let mode: SelectionMode
    
    init(mode: SelectionMode, keyFigures: [KeyFigure], selected: [KeyFigure], didChose: @escaping (_ keyFigure: KeyFigure) -> (), deinitBlock: @escaping () -> ()) {
        self.keyFigures = keyFigures
        self.selectedKeyFigures = selected
        self.didChose = didChose
        self.deinitBlock = deinitBlock
        self.mode = mode
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        reloadUI()
    }
    
    deinit {
        deinitBlock()
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            let groupedKeyFigures: [KeyFigure.Category?: [KeyFigure]] = Dictionary(grouping: keyFigures) { $0.category }
            groupedKeyFigures.sorted { $0.key?.rawValue ?? "" > $1.key?.rawValue ?? "" }.map { group in
                CVSection(title: "keyFiguresController.category.\(group.key?.rawValue ?? "")".localized) {
                    group.value.compactMap { keyFigure in
                        standardRow(title: keyFigure.label,
                                    subtitle: keyFigure.description,
                                    image: selectionImage(for: keyFigure),
                                    isSelected: selectedKeyFigures.contains(keyFigure),
                                    isDisabled: shouldDisableRow(for: keyFigure),
                                    actionBlock: { [weak self] in
                            self?.didChose(keyFigure)
                        })
                    }
                }
            }
        }
    }
}

// MARK: - Utils
private extension KeyFiguresChoiceController {
    func initUI() {
        title = mode.controllerTitle
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
    }
    
    func standardRow(title: String, subtitle: String? = nil, image: UIImage? = nil, isSelected: Bool, isDisabled: Bool, actionBlock: @escaping () -> ()) -> CVRow {
        let row: CVRow = .init(title: title,
                               subtitle: subtitle,
                               image: image,
                               isOn: isSelected,
                               xibName: .keyFigureSelectionCell,
                               theme:  CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                   topInset: Appearance.Cell.Inset.normal,
                                                   bottomInset: Appearance.Cell.Inset.normal,
                                                   textAlignment: .natural,
                                                   titleFont: { Appearance.Cell.Text.standardFont },
                                                   titleColor: isDisabled ? .gray : Appearance.Cell.Text.headerTitleColor,
                                                   subtitleColor: isDisabled ? .lightGray : Appearance.Cell.Text.subtitleColor ,
                                                   subtitleLinesCount: 3,
                                                   imageTintColor: isDisabled ? .gray : Appearance.Cell.Text.headerTitleColor,
                                                   imageSize: Appearance.Cell.Image.size,
                                                   separatorLeftInset: Appearance.Cell.leftMargin),
                               selectionAction: isDisabled ? nil : {
            actionBlock()
        })
        return row
    }
    
    func selectionImage(for keyFigure: KeyFigure) -> UIImage? {
        guard let index: Int = selectedKeyFigures.firstIndex(of: keyFigure) else { return nil }
        return index == 0 ? Asset.Images.icon1.image : Asset.Images.icon2.image
    }
    
    func shouldDisableRow(for keyFigure: KeyFigure) -> Bool {
        guard let index: Int = selectedKeyFigures.firstIndex(of: keyFigure) else { return false }
        return index != mode.rawValue
    }
}
