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
    var deinitBlock: (() -> ())?
    private var isFirstLoad: Bool = true
    private let didTouchFlashCertificate: () -> ()
    private let didTouchTermsOfUse: () -> ()
    private let didTouchCertificate: (_ certificate: WalletCertificate) -> ()
    private let didConvertToEuropeanCertifcate: (_ certificate: EuropeanCertificate) -> ()
    private let didTouchDocumentExplanation: (_ certificateType: WalletConstant.CertificateType) -> ()
    private let didTouchWhenToUse: () -> ()
    private let didTouchConvertToEuropeTermsOfUse: () -> ()
    private var mode: Mode = .empty
    private var mustScrollToTopAfterRefresh: Bool = false
    private weak var currentlyFocusedCertificate: WalletCertificate?
    private weak var currentlyFocusedCell: CVTableViewCell?

    init(didTouchFlashCertificate: @escaping () -> (),
         didTouchTermsOfUse: @escaping () -> (),
         didTouchCertificate: @escaping (_ certificate: WalletCertificate) -> (),
         didConvertToEuropeanCertifcate: @escaping (_ certificate: EuropeanCertificate) -> (),
         didTouchDocumentExplanation: @escaping (_ certificateType: WalletConstant.CertificateType) -> (),
         didTouchWhenToUse: @escaping () -> (),
         didTouchConvertToEuropeTermsOfUse: @escaping () -> (),
         deinitBlock: @escaping () -> ()) {
        self.didTouchFlashCertificate = didTouchFlashCertificate
        self.didTouchTermsOfUse = didTouchTermsOfUse
        self.didTouchCertificate = didTouchCertificate
        self.didConvertToEuropeanCertifcate = didConvertToEuropeanCertifcate
        self.didTouchDocumentExplanation = didTouchDocumentExplanation
        self.didTouchWhenToUse = didTouchWhenToUse
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
    }
    
    deinit {
        removeObservers()
        deinitBlock?()
    }
    
    private func initUI() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        let barButtonItem: UIBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        barButtonItem.accessibilityHint = "accessibility.closeModal.zGesture".localized
        (bottomButtonContainerController ?? self).navigationItem.leftBarButtonItem = barButtonItem
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
                                                             imageRatio: 375.0 / 116.0))
        let explanationsRow: CVRow = CVRow(title: "walletController.howDoesItWork.title".localized,
                                           subtitle: "walletController.howDoesItWork.subtitle".localized,
                                           xibName: .standardCardCell,
                                           theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                              topInset: 0.0,
                                                              bottomInset: 0.0,
                                                              textAlignment: .center,
                                                              titleFont: { Appearance.Cell.Text.headTitleFont }),
                                           accessibilityDidFocusCell: { [weak self] _ in
                                            self?.clearCurrentlyFocusedCellObjects()
                                           })
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
                                        accessibilityDidFocusCell: { [weak self] _ in
                                            self?.clearCurrentlyFocusedCellObjects()
                                        },
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
                                        accessibilityDidFocusCell: { [weak self] _ in
                                            self?.clearCurrentlyFocusedCellObjects()
                                        },
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
                                    accessibilityDidFocusCell: { [weak self] _ in
                                        self?.clearCurrentlyFocusedCellObjects()
                                    },
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
        var rows: [CVRow] = []
        if UIAccessibility.isVoiceOverRunning {
            let addCertificateRow: CVRow = CVRow(title: "walletController.addCertificate".localized,
                                                 xibName: .buttonCell,
                                                 theme: CVRow.Theme(topInset: 30.0, bottomInset: 0.0, buttonStyle: .primary),
                                                 selectionAction: { [weak self] in
                                                    self?.didTouchFlashCertificate()
                                                 })
            rows.append(addCertificateRow)
        }
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
                                            accessibilityDidFocusCell: { [weak self] _ in
                                                self?.clearCurrentlyFocusedCellObjects()
                                            },
                                            segmentsActions: [certificatesModeSelectionAction, infoModeSelectionAction])
        rows.append(modeSelectionRow)
        return rows
    }
    
    private func certificatesRows() -> [CVRow] {
        var rows: [CVRow] = []
        if WalletManager.shared.areThereCertificatesNeedingAttention {
            rows.append(CVRow(title: nil,
                              subtitle: "walletController.certificateWarning".localized,
                              xibName: .textCell,
                              theme: CVRow.Theme(topInset: 20.0,
                                                 bottomInset: 0.0,
                                                 textAlignment: .natural),
                              accessibilityDidFocusCell: { [weak self] _ in
                                self?.clearCurrentlyFocusedCellObjects()
                              }))
        }
        
        let favoriteCertificate: WalletCertificate? = WalletManager.shared.favoriteCertificate
        var favoriteEmptyText: String = "walletController.favoriteCertificateSection.subtitle".localized
        if #available(iOS 14.0, *) {
            favoriteEmptyText +=  "\n\n" + "walletController.favoriteCertificateSection.widget.ios".localized
        }
        let favoriteCertificateSectionRow: CVRow = CVRow(title: "walletController.favoriteCertificateSection.title".localized,
                                                         subtitle: favoriteCertificate == nil ? favoriteEmptyText : nil,
                                                         xibName: .textCell,
                                                         theme: CVRow.Theme(topInset: 20.0,
                                                                            bottomInset: 0.0,
                                                                            textAlignment: .natural,
                                                                            titleFont: { Appearance.Cell.Text.headTitleFont }),
                                                         accessibilityDidFocusCell: { [weak self] _ in
                                                            self?.clearCurrentlyFocusedCellObjects()
                                                         })
        rows.append(favoriteCertificateSectionRow)
        if let certificate = favoriteCertificate {
            rows.append(contentsOf: certificateRows(certificate: certificate))
            if #available(iOS 14.0, *) {
                let favoriteCertificateSectionRow: CVRow = CVRow(subtitle: "walletController.favoriteCertificateSection.widget.ios".localized,
                                                                 xibName: .textCell,
                                                                 theme: CVRow.Theme(topInset: 20.0,
                                                                                    bottomInset: 0.0,
                                                                                    textAlignment: .natural),
                                                                 accessibilityDidFocusCell: { [weak self] _ in
                                                                    self?.clearCurrentlyFocusedCellObjects()
                                                                 })
                rows.append(favoriteCertificateSectionRow)
            }
        }
        
        let recentCertificates: [WalletCertificate] = WalletManager.shared.recentWalletCertificates
        if !recentCertificates.isEmpty {
            let recentCertificatesSectionRow: CVRow = CVRow(title: "walletController.recentCertificatesSection.title".localized,
                                                            subtitle: "walletController.recentCertificatesSection.subtitle".localized,
                                                            xibName: .textCell,
                                                            theme: CVRow.Theme(topInset: 40.0,
                                                                               bottomInset: 0.0,
                                                                               textAlignment: .natural,
                                                                               titleFont: { Appearance.Cell.Text.headTitleFont }),
                                                            accessibilityDidFocusCell: { [weak self] _ in
                                                                self?.clearCurrentlyFocusedCellObjects()
                                                            })
            rows.append(recentCertificatesSectionRow)
            rows.append(contentsOf: recentCertificates.sorted { $0.timestamp > $1.timestamp }.map { certificateRows(certificate: $0) }.reduce([], +))
        }
        
        let oldCertificates: [WalletCertificate] = WalletManager.shared.oldWalletCertificates
        if !oldCertificates.isEmpty {
            let oldCertificatesSectionRow: CVRow = CVRow(title: "walletController.oldCertificatesSection.title".localized,
                                                         subtitle: "walletController.oldCertificatesSection.subtitle".localized,
                                                         xibName: .textCell,
                                                         theme: CVRow.Theme(topInset: recentCertificates.isEmpty ? 20.0 : 40.0,
                                                                            bottomInset: 0.0,
                                                                            textAlignment: .natural,
                                                                            titleFont: { Appearance.Cell.Text.headTitleFont }),
                                                         accessibilityDidFocusCell: { [weak self] _ in
                                                            self?.clearCurrentlyFocusedCellObjects()
                                                         })
            rows.append(oldCertificatesSectionRow)
            rows.append(contentsOf: oldCertificates.sorted { $0.timestamp > $1.timestamp }.map { certificateRows(certificate: $0) }.reduce([], +))
        }
        return rows
    }
    
    private func certificateRows(certificate: WalletCertificate) -> [CVRow] {
        var rows: [CVRow] = []
        let positiveTestWarning: String? = (certificate as? EuropeanCertificate)?.isTestNegative == false && certificate.type == .sanitaryEurope ? "wallet.proof.europe.test.positiveSidepError".localized : nil
        var subtitle: String = certificate.fullDescription ?? ""
        if DccBlacklistManager.shared.isBlacklisted(certificate: certificate) || Blacklist2dDocManager.shared.isBlacklisted(certificate: certificate) { subtitle += "\n\n\("wallet.blacklist.warning".localized)" }
        let certificateRow: CVRow = CVRow(title: certificate.codeImageTitle,
                                          subtitle: subtitle,
                                          accessoryText: positiveTestWarning,
                                          image: certificate.codeImage,
                                          isOn: certificate.id == WalletManager.shared.favoriteDccId,
                                          segmentsTitles: certificate.pillTitles,
                                          xibName: .sanitaryCertificateCell,
                                          theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                             topInset: 20.0,
                                                             bottomInset: 0.0,
                                                             titleFont: { Appearance.Cell.Text.headTitleFont4 },
                                                             subtitleFont: { Appearance.Cell.Text.subtitleFont },
                                                             accessoryTextFont: { Appearance.Cell.Text.subtitleFont },
                                                             maskedCorners: UIAccessibility.isVoiceOverRunning ? .all : .top),
                                          associatedValue: certificate,
                                          accessibilityDidFocusCell: { [weak self] cell in
                                            self?.currentlyFocusedCertificate = certificate
                                            self?.currentlyFocusedCell = cell
                                          },
                                          selectionActionWithCell: { [weak self] cell in
                                            self?.didTouchCertificateMenuButton(certificate: certificate, cell: cell)
                                          },
                                          selectionAction: { [weak self] in
                                            self?.didTouchCertificate(certificate)
                                          },
                                          secondarySelectionAction: certificate.type.format == .walletDCC ? { [weak self] in
                                            guard let self = self else { return }
                                            if certificate.id == WalletManager.shared.favoriteDccId {
                                                WalletManager.shared.removeFavorite()
                                            } else {
                                                self.mustScrollToTopAfterRefresh = true
                                                WalletManager.shared.setFavorite(certificate: certificate)
                                            }
                                          } : nil,
                                          willDisplay: { [weak self] cell in
                                            guard let self = self else { return }
                                            let isFavorite: Bool = certificate.id == WalletManager.shared.favoriteDccId
                                            var customActions: [UIAccessibilityCustomAction] = [
                                                UIAccessibilityCustomAction(name: "walletController.favoriteCertificateSection.openFullScreen".localized, target: self, selector: #selector(self.accessibilityDidActivateFullscreenAction)),
                                                UIAccessibilityCustomAction(name: "accessibility.wallet.dcc.favorite.\(isFavorite ? "remove" : "define")".localized, target: self, selector: #selector(self.accessibilityDidActivateFavoriteAction)),
                                                UIAccessibilityCustomAction(name: "walletController.menu.share".localized, target: self, selector: #selector(self.accessibilityDidActivateShareAction))
                                                ]
                                            if self.canShowConversionOption(for: certificate) {
                                                customActions.append(UIAccessibilityCustomAction(name: "walletController.menu.convertToEurope".localized, target: self, selector: #selector(self.accessibilityDidActivateConvertAction)))
                                            }
                                            customActions.append(UIAccessibilityCustomAction(name: "walletController.menu.delete".localized, target: self, selector: #selector(self.accessibilityDidActivateDeleteAction)))
                                            cell.accessibilityCustomActions = customActions
                                          })
        rows.append(certificateRow)
        if !UIAccessibility.isVoiceOverRunning {
            let actionRow: CVRow = CVRow(title: "walletController.favoriteCertificateSection.openFullScreen".localized,
                                         xibName: .standardCardCell,
                                         theme:  CVRow.Theme(backgroundColor: Appearance.Button.Secondary.backgroundColor,
                                                             topInset: 0.0,
                                                             bottomInset: 0.0,
                                                             textAlignment: .center,
                                                             titleFont: { Appearance.Cell.Text.actionTitleFont },
                                                             titleColor: Appearance.Button.Secondary.titleColor,
                                                             separatorLeftInset: nil,
                                                             separatorRightInset: nil,
                                                             maskedCorners: .bottom),
                                         accessibilityDidFocusCell: { [weak self] _ in
                                            self?.clearCurrentlyFocusedCellObjects()
                                         },
                                         selectionAction: { [weak self] in
                                            self?.didTouchCertificate(certificate)
                                         })
            rows.append(actionRow)
        }
        return rows
    }
    
    private func didTouchCertificateMenuButton(certificate: WalletCertificate, cell: CVTableViewCell) {
        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "walletController.menu.share".localized, style: .default, handler: { [weak self] _ in
            self?.showSanitaryCertificateSharing(image: cell.capture(), text: certificate.fullDescription ?? "")
        }))
        if canShowConversionOption(for: certificate) {
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

    private func canShowConversionOption(for certificate: WalletCertificate) -> Bool {
        ParametersManager.shared.displayCertificateConversion && [.sanitary, .vaccination].contains(certificate.type) && !Blacklist2dDocManager.shared.isBlacklisted(certificate: certificate)
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
        WalletManager.shared.convertToEurope(certificate: certificate) { [weak self] result in
            switch result {
            case let .success(certificate):
                HUD.flash(.success)
                self?.didConvertToEuropeanCertifcate(certificate)
            case let .failure(error):
                HUD.hide()
                AnalyticsManager.shared.reportError(serviceName: "certificateConversion", apiVersion: ParametersManager.shared.inGroupApiVersion, code: (error as NSError).code)
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

    func scrollTo(_ certificate: WalletCertificate) {
        guard let indexPath = getIndexPath(for: certificate) else { return }
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
    }

    private func getIndexPath(for certificate: WalletCertificate) -> IndexPath? {
        let rowIndex: Int? = rows.firstIndex { ($0.associatedValue as? WalletCertificate)?.id == certificate.id }
        guard let row = rowIndex else { return nil }
        return IndexPath(row: row, section: 0)
    }

    @objc private func accessibilityDidActivateFullscreenAction() {
        guard let certificate = currentlyFocusedCertificate else { return }
        didTouchCertificate(certificate)
    }

    @objc private func accessibilityDidActivateFavoriteAction() {
        guard let certificate = currentlyFocusedCertificate else { return }
        if certificate.id == WalletManager.shared.favoriteDccId {
            WalletManager.shared.removeFavorite()
        } else {
            self.mustScrollToTopAfterRefresh = true
            WalletManager.shared.setFavorite(certificate: certificate)
        }
    }

    @objc private func accessibilityDidActivateShareAction() {
        guard let certificate = currentlyFocusedCertificate else { return }
        showSanitaryCertificateSharing(image: currentlyFocusedCell?.capture(), text: certificate.fullDescription ?? "")
    }

    @objc private func accessibilityDidActivateConvertAction() {
        guard let certificate = currentlyFocusedCertificate else { return }
        if ParametersManager.shared.certificateConversionSidepOnlyCode.contains((certificate as? SanitaryCertificate)?.analysisRawCode ?? "") {
            showAntigenicCertificateAlert()
        } else {
            showConvertToEuropeAlert(certificate: certificate)
        }
    }

    @objc private func accessibilityDidActivateDeleteAction() {
        guard let certificate = currentlyFocusedCertificate else { return }
        showCertificateDeletionAlert(certificate: certificate)
    }

    private func clearCurrentlyFocusedCellObjects() {
        currentlyFocusedCertificate = nil
        currentlyFocusedCell = nil
    }

}

extension WalletViewController: WalletChangesObserver {
    
    func walletCertificatesDidUpdate() {
        mode = calculateNewMode()
        reloadUI(animated: true)
    }
    
    func walletFavoriteCertificateDidUpdate() {
        reloadUI(animated: false) { [weak self] in
            guard self?.mustScrollToTopAfterRefresh == true else { return }
            self?.mustScrollToTopAfterRefresh = false
            self?.tableView.scrollToTop()
        }
    }
    
}
