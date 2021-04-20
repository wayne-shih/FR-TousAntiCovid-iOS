// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit
import StorageSDK

final class WalletViewController: CVTableViewController {
    
    private var isFirstLoad: Bool = true
    private var initialUrlToProcess: URL?
    private let didTouchFlashCertificate: () -> ()
    private let didTouchTermsOfUse: () -> ()
    private let didTouchCertificate: (_ dataMatrix: UIImage, _ text: String) -> ()
    private let didRequestWalletScanAuthorization: (_ completion: @escaping (_ granted: Bool) -> ()) -> ()
    private let deinitBlock: () -> ()
    
    init(initialUrlToProcess: URL?,
         didTouchFlashCertificate: @escaping () -> (),
         didTouchTermsOfUse: @escaping () -> (),
         didTouchCertificate: @escaping (_ dataMatrix: UIImage, _ text: String) -> (),
         didRequestWalletScanAuthorization: @escaping (_ completion: @escaping (_ granted: Bool) -> ()) -> (),
         deinitBlock: @escaping () -> ()) {
        self.initialUrlToProcess = initialUrlToProcess
        self.didTouchFlashCertificate = didTouchFlashCertificate
        self.didTouchTermsOfUse = didTouchTermsOfUse
        self.didTouchCertificate = didTouchCertificate
        self.didRequestWalletScanAuthorization = didRequestWalletScanAuthorization
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "walletController.title".localized
        initUI()
        reloadUI()
        addObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard isFirstLoad else {  return }
        isFirstLoad = false
        processInitialUrlIfNeeded()
    }
    
    deinit {
        removeObservers()
    }
    
    func processExternalUrl(_ url: URL) {
        initialUrlToProcess = url
        processInitialUrlIfNeeded()
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
    
    private func addObservers() {
        WalletManager.shared.addObserver(self)
    }
    
    private func removeObservers() {
        WalletManager.shared.removeObserver(self)
    }
    
    override func reloadUI(animated: Bool = false, completion: (() -> ())? = nil) {
        super.reloadUI(animated: animated, completion: completion)
    }
    
    override func createRows() -> [CVRow] {
        WalletManager.shared.walletCertificatesEmpty ? emptyScreenRows() : notEmptyScreenRows()
    }
    
    private func emptyScreenRows() -> [CVRow] {
        let headerImageRow: CVRow = CVRow(image: Asset.Images.wallet.image,
                                          xibName: .imageCell,
                                          theme: CVRow.Theme(topInset: 40.0,
                                                             imageRatio: 375.0 / 233.0))
        let explanationsRow: CVRow = CVRow(title: "walletController.explanations.title".localized,
                                           subtitle: "walletController.explanations.subtitle".localized,
                                           xibName: .standardCardCell,
                                           theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                              topInset: 0.0,
                                                              bottomInset: 10.0,
                                                              textAlignment: .center,
                                                              titleFont: { Appearance.Cell.Text.headTitleFont }))
        let flashExplanationRow: CVRow = CVRow(title: "walletController.noCertificates.flashExplanation".localized,
                                               xibName: .textCell,
                                               theme:  CVRow.Theme(topInset: 10.0,
                                                                   bottomInset: 0.0,
                                                                   textAlignment: .natural,
                                                                   titleFont: { Appearance.Cell.Text.footerFont },
                                                                   titleColor: Appearance.Cell.Text.captionTitleColor))
        return [headerImageRow,
                explanationsRow,
                flashSanitaryCertificateRow(),
                flashExplanationRow]
    }
    
    private func notEmptyScreenRows() -> [CVRow] {
        var rows: [CVRow] = []
        rows.append(flashSanitaryCertificateRow())
        let flashExplanationRow: CVRow = CVRow(title: "walletController.flashExplanation".localized,
                                               xibName: .textCell,
                                               theme:  CVRow.Theme(topInset: 20.0,
                                                                   bottomInset: 0.0,
                                                                   textAlignment: .natural,
                                                                   titleFont: { Appearance.Cell.Text.footerFont },
                                                                   titleColor: Appearance.Cell.Text.captionTitleColor))
        rows.append(flashExplanationRow)
        let recentCertificates: [WalletCertificate] = WalletManager.shared.walletCertificates.filter { !$0.isOld }
        if !recentCertificates.isEmpty {
            let recentCertificatesSectionRow: CVRow = CVRow(title: "walletController.recentCertificatesSection.title".localized,
                                                            subtitle: "walletController.recentCertificatesSection.subtitle".localized,
                                                            xibName: .textCell,
                                                            theme: CVRow.Theme(topInset: 40.0,
                                                                               bottomInset: 20.0,
                                                                               textAlignment: .natural,
                                                                               titleFont: { Appearance.Cell.Text.headTitleFont }))
            rows.append(recentCertificatesSectionRow)
            rows.append(contentsOf: recentCertificates.sorted { $0.timestamp > $1.timestamp }.map { certificateRow(certificate: $0) })
        }
        
        let oldCertificates: [WalletCertificate] = WalletManager.shared.walletCertificates.filter { $0.isOld }
        if !oldCertificates.isEmpty {
            let oldCertificatesSectionRow: CVRow = CVRow(title: "walletController.oldCertificatesSection.title".localized,
                                                         subtitle: "walletController.oldCertificatesSection.subtitle".localized,
                                                         xibName: .textCell,
                                                         theme: CVRow.Theme(topInset: 40.0,
                                                                            bottomInset: 20.0,
                                                                            textAlignment: .natural,
                                                                            titleFont: { Appearance.Cell.Text.headTitleFont }))
            rows.append(oldCertificatesSectionRow)
            rows.append(contentsOf: oldCertificates.sorted { $0.timestamp > $1.timestamp }.map { certificateRow(certificate: $0) })
        }
        return rows
    }
    
