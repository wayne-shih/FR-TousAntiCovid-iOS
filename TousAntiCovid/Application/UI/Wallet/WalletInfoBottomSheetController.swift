// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletInfoBottomSheetController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 11/01/2022 - for the TousAntiCovid project.
//

import UIKit

final class WalletInfoBottomSheetController: BottomSheetedTableViewController {
    private let info: AdditionalInfo
    
    init(content: AdditionalInfo) {
        info = content
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
                contentRow()
            }
        }
    }
    
}

// MARK: - UI configuration
private extension WalletInfoBottomSheetController {
    func initUI() {
        addHeaderView()
        addFooterView(height: 8.0)
        tableView.backgroundColor = info.category.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
    }
}

// MARK: - Rows
private extension WalletInfoBottomSheetController {
    func contentRow() -> CVRow {
        let titleColor: UIColor
        switch info.category {
        case .info, .error:
            titleColor = .white
        case .warning:
            titleColor = .black
        }
        return CVRow(title: info.fullDescription,
                     xibName: .standardCell,
                     theme: .init(topInset: .zero,
                                  bottomInset: .zero,
                                  leftInset: Appearance.Cell.Inset.large,
                                  rightInset: Appearance.Cell.Inset.large,
                                  textAlignment: .natural,
                                  titleFont: { Appearance.Cell.Text.subtitleFont },
                                  titleColor: titleColor))
    }
}
