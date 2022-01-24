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
    var deinitBlock: (() -> ())?
    
    private var controller: UIViewController {
        bottomButtonContainerController ?? self
    }
    
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
        initUI()
        reloadUI()
        addObservers()
        updateBottomBarButton()
    }
    
    deinit {
        removeObservers()
    }
    
    private func initUI() {
        controller.title = "attestationsController.title".localized
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.delaysContentTouches = false
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        controller.navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }
    
    private func updateBottomBarButton() {
        bottomButtonContainerController?.updateButton(title: "attestationsController.newAttestation".localized) { [weak self] in
            self?.didTouchNewAttestation()
            self?.bottomButtonContainerController?.unlockButtons()
        }
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
    
    override func createSections() -> [CVSection] {
        makeSections {
            if AttestationsManager.shared.attestations.isEmpty {
               headerSection()
            }
            let attestations: [Attestation] = AttestationsManager.shared.attestations.filter { !$0.isExpired }
            if !attestations.isEmpty {
                availableAttestations(attestations: attestations)
            }
            let expiredAttestations: [Attestation] = AttestationsManager.shared.attestations.filter { $0.isExpired }
            if !expiredAttestations.isEmpty {
                expiredSection(attestations: expiredAttestations)
            }
            linksSection()
        }
    }
    
    private func headerSection() -> CVSection {
        CVSection {
            if UIAccessibility.isVoiceOverRunning {
                CVRow(title: "attestationsController.newAttestation".localized,
                                                     xibName: .buttonCell,
                                                     theme: CVRow.Theme(topInset: Appearance.Cell.Inset.large,
                                                                        bottomInset: .zero,
                                                                        buttonStyle: .primary),
                                                     selectionAction: { [weak self] _ in
                    self?.didTouchNewAttestation()
                })
            }
            CVRow(image: Asset.Images.attestation.image,
                  xibName: .imageCell,
                  theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                     imageRatio: 375.0 / 116.0))
            CVRow(title: "attestationController.header.title".localized,
                  subtitle: "attestationController.header.subtitle".localized,
                  xibName: .paragraphCell,
                  theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                     topInset: .zero,
                                     bottomInset: .zero,
                                     textAlignment: .natural,
                                     titleFont: { Appearance.Cell.Text.headTitleFont })
            )
        }
    }
    
    private func availableAttestations(attestations: [Attestation]) -> CVSection {
        CVSection(title: "attestationsController.validAttestationsSection.title".localized) {
            CVRow(subtitle: "attestationsController.validAttestationsSection.subtitle".localized,
                  xibName: .textCell,
                  theme: CVRow.Theme(topInset: .zero,
                                     bottomInset: .zero,
                                     textAlignment: .natural))
            attestations.map { attestation in
                CVRow(title: attestation.footer,
                      image: UIImage(data: attestation.qrCode),
                      xibName: .qrCodeCell,
                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                         topInset: Appearance.Cell.Inset.medium,
                                         bottomInset: .zero,
                                         titleFont: { Appearance.Cell.Text.subtitleFont }),
                      selectionActionWithCell: { [weak self] cell in
                    self?.didTouchAttestionMenuButton(attestation: attestation, cell: cell)
                },
                      selectionAction: { [weak self] _ in
                    guard let qrCode = UIImage(data: attestation.qrCode) else { return }
                    self?.didTouchAttestationQrCode(qrCode, attestation.qrCodeString.isEmpty ? attestation.footer : attestation.qrCodeString)
                })
            }
        }
    }
    
    private func expiredSection(attestations: [Attestation]) -> CVSection {
        CVSection(title: "attestationsController.expiredSection.title".localized) {
            CVRow(subtitle: "attestationsController.expiredSection.subtitle".localized,
                  xibName: .textCell,
                  theme: CVRow.Theme(topInset: .zero,
                                     bottomInset: .zero,
                                     textAlignment: .natural))
            attestations.map { attestation in
                CVRow(title: attestation.footer,
                      image: UIImage(data: attestation.qrCode),
                      xibName: .qrCodeCell,
                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                         topInset: Appearance.Cell.Inset.medium,
                                         bottomInset: .zero,
                                         titleFont: { Appearance.Cell.Text.subtitleFont }),
                      selectionActionWithCell: { [weak self] cell in
                    self?.didTouchAttestionMenuButton(attestation: attestation, cell: cell)
                })
            }
        }
    }
    
    private func linksSection() -> CVSection {
        CVSection(title: "attestationController.plusSection.title".localized,
                  footerTitle: "attestationController.footer".localized,
                  rows: [
                    standardCardRow(title: "attestationsController.termsOfUse".localized,
                                    image: Asset.Images.conditions.image,
                                    actionBlock: { [weak self] in
                                        self?.showTermsOfUseAlert()
                                    }),
                    standardCardRow(title: "attestationsController.attestationWebSite".localized,
                                    image: Asset.Images.compassToured.image,
                                    bottomInset: .zero,
                                    actionBlock: { [weak self] in
                                        self?.didTouchWebAttestation()
                                    })
                  ])
    }
    
    private func standardCardRow(title: String, subtitle: String? = nil, image: UIImage, bottomInset: CGFloat = Appearance.Cell.Inset.normal, actionBlock: @escaping () -> ()) -> CVRow {
        let row: CVRow = CVRow(title: title,
                               subtitle: subtitle,
                               image: image,
                               xibName: .standardCardCell,
                               theme:  CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                   topInset: .zero,
                                                   bottomInset: bottomInset,
                                                   textAlignment: .natural,
                                                   titleFont: { Appearance.Cell.Text.standardFont },
                                                   titleColor: Appearance.Cell.Text.headerTitleColor,
                                                   imageTintColor: Appearance.Cell.Text.headerTitleColor),
                               selectionAction: { _ in
            actionBlock()
        })
        return row
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
