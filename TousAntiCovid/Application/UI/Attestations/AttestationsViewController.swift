// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AttestationsViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit
import StorageSDK

final class AttestationsViewController: CVTableViewController {
    
    private let didTouchNewAttestation: () -> ()
    private let didTouchTermsOfUse: () -> ()
    private let didTouchWebAttestation: () -> ()
    private let didTouchAttestationQrCode: (_ qrCode: UIImage, _ text: String) -> ()
    private let deinitBlock: () -> ()
    
    init(didTouchNewAttestation: @escaping () -> (),
         didTouchTermsOfUse: @escaping () -> (),
         didTouchWebAttestation: @escaping () -> (),
         didTouchAttestationQrCode: @escaping (_ qrCode: UIImage, _ text: String) -> (),
         deinitBlock: @escaping () -> ()) {
        self.didTouchNewAttestation = didTouchNewAttestation
        self.didTouchTermsOfUse = didTouchTermsOfUse
        self.didTouchWebAttestation = didTouchWebAttestation
        self.didTouchAttestationQrCode = didTouchAttestationQrCode
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        DeepLinkingManager.shared.attestationController = self
        title = "attestationsController.title".localized
        initUI()
        reloadUI()
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    private func initUI() {
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
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
    
    private func addObservers() {
        AttestationsManager.shared.addObserver(self)
    }
    
    private func removeObservers() {
        AttestationsManager.shared.removeObserver(self)
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let newAttestationRow: CVRow = CVRow(title: "attestationsController.newAttestation".localized,
                                             xibName: .buttonCell,
                                             theme: CVRow.Theme(topInset: 0.0, bottomInset: 0.0, buttonStyle: .primary),
                                             selectionAction: { [weak self] in
                                                self?.didTouchNewAttestation()
                                             })
        rows.append(newAttestationRow)
        let attestations: [Attestation] = AttestationsManager.shared.attestations.filter { !$0.isExpired }
        if !attestations.isEmpty {
            let attestationsSectionRow: CVRow = CVRow(title: "attestationsController.validAttestationsSection.title".localized,
                                                      xibName: .textCell,
                                                      theme: CVRow.Theme(topInset: 20.0,
                                                                         bottomInset: 0.0,
                                                                         textAlignment: .natural,
                                                                         titleFont: { Appearance.Cell.Text.headTitleFont }))
            rows.append(attestationsSectionRow)
            let attestationsExplanationRow: CVRow = CVRow(subtitle: "attestationsController.validAttestationsSection.subtitle".localized,
                                                          xibName: .textCell,
                                                          theme: CVRow.Theme(topInset: 20.0,
                                                                             bottomInset: 0.0,
                                                                             textAlignment: .natural))
            rows.append(attestationsExplanationRow)
            let attestationsRows: [CVRow] = attestations.map { attestation in
                CVRow(title: attestation.footer,
                      image: UIImage(data: attestation.qrCode),
                      xibName: .qrCodeCell,
                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                         topInset: 20.0,
                                         bottomInset: 0.0,
                                         titleFont: { Appearance.Cell.Text.subtitleFont }),
                      selectionActionWithCell: { [weak self] cell in
                        self?.didTouchAttestionMenuButton(attestation: attestation, cell: cell)
                      },
                      selectionAction: { [weak self] in
                        guard let qrCode = UIImage(data: attestation.qrCode) else { return }
                        self?.didTouchAttestationQrCode(qrCode, attestation.qrCodeString.isEmpty ? attestation.footer : attestation.qrCodeString)
                      })
            }
            rows.append(contentsOf: attestationsRows)
        }
        
        let expiredAttestations: [Attestation] = AttestationsManager.shared.attestations.filter { $0.isExpired }
        if !expiredAttestations.isEmpty {
            let attestationsSectionRow: CVRow = CVRow(title: "attestationsController.expiredSection.title".localized,
                                                      xibName: .textCell,
                                                      theme: CVRow.Theme(topInset: 20.0,
                                                                         bottomInset: 0.0,
                                                                         textAlignment: .natural,
                                                                         titleFont: { Appearance.Cell.Text.headTitleFont }))
            rows.append(attestationsSectionRow)
            let attestationsExplanationRow: CVRow = CVRow(subtitle: "attestationsController.expiredSection.subtitle".localized,
                                                          xibName: .textCell,
                                                          theme: CVRow.Theme(topInset: 20.0,
                                                                             bottomInset: 0.0,
                                                                             textAlignment: .natural))
            rows.append(attestationsExplanationRow)
            let attestationsRows: [CVRow] = expiredAttestations.map { attestation in
                CVRow(title: attestation.footer,
                      image: UIImage(data: attestation.qrCode),
                      xibName: .qrCodeCell,
                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                         topInset: 20.0,
                                         bottomInset: 0.0,
                                         titleFont: { Appearance.Cell.Text.subtitleFont }),
                      selectionActionWithCell: { [weak self] cell in
                        self?.didTouchAttestionMenuButton(attestation: attestation, cell: cell)
                      })
            }
            rows.append(contentsOf: attestationsRows)
        }
        let termsOfuseRow: CVRow = CVRow(buttonTitle: "attestationsController.termsOfUse".localized,
                                         xibName: .linkButtonCell,
                                         theme:  CVRow.Theme(topInset: 20.0,
                                                             bottomInset: 0.0),
                                         secondarySelectionAction: { [weak self] in
                                            self?.showTermsOfUseAlert()
                                         })
        rows.append(termsOfuseRow)
        let footerRow: CVRow = CVRow(title: "attestationController.footer".localized,
                                     xibName: .textCell,
                                     theme:  CVRow.Theme(topInset: 20.0,
                                                         bottomInset: 8.0,
                                                         textAlignment: .natural,
                                                         titleFont: { Appearance.Cell.Text.footerFont },
                                                         titleColor: Appearance.Cell.Text.captionTitleColor))
        rows.append(footerRow)
        let webAttestationRow: CVRow = CVRow(buttonTitle: "attestationsController.attestationWebSite".localized,
                                             xibName: .linkButtonCell,
                                             theme:  CVRow.Theme(topInset: 0.0,
                                                                 bottomInset: 20.0),
                                             secondarySelectionAction: { [weak self] in
                                                self?.didTouchWebAttestation()
                                             })
        rows.append(webAttestationRow)
        return rows
    }
    
