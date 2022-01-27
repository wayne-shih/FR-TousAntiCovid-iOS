// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MultiPassGenerationErrorViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 19/01/2022 - for the TousAntiCovid project.
//

import UIKit

final class MultiPassGenerationErrorViewController: CVTableViewController {
    private let errorsCodes: [String]?
    private let didTouchClose: () -> ()
    private let deinitBlock: () -> ()
    
    init(errorsCodes: [String]?,
         didTouchClose: @escaping () -> (),
         deinitBlock: @escaping () -> ()) {
        self.errorsCodes = errorsCodes
        self.didTouchClose = didTouchClose
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }
    
    deinit {
        deinitBlock()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        reloadUI()
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                errorRow()
                phoneRow()
            }
        }
    }
}

// MARK: - Private functions
private extension MultiPassGenerationErrorViewController {
    func initUI() {
        title = "multiPass.generation.errorScreen.title".localized
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchLeftBarButtonItem))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }
    
    @objc func didTouchLeftBarButtonItem() {
        didTouchClose()
    }
}

// MARK: - Rows
private extension MultiPassGenerationErrorViewController {
    func errorRow() -> CVRow {
        CVRow(title: "multiPass.generation.errorScreen.explanation.title".localized,
              subtitle: String(format: "multiPass.generation.errorScreen.explanation.subtitle".localized, errorsCodes?.compactMap { ("multiPass.errors." + $0).localizedOrNil }.joined(separator: "\n") ?? ""),
              xibName: .standardCardCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.normal,
                                 bottomInset: .zero,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.headTitleFont }))
    }
    
    func phoneRow() -> CVRow {
        CVRow(title: "walletController.phone.title".localized,
              subtitle: "walletController.phone.subtitle".localized,
              image: Asset.Images.walletPhone.image,
              xibName: .phoneCell,
              theme: CVRow.Theme(backgroundColor: Asset.Colors.secondaryButtonBackground.color,
                                 topInset: Appearance.Cell.Inset.normal,
                                 bottomInset: .zero,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.smallHeadTitleFont },
                                 subtitleFont: { Appearance.Cell.Text.accessoryFont }),
              selectionAction: { [weak self] _ in
            guard let self = self else { return }
            "walletController.phone.number".localized.callPhoneNumber(from: self)
        })
    }
}
