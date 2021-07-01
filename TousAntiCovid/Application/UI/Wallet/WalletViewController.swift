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
import PKHUD
import ServerSDK

final class WalletViewController: CVTableViewController {

    enum Mode {
        case empty
        case certificates
        case info
    }

    private var isFirstLoad: Bool = true
    private var initialUrlToProcess: URL?
    private let didTouchFlashCertificate: () -> ()
    private let didTouchTermsOfUse: () -> ()
    private let didTouchCertificate: (_ certificate: WalletCertificate) -> ()
    private let didRequestWalletScanAuthorization: (_ comingFromTheApp: Bool, _ completion: @escaping (_ granted: Bool) -> ()) -> ()
    private let didScanEuropeanCertifcate: (_ certificate: EuropeanCertificate) -> ()
    private let didTouchDocumentExplanation: (_ certificateType: WalletConstant.CertificateType) -> ()
    private let didTouchWhenToUse: () -> ()
    private let didGetCertificateError: (_ certificateType: WalletConstant.CertificateType, _ error: Error) -> ()
    private let didTouchConvertToEuropeTermsOfUse: () -> ()
    private let deinitBlock: () -> ()
    private var mode: Mode = .empty

    init(initialUrlToProcess: URL?,
         didTouchFlashCertificate: @escaping () -> (),
         didTouchTermsOfUse: @escaping () -> (),
         didTouchCertificate: @escaping (_ certificate: WalletCertificate) -> (),
         didRequestWalletScanAuthorization: @escaping (_ comingFromTheApp: Bool, _ completion: @escaping (_ granted: Bool) -> ()) -> (),
         didScanEuropeanCertifcate: @escaping (_ certificate: EuropeanCertificate) -> (),
         didTouchDocumentExplanation: @escaping (_ certificateType: WalletConstant.CertificateType) -> (),
         didTouchWhenToUse: @escaping () -> (),
         didGetCertificateError: @escaping (_ certificateType: WalletConstant.CertificateType, _ error: Error) -> (),
         didTouchConvertToEuropeTermsOfUse: @escaping () -> (),
         deinitBlock: @escaping () -> ()) {
        self.initialUrlToProcess = initialUrlToProcess
        self.didTouchFlashCertificate = didTouchFlashCertificate
        self.didTouchTermsOfUse = didTouchTermsOfUse
        self.didTouchCertificate = didTouchCertificate
        self.didRequestWalletScanAuthorization = didRequestWalletScanAuthorization
        self.didScanEuropeanCertifcate = didScanEuropeanCertifcate
        self.didTouchDocumentExplanation = didTouchDocumentExplanation
        self.didTouchWhenToUse = didTouchWhenToUse
        self.didGetCertificateError = didGetCertificateError
        self.didTouchConvertToEuropeTermsOfUse = didTouchConvertToEuropeTermsOfUse
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        (bottomButtonContainerController ?? self).title = "walletController.title".localized
        initUI()
        reloadUI()
        addObservers()
        updateBottomBarButton()
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
        (bottomButtonContainerController ?? self).navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
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
    
    private func updateBottomBarButton() {
        bottomButtonContainerController?.updateButton(title: "walletController.addCertificate".localized) { [weak self] in
            self?.didTouchFlashCertificate()
            self?.bottomButtonContainerController?.unlockButtons()
        }
    }
    
    override func createRows() -> [CVRow] {
        mode = calculateNewMode()
        var rows: [CVRow] = []
        switch mode {
        case .certificates:
            rows.append(contentsOf: headerRows())
            rows.append(contentsOf: certificatesRows())
        case .info:
            rows.append(contentsOf: headerRows())
            rows.append(contentsOf: infoRows())
        case .empty:
            rows.append(contentsOf: infoRows())
        }
        return rows
    }
    
    private func calculateNewMode() -> Mode {
        WalletManager.shared.walletCertificates.isEmpty ? .empty : (mode == .empty ? .certificates : mode)
    }
    
    private func infoRows() -> [CVRow] {
        let headerImageRow: CVRow = CVRow(image: Asset.Images.wallet.image,
                                          xibName: .imageCell,
                                          theme: CVRow.Theme(topInset: 40.0,
                                                             imageRatio: 375.0 / 155.0))
        let explanationsRow: CVRow = CVRow(title: "walletController.howDoesItWork.title".localized,
                                           subtitle: "walletController.howDoesItWork.subtitle".localized,
                                           xibName: .standardCardCell,
                                           theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                              topInset: 0.0,
                                                              bottomInset: 0.0,
                                                              textAlignment: .center,
                                                              titleFont: { Appearance.Cell.Text.headTitleFont }))
        let documentsRow: CVRow = CVRow(title: "walletController.documents.title".localized,
                                        subtitle: "walletController.documents.subtitle".localized,
                                        accessoryText: "walletController.documents.vaccin".localized,
                                        footerText: "walletController.documents.test".localized,
                                        image: WalletImagesManager.shared.image(named: .vaccinEuropeCertificate),
                                        secondaryImage: WalletImagesManager.shared.image(named: .testEuropeCertificate),
                                        xibName: .walletDocumentsCell,
                                        theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                           topInset: 15.0,
                                                           bottomInset: 0.0,
                                                           textAlignment: .center,
                                                           titleFont: { Appearance.Cell.Text.headTitleFont }),
                                        secondarySelectionAction: { [weak self] in
                                            self?.didTouchDocumentExplanation(.vaccinationEurope)
                                        },
                                        tertiarySelectionAction: { [weak self] in
                                            self?.didTouchDocumentExplanation(.sanitaryEurope)
                                        })
        let whenToUseRow: CVRow = CVRow(title: "walletController.whenToUse.title".localized,
                                        subtitle: "walletController.whenToUse.subtitle".localized,
                                        buttonTitle: "walletController.whenToUse.button".localized,
                                        xibName: .whenToUseCell,
                                        theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                           topInset: 15.0,
                                                           bottomInset: 0.0,
                                                           textAlignment: .center,
                                                           titleFont: { Appearance.Cell.Text.headTitleFont }),
                                        secondarySelectionAction: { [weak self] in
                                            self?.didTouchWhenToUse()
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
        return [headerImageRow,
                explanationsRow,
                documentsRow,
                whenToUseRow,
                phoneRow]
    }
    
