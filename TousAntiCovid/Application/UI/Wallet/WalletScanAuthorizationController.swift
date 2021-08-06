// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletScanAuthorizationController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 13/01/2021 - for the TousAntiCovid project.
//

import UIKit

final class WalletScanAuthorizationController: CVTableViewController {

    private let comingFromTheApp: Bool
    private let didAnswer: (_ granted: Bool) -> ()

    init(comingFromTheApp: Bool, didAnswer: @escaping (_ granted: Bool) -> ()) {
        self.comingFromTheApp = comingFromTheApp
        self.didAnswer = didAnswer
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }

    deinit {
        LocalizationsManager.shared.removeObserver(self)
    }
    
    private func initUI() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
    }

    private func updateTitle() {
        title = "confirmWalletQrCodeController.title".localized
    }

    override func createRows() -> [CVRow] {
        let imageRow: CVRow = CVRow(image: Asset.Images.wallet.image,
                                    xibName: .imageCell,
                                    theme: CVRow.Theme(topInset: 80.0,
                                                       bottomInset: 40,
                                                       imageRatio: 375.0 / 116.0,
                                                       showImageBottomEdging: true))
        let explanationRow: CVRow = CVRow(title: comingFromTheApp ? "confirmWalletQrCodeController.explanation.title.fromUniversalQrScan".localized : "confirmWalletQrCodeController.explanation.title".localized,
                                          xibName: .textCell,
                                          theme: CVRow.Theme(topInset: 40.0,
                                                             bottomInset: 10.0,
                                                             textAlignment: .center,
                                                             titleFont: { Appearance.Cell.Text.standardFont }))
        let questionRow: CVRow = CVRow(title: "confirmWalletQrCodeController.explanation.subtitle".localized,
                                       xibName: .textCell,
                                       theme: CVRow.Theme(topInset: 10.0,
                                                          bottomInset: 20.0,
                                                          textAlignment: .center))
        let acceptRow: CVRow = CVRow(title: "confirmWalletQrCodeController.confirm".localized,
                                        xibName: .buttonCell,
                                        theme: CVRow.Theme(topInset: 20.0, bottomInset: 10.0),
                                        selectionAction: { [weak self] in
                                            self?.didAnswer(true)
                                        })
        let refuseRow: CVRow = CVRow(title: "common.cancel".localized,
                                        xibName: .buttonCell,
                                        theme: CVRow.Theme(topInset: 10.0,
                                                           bottomInset: 0.0,
                                                           buttonStyle: .destructive),
                                        selectionAction: { [weak self] in
                                            self?.didAnswer(false)
                                        })
        return [imageRow,
                explanationRow,
                questionRow,
                acceptRow,
                refuseRow]
    }

}

extension WalletScanAuthorizationController: LocalizationsChangesObserver {

    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }

}