    private func showTermsOfUseAlert() {
        showAlert(title: "attestationsController.termsOfUse.alert.title".localized,
                  message: "attestationsController.termsOfUse.alert.message".localized,
                  okTitle: "common.readMore".localized,
                  cancelTitle: "common.ok".localized, handler:  { [weak self] in
                    self?.didTouchTermsOfUse()
                  })
    }
    
    private func didTouchAttestionMenuButton(attestation: Attestation, cell: CVTableViewCell) {
        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if !attestation.isExpired {
            alertController.addAction(UIAlertAction(title: "attestationsController.menu.share".localized, style: .default, handler: { [weak self] _ in
                self?.showAttestationSharing(image: cell.capture(), text: attestation.qrCodeString)
            }))
        }
        alertController.addAction(UIAlertAction(title: "attestationsController.menu.delete".localized, style: .destructive, handler: { [weak self] _ in
            self?.showAttestationDeletionAlert(attestation: attestation)
        }))
        alertController.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel))
        present(alertController, animated: true)
    }
    
    private func showAttestationDeletionAlert(attestation: Attestation) {
        showAlert(title: "attestationsController.menu.delete.alert.title".localized,
                  message: "attestationsController.menu.delete.alert.message".localized,
                  okTitle: "common.ok".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.cancel".localized, handler: {
            AttestationsManager.shared.deleteAttestation(attestation)
        })
    }
    
    private func showAttestationSharing(image: UIImage?, text: String) {
        let activityItems: [Any?] = [text, "\n\n\("attestationsController.menu.share.text".localized)", image]
        let controller: UIActivityViewController = UIActivityViewController(activityItems: activityItems.compactMap { $0 }, applicationActivities: nil)
        controller.excludedActivityTypes = [.saveToCameraRoll, .print]
        present(controller, animated: true, completion: nil)
    }
    
}

extension AttestationsViewController: AttestationsChangesObserver {

    func attestationsDidUpdate() {
        reloadUI(animated: true)
    }

}