    private func headerRows() -> [CVRow] {
        let certificatesModeSelectionAction: () -> () = { [weak self] in
            self?.mode = .certificates
            self?.reloadUI(animated: true, completion: nil)
        }
        let infoModeSelectionAction: () -> () = { [weak self] in
            self?.mode = .info
            self?.reloadUI(animated: true, completion: nil)
        }
        let modeSelectionRow: CVRow = CVRow(segmentsTitles: [String(format: "walletController.mode.myCertificates".localized, WalletManager.shared.walletCertificates.count),
                                                             "walletController.mode.info".localized],
                                            selectedSegmentIndex: mode == .certificates ? 0 : 1,
                                            xibName: .walletModeSelectionCell,
                                            theme:  CVRow.Theme(backgroundColor: .clear,
                                                                topInset: 30.0,
                                                                bottomInset: 4.0,
                                                                textAlignment: .natural,
                                                                titleFont: { Appearance.SegmentedControl.selectedFont },
                                                                subtitleFont: { Appearance.SegmentedControl.normalFont }),
                                            segmentsActions: [certificatesModeSelectionAction, infoModeSelectionAction])
        return [modeSelectionRow]
    }

    private func certificatesRows() -> [CVRow] {
        var rows: [CVRow] = []
        let recentCertificates: [WalletCertificate] = WalletManager.shared.recentWalletCertificates
        if !recentCertificates.isEmpty {
            let recentCertificatesSectionRow: CVRow = CVRow(title: "walletController.recentCertificatesSection.title".localized,
                                                            subtitle: "walletController.recentCertificatesSection.subtitle".localized,
                                                            xibName: .textCell,
                                                            theme: CVRow.Theme(topInset: 20.0,
                                                                               bottomInset: 0.0,
                                                                               textAlignment: .natural,
                                                                               titleFont: { Appearance.Cell.Text.headTitleFont }))
            rows.append(recentCertificatesSectionRow)
            rows.append(contentsOf: recentCertificates.sorted { $0.timestamp > $1.timestamp }.map { certificateRow(certificate: $0) })
        }

        let oldCertificates: [WalletCertificate] = WalletManager.shared.oldWalletCertificates
        if !oldCertificates.isEmpty {
            let oldCertificatesSectionRow: CVRow = CVRow(title: "walletController.oldCertificatesSection.title".localized,
                                                         subtitle: "walletController.oldCertificatesSection.subtitle".localized,
                                                         xibName: .textCell,
                                                         theme: CVRow.Theme(topInset: 40.0,
                                                                            bottomInset: 0.0,
                                                                            textAlignment: .natural,
                                                                            titleFont: { Appearance.Cell.Text.headTitleFont }))
            rows.append(oldCertificatesSectionRow)
            rows.append(contentsOf: oldCertificates.sorted { $0.timestamp > $1.timestamp }.map { certificateRow(certificate: $0) })
        }
        return rows
    }
    
