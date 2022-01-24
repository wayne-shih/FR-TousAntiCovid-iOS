// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  HomeInfoBottomSheetController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 17/01/2022 - for the TousAntiCovid project.
//

import UIKit

final class HomeInfoBottomSheetController: BottomSheetedTableViewController {
    private let info: Info
    private let didTouchOpenAllButton: () -> ()
    
    override var mode: BottomSheetedTableViewController.Mode { .twoPositions }
        
    init(content: Info, didTouchOpenAllButton: @escaping () -> ()) {
        info = content
        self.didTouchOpenAllButton = didTouchOpenAllButton
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                contentRow(for: info)
                buttonRow()
            }
        }
    }
    
}

// MARK: - UI configuration
private extension HomeInfoBottomSheetController {
    func initUI() {
        addFooterView(height: 8.0)
        tableView.backgroundColor = Appearance.Cell.cardBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
    }
}

// MARK: - Rows
private extension HomeInfoBottomSheetController {
    func contentRow(for info: Info) -> CVRow {
        CVRow(title: info.title,
              subtitle: info.description,
              accessoryText: info.formattedDate,
              buttonTitle: info.buttonLabel,
              xibName: .infoCell,
              theme: CVRow.Theme(backgroundColor: UIColor.clear,
                                 topInset: .zero,
                                 bottomInset: .zero,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.headTitleFont },
                                 titleHighlightFont: { Appearance.Cell.Text.subtitleBoldFont },
                                 titleHighlightColor: Appearance.Cell.Text.subtitleColor,
                                 subtitleFont: { Appearance.Cell.Text.subtitleFont },
                                 subtitleColor: Appearance.Cell.Text.subtitleColor),
              associatedValue: info,
              selectionActionWithCell: { [weak self] cell in
            self?.didTouchSharingFor(cell: cell, info: info)
        },
              secondarySelectionAction: {
            info.url?.openInSafari()
        })
    }
    
    func buttonRow() -> CVRow {
        CVRow(title: "homeInfo.bottomSheet.otherNews.button".localized,
              xibName: .buttonCell,
              theme: .init(buttonStyle: .tertiary),
              selectionAction: { [weak self] _ in
            self?.dismiss(animated: true) {
                self?.didTouchOpenAllButton()
            }
        })
    }
}

// MARK: - Private functions
private extension HomeInfoBottomSheetController {
    func didTouchSharingFor(cell: CVTableViewCell, info: Info) {
        let sharingText: String = String(format: "info.sharing.title".localized, info.title)
        let activityItems: [Any?] = [sharingText]
        let controller: UIActivityViewController = UIActivityViewController(activityItems: activityItems.compactMap { $0 }, applicationActivities: nil)
        controller.excludedActivityTypes = [.saveToCameraRoll, .print]
        present(controller, animated: true, completion: nil)
    }
}
