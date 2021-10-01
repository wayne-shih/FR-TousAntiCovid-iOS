// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletCertificateErrorViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit
import StorageSDK

final class WalletCertificateErrorViewController: CVTableViewController {
    
    private let certificateType: WalletConstant.CertificateType
    private let error: Error
    private let didTouchDocument: (_ certificateType: WalletConstant.CertificateType) -> ()
    private let deinitBlock: () -> ()

    init(certificateType: WalletConstant.CertificateType, error: Error, didTouchDocument: @escaping (_ certificateType: WalletConstant.CertificateType) -> (), deinitBlock: @escaping () -> ()) {
        self.certificateType = certificateType
        self.error = error
        self.didTouchDocument = didTouchDocument
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
    }

    deinit {
        deinitBlock()
    }
    
    private func initUI() {
        title = "walletCertificateErrorController.title".localized
        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.delaysContentTouches = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }

    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    override func createRows() -> [CVRow] {
        let explanationsRow: CVRow = CVRow(title: "walletCertificateErrorController.explanations.\(error.localizedDescription).\(certificateType.textKey).title".localized,
                                           subtitle: "walletCertificateErrorController.explanations.\(error.localizedDescription).\(certificateType.textKey).subtitle".localized,
                                           xibName: .standardCardCell,
                                           theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                              topInset: 20.0,
                                                              bottomInset: 0.0,
                                                              textAlignment: .center,
                                                              titleFont: { Appearance.Cell.Text.headTitleFont }))
        let documentImage: UIImage
        switch certificateType {
        case .vaccination:
            documentImage = WalletImagesManager.shared.image(named: .vaccinCertificateFull)!
        case .sanitary:
            documentImage = WalletImagesManager.shared.image(named: .testCertificateFull)!
        case .sanitaryEurope:
            documentImage = WalletImagesManager.shared.image(named: .testEuropeCertificateFull)!
        case .vaccinationEurope:
            documentImage = WalletImagesManager.shared.image(named: .vaccinEuropeCertificateFull)!
        case .recoveryEurope:
            documentImage = WalletImagesManager.shared.image(named: .recoveryEuropeCertificateFull)!
        case .activityEurope:
            documentImage = WalletImagesManager.shared.image(named: .vaccinEuropeCertificateFull)!
        case .exemptionEurope:
            documentImage = WalletImagesManager.shared.image(named: .vaccinEuropeCertificateFull)!
        case .unknown:
            documentImage = UIImage()
        }
        let checkDocumentRow: CVRow = CVRow(title: "walletCertificateErrorController.checkDocument.\(certificateType.textKey).title".localized,
                                            subtitle: "walletCertificateErrorController.checkDocument.\(certificateType.textKey).subtitle".localized,
                                            image: documentImage,
                                        xibName: .checkDocumentCell,
                                        theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                           topInset: 15.0,
                                                           bottomInset: 0.0,
                                                           textAlignment: .center,
                                                           titleFont: { Appearance.Cell.Text.headTitleFont }),
                                        selectionAction: { [weak self] in
                                            guard let self = self else { return }
                                            self.didTouchDocument(self.certificateType)
                                        })
        let phoneRow: CVRow = CVRow(title: "walletController.phone.title".localized,
                                    subtitle: "walletController.phone.subtitle".localized,
                                    image: Asset.Images.walletPhone.image,
                                    xibName: .phoneCell,
                                    theme: CVRow.Theme(backgroundColor: Asset.Colors.secondaryButtonBackground.color,
                                                       topInset: 15.0,
                                                       bottomInset: 0.0,
                                                       textAlignment: .natural,
                                                       titleFont: { Appearance.Cell.Text.smallHeadTitleFont },
                                                       subtitleFont: { Appearance.Cell.Text.accessoryFont }),
                                    selectionAction: { [weak self] in
                                        guard let self = self else { return }
                                        "walletController.phone.number".localized.callPhoneNumber(from: self)
                                    })
        let closeRow: CVRow = CVRow(title: "common.close".localized,
                                    xibName: .buttonCell,
                                    theme: CVRow.Theme(topInset: 15.0, bottomInset: 0.0, buttonStyle: .primary),
                                    selectionAction: { [weak self] in
                                        self?.didTouchCloseButton()
                                    })
        return [explanationsRow, checkDocumentRow, phoneRow, closeRow]
    }

}