    private func flashSanitaryCertificateRow() -> CVRow {
        CVRow(title: "walletController.flashButton.title".localized,
              image: Asset.Images.add.image,
              xibName: .standardCardCell,
              theme:  CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                  topInset: 20.0,
                                  bottomInset: 0.0,
                                  textAlignment: .natural,
                                  titleFont: { Appearance.Cell.Text.standardFont },
                                  titleColor: Appearance.Cell.Text.headerTitleColor,
                                  imageTintColor: Appearance.Cell.Text.headerTitleColor),
              selectionAction: { [weak self] in
                self?.didTouchFlashCertificate()
              },
              willDisplay: { cell in
                cell.selectionStyle = .none
                cell.accessoryType = .none
              })
    }
    
    private func certificateRow(certificate: WalletCertificate) -> CVRow {
        let dataMatrix: UIImage? = certificate.value.dataMatrix()
        return CVRow(title: "2D-DOC",
                     subtitle: certificate.fullDescription,
                     accessoryText: certificate.pillTitle,
                     image: dataMatrix,
                     xibName: .sanitaryCertificateCell,
                     theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                        topInset: 20.0,
                                        bottomInset: 0.0,
                                        titleFont: { Appearance.Cell.Text.headTitleFont4 },
                                        subtitleFont: { Appearance.Cell.Text.subtitleFont }),
                     selectionActionWithCell: { [weak self] cell in
                        self?.didTouchCertificateMenuButton(certificate: certificate, cell: cell)
                     },
                     selectionAction: { [weak self] in
                        guard let dataMatrix = dataMatrix else { return }
                        self?.didTouchCertificate(dataMatrix, certificate.shortDescription)
                     })
    }
    
    private func didTouchCertificateMenuButton(certificate: WalletCertificate, cell: CVTableViewCell) {
        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "walletController.menu.share".localized, style: .default, handler: { [weak self] _ in
            self?.showSanitaryCertificateSharing(image: cell.capture(), text: certificate.fullDescription)
        }))
        alertController.addAction(UIAlertAction(title: "walletController.menu.delete".localized, style: .destructive, handler: { [weak self] _ in
            self?.showCertificateDeletionAlert(certificate: certificate)
        }))
        alertController.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel))
        present(alertController, animated: true)
    }
    
    private func showCertificateDeletionAlert(certificate: WalletCertificate) {
        showAlert(title: "walletController.menu.delete.alert.title".localized,
                  message: "walletController.menu.delete.alert.message".localized,
                  okTitle: "common.ok".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.cancel".localized, handler: {
                    WalletManager.shared.deleteCertificate(id: certificate.id)
        })
    }
    
    private func showSanitaryCertificateSharing(image: UIImage?, text: String) {
        let activityItems: [Any?] = ["\n\n\("walletController.menu.share.text".localized)", text, image]
        let controller: UIActivityViewController = UIActivityViewController(activityItems: activityItems.compactMap { $0 }, applicationActivities: nil)
        controller.excludedActivityTypes = [.saveToCameraRoll, .print]
        present(controller, animated: true, completion: nil)
    }
    
    private func processInitialUrlIfNeeded() {
        guard let url = initialUrlToProcess else { return }
        initialUrlToProcess = nil
        do {
            let certificate: WalletCertificate = try WalletManager.shared.extractCertificateFrom(url: url)
            didRequestWalletScanAuthorization { granted in
                guard granted == true else { return }
                WalletManager.shared.saveCertificate(certificate)
            }
        } catch {
            showWalletErrorAlert(error: error)
        }
    }

    private func showWalletErrorAlert(error: Error) {
        let alertTitle: String = "wallet.proof.error.\((error as NSError).code).title".localized
        let alertMessage: String = error.localizedDescription
        showAlert(title: alertTitle,
                  message: alertMessage,
                  okTitle: "common.ok".localized)
    }

}

extension WalletViewController: WalletChangesObserver {

    func walletCertificatesDidUpdate() {
        reloadUI(animated: true)
    }

}
