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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .screenChanged, argument: self.navigationController?.navigationBar)
    }

    deinit {
        LocalizationsManager.shared.removeObserver(self)
    }
    
    private func initUI() {
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
    }

    private func updateTitle() {
        title = "confirmWalletQrCodeController.title".localized
    }

    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                CVRow(image: Asset.Images.wallet.image,
                      xibName: .imageCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.large,
                                         bottomInset: .zero,
                                         imageRatio: 375.0 / 116.0,
                                         showImageBottomEdging: true))
                CVRow(title: comingFromTheApp ? "confirmWalletQrCodeController.explanation.title.fromUniversalQrScan".localized : "confirmWalletQrCodeController.explanation.title".localized,
                      xibName: .textCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                         bottomInset: .zero,
                                         textAlignment: .center,
                                         titleFont: { Appearance.Cell.Text.standardFont }))
                CVRow(title: "confirmWalletQrCodeController.explanation.subtitle".localized,
                      xibName: .textCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                         bottomInset: Appearance.Cell.Inset.medium,
                                         textAlignment: .center))
                CVRow(title: "confirmWalletQrCodeController.confirm".localized,
                      xibName: .buttonCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium, bottomInset: Appearance.Cell.Inset.small),
                      selectionAction: { [weak self] in
                    self?.didAnswer(true)
                })
                CVRow(title: "common.cancel".localized,
                      xibName: .buttonCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.small,
                                         bottomInset: .zero,
                                         buttonStyle: .destructive),
                      selectionAction: { [weak self] in
                    self?.didAnswer(false)
                })
            }
        }
    }
    
}

extension WalletScanAuthorizationController: LocalizationsChangesObserver {

    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }

}
