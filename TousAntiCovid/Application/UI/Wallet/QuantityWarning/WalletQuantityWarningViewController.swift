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
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Asset.Colors.error.color
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
    }

    override func createRows() -> [CVRow] {
        [
            titleRow(),
            explanationsRow(),
            continueRow(),
            cancelRow()
        ]
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
              theme: CVRow.Theme(topInset: 40.0,
                                 bottomInset: 0.0,
                                 titleFont: { .marianneExtraBold(size: 21.0) },
                                 titleColor: .white))
    }

    private func explanationsRow() -> CVRow {
        CVRow(title: "walletQuantityWarningController.explanation".localized,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: 30.0,
                                 bottomInset: 0.0,
                                 titleFont: { .regular(size: 17.0) },
                                 titleColor: .white))
    }

    private func continueRow() -> CVRow {
        CVRow(title: "walletQuantityWarningController.continue".localized,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: 30.0,
                                 bottomInset: 0.0,
                                 buttonStyle: .quinary),
              selectionAction: { [weak self] in
                self?.showConfirmationAlert()
              })
    }

    private func cancelRow() -> CVRow {
        CVRow(title: "common.cancel".localized,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: 10.0,
                                 bottomInset: 0.0,
                                 buttonStyle: .quinary),
              selectionAction: { [weak self] in
                self?.didCancel()
              })
    }

}
