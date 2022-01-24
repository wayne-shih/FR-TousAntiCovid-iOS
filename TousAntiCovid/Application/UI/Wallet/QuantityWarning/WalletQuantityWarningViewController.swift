// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletQuantityWarningViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 19/08/2021 - for the TousAntiCovid project.
//

import UIKit

final class WalletQuantityWarningViewController: CVTableViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private let didConfirm: () -> ()
    private let didCancel: () -> ()

    init(didConfirm: @escaping () -> (), didCancel: @escaping () -> ()) {
        self.didConfirm = didConfirm
        self.didCancel = didCancel
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        reloadUI()
    }

    private func initUI() {
        tableView.backgroundColor = Asset.Colors.error.color
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                titleRow()
                explanationsRow()
                continueRow()
                cancelRow()
            }
        }
    }


    private func showConfirmationAlert() {
        showAlert(title: "walletQuantityWarningController.continueAlert.title".localized,
                  message: "walletQuantityWarningController.continueAlert.message".localized,
                  okTitle: "walletQuantityWarningController.continueAlert.confirm".localized,
                  cancelTitle: "common.cancel".localized) { [weak self] in
            self?.didConfirm()
        } cancelHandler: { [weak self] in
            self?.didCancel()
        }
    }

}

extension WalletQuantityWarningViewController {

    private func titleRow() -> CVRow {
        CVRow(title: "walletQuantityWarningController.title".localized,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                 bottomInset: .zero,
                                 titleFont: { .marianneExtraBold(size: 21.0) },
                                 titleColor: .white))
    }

    private func explanationsRow() -> CVRow {
        CVRow(title: "walletQuantityWarningController.explanation".localized,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.large,
                                 bottomInset: .zero,
                                 titleFont: { .regular(size: 17.0) },
                                 titleColor: .white))
    }

    private func continueRow() -> CVRow {
        CVRow(title: "walletQuantityWarningController.continue".localized,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.large,
                                 bottomInset: .zero,
                                 buttonStyle: .quinary),
              selectionAction: { [weak self] _ in
                self?.showConfirmationAlert()
              })
    }

    private func cancelRow() -> CVRow {
        CVRow(title: "common.cancel".localized,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.small,
                                 bottomInset: .zero,
                                 buttonStyle: .quinary),
              selectionAction: { [weak self] _ in
                self?.didCancel()
              })
    }

}
