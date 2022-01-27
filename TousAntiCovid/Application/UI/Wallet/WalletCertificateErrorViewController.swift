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

    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                CVRow(title: "walletCertificateErrorController.explanations.\(error.localizedDescription).\(certificateType.textKey).title".localized,
                      subtitle: "walletCertificateErrorController.explanations.\(error.localizedDescription).\(certificateType.textKey).subtitle".localized,
                      xibName: .standardCardCell,
                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                         topInset: Appearance.Cell.Inset.medium,
                                         bottomInset: .zero,
                                         textAlignment: .center,
                                         titleFont: { Appearance.Cell.Text.headTitleFont }))
                documentImageRow()
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
                CVRow(title: "common.close".localized,
                      xibName: .buttonCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                         bottomInset: .zero,
                                         buttonStyle: .primary),
                      selectionAction: { [weak self] _ in
                    self?.didTouchCloseButton()
                })
            }
        }
    }
    private func documentImageRow() -> CVRow {
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
        case .activityEurope, .multiPass:
            documentImage = WalletImagesManager.shared.image(named: .vaccinEuropeCertificateFull)!
        case .exemptionEurope:
            documentImage = WalletImagesManager.shared.image(named: .vaccinEuropeCertificateFull)!
        case .unknown:
            documentImage = WalletImagesManager.shared.image(named: .vaccinEuropeCertificateFull)!
        }
        return CVRow(title: "walletCertificateErrorController.checkDocument.\(certificateType.textKey).title".localized,
                     subtitle: "walletCertificateErrorController.checkDocument.\(certificateType.textKey).subtitle".localized,
                     image: documentImage,
                     xibName: .checkDocumentCell,
                     theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                        topInset: Appearance.Cell.Inset.normal,
                                        bottomInset: .zero,
                                        textAlignment: .center,
                                        titleFont: { Appearance.Cell.Text.headTitleFont }),
                     selectionAction: { [weak self] _ in
            guard let self = self else { return }
            self.didTouchDocument(self.certificateType)
        })
    }

}