    private func certificateRow(certificate: WalletCertificate) -> CVRow {
        return CVRow(title: certificate.codeImageTitle,
                     subtitle: certificate.fullDescription,
                     image: certificate.codeImage,
                     xibName: .sanitaryCertificateCell,
                     theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                        topInset: 20.0,
                                        bottomInset: 0.0,
                                        titleFont: { Appearance.Cell.Text.headTitleFont4 },
                                        subtitleFont: { Appearance.Cell.Text.subtitleFont }),
                     associatedValue: certificate.pillTitles,
                     selectionActionWithCell: { [weak self] cell in
                        self?.didTouchCertificateMenuButton(certificate: certificate, cell: cell)
                     },
                     selectionAction: { [weak self] in
                        self?.didTouchCertificate(certificate)
                     })
    }
    
    private func didTouchCertificateMenuButton(certificate: WalletCertificate, cell: CVTableViewCell) {
        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "walletController.menu.share".localized, style: .default, handler: { [weak self] _ in
            self?.showSanitaryCertificateSharing(image: cell.capture(), text: certificate.fullDescription ?? "")
        }))
        if ParametersManager.shared.displayCertificateConversion && [.sanitary, .vaccination].contains(certificate.type) {
            alertController.addAction(UIAlertAction(title: "walletController.menu.convertToEurope".localized, style: .default, handler: { [weak self] _ in
                if ParametersManager.shared.certificateConversionSidepOnlyCode.contains((certificate as? SanitaryCertificate)?.analysisRawCode ?? "") {
                    self?.showAntigenicCertificateAlert()
                } else {
                    self?.showConvertToEuropeAlert(certificate: certificate)
                }
            }))
        }
        alertController.addAction(UIAlertAction(title: "walletController.menu.delete".localized, style: .destructive, handler: { [weak self] _ in
            self?.showCertificateDeletionAlert(certificate: certificate)
        }))
        alertController.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel))
        present(alertController, animated: true)
    }

    private func showAntigenicCertificateAlert() {
        let alertController: UIAlertController = UIAlertController(title: "walletController.convertCertificate.antigenicAlert.title".localized,
                                                                   message: "walletController.convertCertificate.antigenicAlert.message".localized,
                                                                   preferredStyle: .alert)
        if let url = URL(string: "walletController.convertCertificate.antigenicAlert.urlLink".localized) {
            alertController.addAction(UIAlertAction(title: "walletController.convertCertificate.antigenicAlert.link".localized, style: .default, handler: { _ in url.openInSafari() }))
        }
        alertController.addAction(UIAlertAction(title: "common.ok".localized, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
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

    private func showConvertToEuropeAlert(certificate: WalletCertificate) {
        let alertController: UIAlertController = UIAlertController(title: "walletController.menu.convertToEurope.alert.title".localized,
                                                                   message: "walletController.menu.convertToEurope.alert.message".localized,
                                                                   preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "common.ok".localized,
                                                style: .default,
                                                handler: { [weak self] _ in
                                                    self?.processConvertToEurope(certificate)
                                                    AnalyticsManager.shared.reportAppEvent(.e20)
                                                }))
        alertController.addAction(UIAlertAction(title: "common.cancel".localized,
                                                style: .cancel,
                                                handler: nil))
        alertController.addAction(UIAlertAction(title: "walletController.menu.convertToEurope.alert.terms".localized,
                                                style: .default,
                                                handler: { [weak self] _ in
                                                    self?.didTouchConvertToEuropeTermsOfUse()
                                                }))

        present(alertController, animated: true, completion: nil)
    }

    private func processConvertToEurope(_ certificate: WalletCertificate) {
        HUD.show(.progress)
        WalletManager.shared.converToEurope(certificate: certificate) { [weak self] result in
            switch result {
            case let .success(certificate):
                HUD.flash(.success)
                self?.showCompletedVaccinationControllerIfNeeded(certificate: certificate)
            case let .failure(error):
                HUD.hide()
                AnalyticsManager.shared.reportError(serviceName: "certificateConversion", apiVersion: ParametersManager.shared.inGroupApiVersion, code: (error as NSError).code, desc: "\(error.localizedDescription) (\((error as NSError).code))")
                let message: String = "walletController.convertCertificate.error.message".localized
                self?.showConvertToEuropeErrorAlert(message: message)
            }
        }
    }

    private func showConvertToEuropeErrorAlert(message: String) {
        let alertController: UIAlertController = UIAlertController(title: "common.error.unknown".localized, message: message, preferredStyle: .alert)
        if let url1 = URL(string: "walletController.convertCertificate.error.url1".localized) {
            alertController.addAction(UIAlertAction(title: "walletController.convertCertificate.error.url1.title".localized, style: .default, handler: { _ in url1.openInSafari() }))
        }
        if let url2 = URL(string: "walletController.convertCertificate.error.url2".localized) {
            alertController.addAction(UIAlertAction(title: "walletController.convertCertificate.error.url2.title".localized, style: .default, handler: { _ in url2.openInSafari() }))
        }
        alertController.addAction(UIAlertAction(title: "common.ok".localized, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func processInitialUrlIfNeeded() {
        guard let url = initialUrlToProcess else { return }
        initialUrlToProcess = nil
        do {
            guard let certificate = try WalletManager.shared.getWalletCertificate(from: url) else { return }
            didRequestWalletScanAuthorization(DeepLinkingManager.shared.lastDeeplinkScannedDirectlyFromApp) { [weak self] granted in
                guard granted else { return }
                WalletManager.shared.saveCertificate(certificate)
                self?.showCompletedVaccinationControllerIfNeeded(certificate: certificate)
            }
        } catch {
            let certificateType: WalletConstant.CertificateType = WalletManager.certificateTypeFromHeaderInUrl(url) ?? .sanitary
            didGetCertificateError(certificateType, error)
        }
    }

    private func showCompletedVaccinationControllerIfNeeded(certificate: WalletCertificate) {
        guard let europeanCertificate = certificate as? EuropeanCertificate else { return }
        didScanEuropeanCertifcate(europeanCertificate)
    }

}

extension WalletViewController: WalletChangesObserver {

    func walletCertificatesDidUpdate() {
        mode = calculateNewMode()
        reloadUI(animated: true)
    }

}
