// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletAddCertificateViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit
import StorageSDK

final class WalletAddCertificateViewController: CVTableViewController {
    
    private let didTouchFlashCertificate: (_ certificateType: WalletConstant.CertificateType) -> ()
    private let didTouchDocumentExplanation: (_ certificateType: WalletConstant.CertificateType) -> ()
    private let deinitBlock: () -> ()
    
    init(didTouchFlashCertificate: @escaping (_ certificateType: WalletConstant.CertificateType) -> (),
         didTouchDocumentExplanation: @escaping (_ certificateType: WalletConstant.CertificateType) -> (),
         deinitBlock: @escaping () -> ()) {
        self.didTouchFlashCertificate = didTouchFlashCertificate
        self.didTouchDocumentExplanation = didTouchDocumentExplanation
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
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.delaysContentTouches = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    override func reloadUI(animated: Bool = false, completion: (() -> ())? = nil) {
        super.reloadUI(animated: animated, completion: completion)
    }
    
    override func createRows() -> [CVRow] {
        let testCertificateRow: CVRow = CVRow(title: "walletAddCertificateController.testCertificate.title".localized,
                                        subtitle: "walletAddCertificateController.testCertificate.subtitle".localized,
                                        image: WalletImagesManager.shared.image(named: .testCertificate),
                                        xibName: .walletAddCertificateCell,
                                        theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                           topInset: 20.0,
                                                           bottomInset: 0.0,
                                                           textAlignment: .natural),
                                        selectionAction: { [weak self] in
                                            CameraAuthorizationManager.requestAuthorization { granted, isFirstTimeRequest in
                                                if granted {
                                                    self?.didTouchFlashCertificate(.sanitary)
                                                } else if !isFirstTimeRequest {
                                                    self?.showAlert(title: "scanCodeController.camera.authorizationNeeded.title".localized,
                                                                    message: "scanCodeController.camera.authorizationNeeded.message".localized,
                                                                    okTitle: "common.settings".localized,
                                                                    cancelTitle: "common.cancel".localized, handler:  {
                                                                        UIApplication.shared.openSettings()
                                                                    })
                                                }
                                            }
                                        },
                                        secondarySelectionAction: { [weak self] in
                                            self?.didTouchDocumentExplanation(.sanitary)
                                        })
        let vaccinCertificateRow: CVRow = CVRow(title: "walletAddCertificateController.vaccinCertificate.title".localized,
                                     subtitle: "walletAddCertificateController.vaccinCertificate.subtitle".localized,
                                     image: WalletImagesManager.shared.image(named: .vaccinCertificate),
                                     xibName: .walletAddCertificateCell,
                                     theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                        topInset: 15.0,
                                                        bottomInset: 0.0,
                                                        textAlignment: .natural),
                                     selectionAction: { [weak self] in
                                        CameraAuthorizationManager.requestAuthorization { granted, isFirstTimeRequest in
                                            if granted {
                                                self?.didTouchFlashCertificate(.vaccination)
                                            } else if !isFirstTimeRequest {
                                                self?.showAlert(title: "scanCodeController.camera.authorizationNeeded.title".localized,
                                                                message: "scanCodeController.camera.authorizationNeeded.message".localized,
                                                                okTitle: "common.settings".localized,
                                                                cancelTitle: "common.cancel".localized, handler:  {
                                                                    UIApplication.shared.openSettings()
                                                                })
                                            }
                                        }
                                     },
                                     secondarySelectionAction: { [weak self] in
                                        self?.didTouchDocumentExplanation(.vaccination)
                                     })
        let explanationRow: CVRow = CVRow(title: "walletController.addCertificate.explanation".localized,
                                               xibName: .textCell,
                                               theme:  CVRow.Theme(topInset: 15.0,
                                                                   bottomInset: 0.0,
                                                                   textAlignment: .natural,
                                                                   titleFont: { Appearance.Cell.Text.footerFont },
                                                                   titleColor: Appearance.Cell.Text.captionTitleColor))
        let phoneRow: CVRow = CVRow(title: "walletController.phone.title".localized,
                                    subtitle: "walletController.phone.subtitle".localized,
                                    image: Asset.Images.walletPhone.image,
                                    xibName: .phoneCell,
                                    theme: CVRow.Theme(backgroundColor: Asset.Colors.secondaryButtonBackground.color,
                                                       topInset: 30.0,
                                                       bottomInset: 0.0,
                                                       textAlignment: .natural,
                                                       titleFont: { Appearance.Cell.Text.smallHeadTitleFont },
                                                       subtitleFont: { Appearance.Cell.Text.accessoryFont }),
                                    selectionAction: { [weak self] in
                                        guard let self = self else { return }
                                        "walletController.phone.number".localized.callPhoneNumber(from: self)
                                    })
        return [testCertificateRow, vaccinCertificateRow, explanationRow, phoneRow]
    }

}
