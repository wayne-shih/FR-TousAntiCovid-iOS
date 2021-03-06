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
    
    private enum Mode {
        case empty
        case certificates
        case multiPass
        case info
        
        var selectedIndex: Int {
            switch self {
            case .empty, .certificates: return 0
            case .multiPass: return 1
            case .info: return 2
            }
        }
    }
    
    var deinitBlock: (() -> ())?
    private let didTouchFlashCertificate: () -> ()
    private let didTouchCertificate: (_ certificate: WalletCertificate) -> ()
    private let didConvertToEuropeanCertifcate: (_ certificate: EuropeanCertificate) -> ()
    private let didTouchDocumentExplanation: (_ certificateType: WalletConstant.CertificateType) -> ()
    private let didTouchWhenToUse: () -> ()
    private let didTouchMultiPassMoreInfo: () -> ()
    private let didTouchMultiPassInstructions: () -> ()
    private let didTouchContinueOnFraud: () -> ()
    private let didTouchConvertToEuropeTermsOfUse: () -> ()
    private let didTouchCertificateAdditionalInfo: (_ info: AdditionalInfo) -> ()
    private let didSelectProfileForMultiPass: (_ certificates: [EuropeanCertificate]) -> ()
    private var mode: Mode = .empty {
        didSet {
            updateBottomBarButton()
        }
    }
    private var mustScrollToTopAfterRefresh: Bool = false
    private var shouldHideCellImage: Bool {
        UIScreen.main.bounds.width < 375.0 ||
        [.accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge,
            .extraLarge,
            .extraExtraLarge,
            .extraExtraExtraLarge].contains(UIApplication.shared.preferredContentSizeCategory)
    }
    private weak var currentlyFocusedCertificate: WalletCertificate?
    private weak var currentlyFocusedCell: CVTableViewCell?

    init(didTouchFlashCertificate: @escaping () -> (),
         didTouchCertificate: @escaping (_ certificate: WalletCertificate) -> (),
         didConvertToEuropeanCertifcate: @escaping (_ certificate: EuropeanCertificate) -> (),
         didTouchDocumentExplanation: @escaping (_ certificateType: WalletConstant.CertificateType) -> (),
         didTouchWhenToUse: @escaping () -> (),
         didTouchMultiPassMoreInfo: @escaping () -> (),
         didTouchMultiPassInstructions: @escaping () -> (),
         didTouchContinueOnFraud: @escaping () -> (),
         didTouchConvertToEuropeTermsOfUse: @escaping () -> (),
         didTouchCertificateAdditionalInfo: @escaping (_ info: AdditionalInfo) -> (),
         didSelectProfileForMultiPass: @escaping (_ certificates: [EuropeanCertificate]) -> (),
         deinitBlock: @escaping () -> ()) {
        self.didTouchFlashCertificate = didTouchFlashCertificate
        self.didTouchCertificate = didTouchCertificate
        self.didConvertToEuropeanCertifcate = didConvertToEuropeanCertifcate
        self.didTouchDocumentExplanation = didTouchDocumentExplanation
        self.didTouchWhenToUse = didTouchWhenToUse
        self.didTouchMultiPassMoreInfo = didTouchMultiPassMoreInfo
        self.didTouchMultiPassInstructions = didTouchMultiPassInstructions
        self.didTouchContinueOnFraud = didTouchContinueOnFraud
        self.didTouchConvertToEuropeTermsOfUse = didTouchConvertToEuropeTermsOfUse
        self.didTouchCertificateAdditionalInfo = didTouchCertificateAdditionalInfo
        self.didSelectProfileForMultiPass = didSelectProfileForMultiPass
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
    
    deinit {
        removeObservers()
        deinitBlock?()
    }
    
    private func initUI() {
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
        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.reloadUI()
        }
    }
    
    private func removeObservers() {
        WalletManager.shared.removeObserver(self)
    }
    
    private func updateBottomBarButton() {
        bottomButtonContainerController?.setBottomBarHidden(mode == .info, animated: true)
        switch mode {
        case .multiPass:
            bottomButtonContainerController?.updateButton(title: "multiPass.tab.generation.button.title".localized) { [weak self] in
                self?.openProfilesAlert()
                self?.bottomButtonContainerController?.unlockButtons()
            }
        default:
            bottomButtonContainerController?.updateButton(title: "walletController.addCertificate".localized) { [weak self] in
                self?.openQRScan()
                self?.bottomButtonContainerController?.unlockButtons()
            }
        }
    }
    
    override func createSections() -> [CVSection] {
        mode = calculateNewMode()
        return makeSections {
            CVSection {
                switch mode {
                case .certificates:
                    headerRows()
                    certificatesRows()
                case .multiPass:
                    headerRows()
                    multiPassInfoRows()
                case .info:
                    headerRows()
                    infoRows()
                case .empty:
                    infoRows()
                }
            }
        }
    }
    
    private func calculateNewMode() -> Mode {
        WalletManager.shared.walletCertificates.isEmpty ? .empty : (mode == .empty ? .certificates : mode)
    }
    
    private func multiPassInfoRows() -> [CVRow] {
        let url: URL? = URL(string: "multiPass.tab.explanation.url".localized)
        let explanationsRow: CVRow = .init(title: "multiPass.tab.explanation.title".localized,
                                           subtitle: "multiPass.tab.explanation.subtitle".localized,
                                           buttonTitle: url == nil ? nil : "multiPass.tab.explanation.linkButton.title".localized,
                                           xibName: .paragraphCell,
                                           theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                              topInset: Appearance.Cell.Inset.normal,
                                                              bottomInset: .zero,
                                                              textAlignment: .natural,
                                                              titleFont: { Appearance.Cell.Text.headTitleFont }),
                                           accessibilityDidFocusCell: { [weak self] _ in
                                            self?.clearCurrentlyFocusedCellObjects()
                                            },
                                           selectionAction: { [weak self] _ in
                                            self?.didTouchMultiPassMoreInfo()
                                        })
        let similarProfilesNames: [String] = WalletManager.shared.getSimilarProfileNames()
        let instructionUrl: URL? = URL(string: "multiPass.tab.similarProfile.url".localized)
        let warningRow: CVRow? = similarProfilesNames.isEmpty ? nil : .init(title: "multiPass.tab.similarProfile.title".localized,
                                                                            subtitle: String(format: "multiPass.tab.similarProfile.subtitle".localized, similarProfilesNames.joined(separator: ", ")),
                                                                     buttonTitle: instructionUrl == nil ? nil : "multiPass.tab.similarProfile.linkButton.title".localized,
                                                                     xibName: .paragraphCell,
                                                                     theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                                                        topInset: Appearance.Cell.Inset.normal,
                                                                                        bottomInset: .zero,
                                                                                        textAlignment: .natural,
                                                                                        titleFont: { Appearance.Cell.Text.headTitleFont }),
                                                                     accessibilityDidFocusCell: { [weak self] _ in
                                                                        self?.clearCurrentlyFocusedCellObjects()
                                                                        },
                                                                     selectionAction: { [weak self] _ in
                                                                        self?.didTouchMultiPassInstructions()
                                                                })
        return [explanationsRow, warningRow].compactMap { $0 }
    }
    
    private func infoRows() -> [CVRow] {
        let headerImageRow: CVRow = .init(image: Asset.Images.wallet.image,
                                          xibName: .imageCell,
                                          theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                                             imageRatio: 375.0 / 116.0))
        let explanationsRow: CVRow = .init(title: "walletController.howDoesItWork.title".localized,
                                           subtitle: "walletController.howDoesItWork.subtitle".localized,
                                           xibName: .standardCardCell,
                                           theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                              topInset: .zero,
                                                              bottomInset: .zero,
                                                              textAlignment: .natural,
                                                              titleFont: { Appearance.Cell.Text.headTitleFont }),
                                           accessibilityDidFocusCell: { [weak self] _ in
                                            self?.clearCurrentlyFocusedCellObjects()
                                           })
        let documentsRow: CVRow = .init(title: "walletController.documents.title".localized,
                                        subtitle: "walletController.documents.subtitle".localized,
                                        accessoryText: "walletController.documents.vaccin".localized,
                                        footerText: "walletController.documents.test".localized,
                                        image: WalletImagesManager.shared.image(named: .vaccinEuropeCertificate),
                                        secondaryImage: WalletImagesManager.shared.image(named: .testEuropeCertificate),
                                        xibName: .walletDocumentsCell,
                                        theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                           topInset: Appearance.Cell.Inset.normal,
                                                           bottomInset: .zero,
                                                           textAlignment: .natural,
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
        let whenToUseRow: CVRow = .init(title: "walletController.whenToUse.title".localized,
                                        subtitle: "walletController.whenToUse.subtitle".localized,
                                        buttonTitle: "walletController.whenToUse.button".localized,
                                        xibName: .paragraphCell,
                                        theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                           topInset: Appearance.Cell.Inset.normal,
                                                           bottomInset: .zero,
                                                           textAlignment: .natural,
                                                           titleFont: { Appearance.Cell.Text.headTitleFont }),
                                        accessibilityDidFocusCell: { [weak self] _ in
                                            self?.clearCurrentlyFocusedCellObjects()
                                        },
                                        selectionAction: { [weak self] _ in
                                            self?.didTouchWhenToUse()
        })
        let fraudRow: CVRow = .init(title: "walletController.info.fraud.title".localized,
                                        subtitle: "walletController.info.fraud.explanation".localized,
                                        buttonTitle: "walletController.info.fraud.button".localized,
                                        xibName: .paragraphCell,
                                        theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                           topInset: Appearance.Cell.Inset.small,
                                                           bottomInset: .zero,
                                                           textAlignment: .natural,
                                                           titleFont: { Appearance.Cell.Text.headTitleFont }),
                                        accessibilityDidFocusCell: { [weak self] _ in
            self?.clearCurrentlyFocusedCellObjects()
        },
                                        selectionAction: { [weak self] _ in
            self?.didTouchContinueOnFraud()
        })
        let phoneRow: CVRow = .init(title: "walletController.phone.title".localized,
                                    subtitle: "walletController.phone.subtitle".localized,
                                    image: Asset.Images.walletPhone.image,
                                    xibName: .phoneCell,
                                    theme: CVRow.Theme(backgroundColor: Asset.Colors.secondaryButtonBackground.color,
                                                       topInset: Appearance.Cell.Inset.normal,
                                                       bottomInset: .zero,
                                                       textAlignment: .natural,
                                                       titleFont: { Appearance.Cell.Text.smallHeadTitleFont },
                                                       subtitleFont: { Appearance.Cell.Text.accessoryFont }),
                                    accessibilityDidFocusCell: { [weak self] _ in
                                        self?.clearCurrentlyFocusedCellObjects()
                                    },
                                    selectionAction: { [weak self] _ in
                                        guard let self = self else { return }
                                        "walletController.phone.number".localized.callPhoneNumber(from: self)
                                    })
        return [headerImageRow,
                explanationsRow,
                documentsRow,
                whenToUseRow,
                fraudRow,
                phoneRow]
    }
    
    private func headerRows() -> [CVRow] {
        var rows: [CVRow] = []
        if UIAccessibility.isVoiceOverRunning {
            let addCertificateRow: CVRow = CVRow(title: "walletController.addCertificate".localized,
                                                 xibName: .buttonCell,
                                                 theme: CVRow.Theme(topInset: Appearance.Cell.Inset.large,
                                                                    bottomInset: .zero,
                                                                    buttonStyle: .primary),
                                                 selectionAction: { [weak self] _ in
                self?.openQRScan()
            })
            rows.append(addCertificateRow)
        }
        let certificatesModeSelectionAction: () -> () = { [weak self] in
            self?.mode = .certificates
            self?.reloadUI(animated: true, completion: nil)
        }
        let multiPassModeSelectionAction: (() -> ())? = WalletManager.shared.isMultiPassActivated ? { [weak self] in
            AnalyticsManager.shared.reportAppEvent(.e23)
            self?.mode = .multiPass
            self?.reloadUI(animated: true, completion: nil)
        } : nil
        let infoModeSelectionAction: () -> () = { [weak self] in
            self?.mode = .info
            self?.reloadUI(animated: true, completion: nil)
        }
        let modeSelectionRow: CVRow = CVRow(segmentsTitles: ["walletController.mode.myCertificates".localized,
                                                             WalletManager.shared.isMultiPassActivated ? "multiPass.tab.title".localized : nil,
                                                             "walletController.mode.info".localized].compactMap { $0 },
                                            selectedSegmentIndex: mode.selectedIndex,
                                            xibName: .segmentedCell,
                                            theme:  CVRow.Theme(backgroundColor: .clear,
                                                                topInset: Appearance.Cell.Inset.large,
                                                                bottomInset: Appearance.Cell.Inset.small / 2,
                                                                textAlignment: .natural,
                                                                titleFont: { Appearance.SegmentedControl.selectedFont },
                                                                subtitleFont: { Appearance.SegmentedControl.normalFont }),
                                            accessibilityDidFocusCell: { [weak self] _ in
                                                self?.clearCurrentlyFocusedCellObjects()
                                            },
                                            segmentsActions: [certificatesModeSelectionAction, multiPassModeSelectionAction, infoModeSelectionAction].compactMap { $0 })
        rows.append(modeSelectionRow)
        return rows
    }
    
    private func certificatesRows() -> [CVRow] {
        var rows: [CVRow] = []
        if WalletManager.shared.areThereCertificatesNeedingAttention {
            rows.append(CVRow(title: nil,
                              subtitle: "walletController.certificateWarning".localized,
                              xibName: .textCell,
                              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                                 bottomInset: .zero,
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
                                                         theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                                                            bottomInset: .zero,
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
                                                                 theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                                                                    bottomInset: .zero,
                                                                                    textAlignment: .natural),
                                                                 accessibilityDidFocusCell: { [weak self] _ in
                                                                    self?.clearCurrentlyFocusedCellObjects()
                                                                 })
                rows.append(favoriteCertificateSectionRow)
            }
        }
        
        let recentCertificates: [WalletCertificate] = WalletManager.shared.recentWalletCertificates.filter { $0.uniqueHash != favoriteCertificate?.uniqueHash }
        if !recentCertificates.isEmpty {
            let recentCertificatesSectionRow: CVRow = CVRow(title: "walletController.recentCertificatesSection.title".localized,
                                                            subtitle: "walletController.recentCertificatesSection.subtitle".localized,
                                                            xibName: .textCell,
                                                            theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                                                               bottomInset: .zero,
                                                                               textAlignment: .natural,
                                                                               titleFont: { Appearance.Cell.Text.headTitleFont }),
                                                            accessibilityDidFocusCell: { [weak self] _ in
                                                                self?.clearCurrentlyFocusedCellObjects()
                                                            })
            rows.append(recentCertificatesSectionRow)
            rows.append(contentsOf: recentCertificates.sorted { $0.timestamp > $1.timestamp }.map { certificateRows(certificate: $0) }.reduce([], +))
        }
        
        let oldCertificates: [WalletCertificate] = WalletManager.shared.oldWalletCertificates.filter { $0.uniqueHash != favoriteCertificate?.uniqueHash }
        if !oldCertificates.isEmpty {
            let oldCertificatesSectionRow: CVRow = CVRow(title: "walletController.oldCertificatesSection.title".localized,
                                                         subtitle: "walletController.oldCertificatesSection.subtitle".localized,
                                                         xibName: .textCell,
                                                         theme: CVRow.Theme(topInset: recentCertificates.isEmpty ? Appearance.Cell.Inset.medium : Appearance.Cell.Inset.extraLarge,
                                                                            bottomInset: .zero,
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
    
    private func row(for additionalInfoDesc: String, additionalInfoCategory: AdditionalInfo.Category) -> CVRow {
        let backgroundColor: UIColor = additionalInfoCategory.backgroundColor
        let image: UIImage
        let titleColor: UIColor
        switch additionalInfoCategory {
        case .error:
            image = Asset.Images.passWarning.image
            titleColor = .white.withAlphaComponent(0.85)
        case .warning:
            image = Asset.Images.passWarning.image
            titleColor = .black.withAlphaComponent(0.55)
        case .info:
            image = Asset.Images.passInfo.image
            titleColor = .white.withAlphaComponent(0.85)
        }
        
        return CVRow(title: additionalInfoDesc,
                     subtitle: "Lire la suite",
                     image: shouldHideCellImage ? nil : image,
                     xibName: .additionalInfoCell,
                     theme: CVRow.Theme(backgroundColor: backgroundColor,
                                        topInset: Appearance.Cell.Inset.medium,
                                        bottomInset: .zero,
                                        textAlignment: .natural,
                                        titleFont: { Appearance.Cell.Text.subtitleFont },
                                        titleColor: titleColor,
                                        titleLinesCount: 2,
                                        subtitleFont: { Appearance.Cell.Text.accessoryFont },
                                        subtitleColor: titleColor,
                                        imageSize: Appearance.Cell.Image.size,
                                        interLabelSpacing: Appearance.Cell.Inset.normal,
                                        maskedCorners: .top),
                     selectionAction: { [weak self] cell in
            if cell?.cvSubtitleLabel?.isHidden == false {
                let additionalInfo: AdditionalInfo = .init(category: additionalInfoCategory, fullDescription: additionalInfoDesc)
                self?.didTouchCertificateAdditionalInfo(additionalInfo)
            }
        }, willDisplay: { cell in
            (cell as? AdditionalInfoCell)?.cvImageView?.alpha = additionalInfoCategory == .warning ? 0.55 : 0.85
        }, didValidateValue: { [weak self] _, cell in
            self?.tableView.beginUpdates()
            cell.layoutSubviews()
            self?.tableView.endUpdates()
        })
    }
    
    private func additionalInfoRowIfNeeded(for certificate: WalletCertificate) -> CVRow? {
        var additionalInfo: [AdditionalInfo] = certificate.additionalInfo
        
        if WalletManager.shared.shouldUseSmartWallet,
           let europeanCertificate = certificate as? EuropeanCertificate,
           WalletManager.shared.isRelevantCertificate(europeanCertificate) {
            if let desc = WalletManager.shared.expirationDescription(for: europeanCertificate) {
                additionalInfo.append(AdditionalInfo(category: .error, fullDescription: desc))
            } else if let desc = WalletManager.shared.expirationSoonDescription(for: europeanCertificate) {
                additionalInfo.append(AdditionalInfo(category: .warning, fullDescription: desc))
            } else if let desc = WalletManager.shared.eligibilityDescription(for: europeanCertificate) {
                additionalInfo.append(AdditionalInfo(category: .info, fullDescription: desc))
            } else if let desc = WalletManager.shared.eligibleSoonDescription(for: europeanCertificate) {
                additionalInfo.append(AdditionalInfo(category: .info, fullDescription: desc))
            }
        }
        
        if !additionalInfo.errors.isEmpty {
            let aggregateDescription: String = additionalInfo.errors.map { $0.fullDescription }.joined(separator: "\n\n")
            return row(for: aggregateDescription, additionalInfoCategory: .error)
        } else if !additionalInfo.warnings.isEmpty {
            let aggregateDescription: String = additionalInfo.warnings.map { $0.fullDescription }.joined(separator: "\n\n")
            return row(for: aggregateDescription, additionalInfoCategory: .warning)
        } else if !additionalInfo.info.isEmpty {
            let aggregateDescription: String = additionalInfo.info.map { $0.fullDescription }.joined(separator: "\n\n")
            return row(for: aggregateDescription, additionalInfoCategory: .info)
        }
        return nil
    }
    
    private func certificateRows(certificate: WalletCertificate) -> [CVRow] {
        var rows: [CVRow] = []
        var subtitle: String = certificate.fullDescription ?? ""
        if WalletManager.shared.shouldUseSmartWallet,
           let cert = certificate as? EuropeanCertificate,
           let expiryTimestamp = WalletManager.shared.expiryTimestamp(cert) {
            let expiryDate: Date = Date(timeIntervalSince1970: expiryTimestamp)
            let remainingValidityDuration: Double = expiryTimestamp - Date().timeIntervalSince1970
            if remainingValidityDuration.secondsToDays() <= ParametersManager.shared.smartWalletConfiguration.exp.displayExpOnAllDcc {
                subtitle.append("\n")
                subtitle.append(remainingValidityDuration > 0 ? String(format: "walletController.certificateExpiration".localized, expiryDate.dayShortMonthYearFormatted(timeZoneIndependant: true)) : String(format: "walletController.certificateExpired".localized, expiryDate.dayShortMonthYearFormatted(timeZoneIndependant: true)))
            }
        }
        if let row = additionalInfoRowIfNeeded(for: certificate) {
            rows.append(row)
        }
        let canBeAddedToFavorite: Bool = certificate.type.format == .walletDCC || certificate.type == .multiPass
        let certificateRow: CVRow = CVRow(title: certificate.shortDescriptionForList?.uppercased(),
                                          subtitle: subtitle,
                                          image: shouldHideCellImage ? nil : certificate.codeImage,
                                          isOn: certificate.id == WalletManager.shared.favoriteDccId,
                                          xibName: .sanitaryCertificateCell,
                                          theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                             topInset: rows.isEmpty ? Appearance.Cell.Inset.medium : .zero,
                                                             bottomInset: .zero,
                                                             textAlignment: shouldHideCellImage ? .center : .natural,
                                                             titleFont: { Appearance.Cell.Text.smallHeadTitleFont },
                                                             titleColor: Appearance.Cell.Text.titleColor,
                                                             subtitleFont: { Appearance.Cell.Text.subtitleFont },
                                                             accessoryTextFont: { Appearance.Cell.Text.subtitleFont },
                                                             imageSize: Appearance.Cell.Image.largeSize,
                                                             maskedCorners: UIAccessibility.isVoiceOverRunning ? (rows.isEmpty ? .all : .bottom) : (rows.isEmpty ? .top : .none)),
                                          associatedValue: certificate,
                                          accessibilityDidFocusCell: { [weak self] cell in
                                            self?.currentlyFocusedCertificate = certificate
                                            self?.currentlyFocusedCell = cell
                                          },
                                          selectionActionWithCell: { [weak self] cell in
                                            self?.didTouchCertificateMenuButton(certificate: certificate, cell: cell)
                                          },
                                          selectionAction: { [weak self] _ in
                                            self?.didTouchCertificate(certificate)
                                          },
                                          secondarySelectionAction: canBeAddedToFavorite ? { [weak self] in
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
                                                             topInset: .zero,
                                                             bottomInset: .zero,
                                                             textAlignment: .center,
                                                             titleFont: { Appearance.Cell.Text.actionTitleFont },
                                                             titleColor: Appearance.Button.Secondary.titleColor,
                                                             separatorLeftInset: nil,
                                                             separatorRightInset: nil,
                                                             maskedCorners: .bottom),
                                         accessibilityDidFocusCell: { [weak self] _ in
                                            self?.clearCurrentlyFocusedCellObjects()
                                         },
                                         selectionAction: { [weak self] _ in
                                            self?.didTouchCertificate(certificate)
                                         })
            rows.append(actionRow)
        }
        return rows
    }
    
    private func didTouchCertificateMenuButton(certificate: WalletCertificate, cell: CVTableViewCell) {
        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "walletController.menu.share".localized, style: .default, handler: { [weak self] _ in
            self?.showSharingConfirmationController {
                self?.showSanitaryCertificateSharing(image: cell.capture(), text: certificate.fullDescription ?? "")
            }
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
    
    private func showSharingConfirmationController(confirmationHandler: @escaping () -> ()) {
        let bottomSheet: BottomSheetAlertController = .init(
            title: "certificateSharingController.title".localized,
            message: "certificateSharingController.message".localized,
            okTitle: "common.confirm".localized,
            cancelTitle: "common.cancel".localized) {
                confirmationHandler()
            }
        bottomSheet.show()
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

    func scrollTo(_ certificate: WalletCertificate, animated: Bool = true) {
        if mode != .certificates {
            mode = .certificates
            reloadUI()
        }
        guard let indexPath = getIndexPath(for: certificate) else { return }
        tableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
    }

    private func getIndexPath(for certificate: WalletCertificate) -> IndexPath? {
        var indexPath: IndexPath? = nil
        for (index, section) in sections.enumerated() {
            let rowIndex: Int? = section.rows.firstIndex { ($0.associatedValue as? WalletCertificate)?.uniqueHash == certificate.uniqueHash }
            guard let row = rowIndex else { continue }
            indexPath = IndexPath(row: row, section: index)
            break
        }
        return indexPath
    }
    
    private func openQRScan() {
        CameraAuthorizationManager.requestAuthorization { granted, isFirstTimeRequest in
            if granted {
                self.didTouchFlashCertificate()
            } else if !isFirstTimeRequest {
                self.showAlert(title: "scanCodeController.camera.authorizationNeeded.title".localized,
                               message: "scanCodeController.camera.authorizationNeeded.message".localized,
                               okTitle: "common.settings".localized,
                               cancelTitle: "common.cancel".localized, handler:  {
                                UIApplication.shared.openSettings()
                               })
            }
        }
    }
    
    private func openProfilesAlert() {
        let profiles: [String: [EuropeanCertificate]] = WalletManager.shared.getMultiPassProfiles()
        if profiles.count > 1 {
            let actions: [UIAlertAction] = profiles.compactMap { profile in
                guard let fullName = profile.value.first?.fullName.capitalized else { return nil }
                return UIAlertAction(title: fullName, style: .default) { [weak self] _ in
                    self?.didSelectProfileForMultiPass(profile.value)
                }
            }.sorted { ($0.title ?? "") < ($1.title ?? "")}
            showActionSheet(title: nil, message: "multiPass.tab.generation.profileList.title".localized, actions: actions, showCancel: true)
        } else if let certificates = profiles.first?.value, profiles.count == 1 {
            didSelectProfileForMultiPass(certificates)
        } else {
            showAlert(title: "multiPass.noProfile.alert.title".localized, message: "multiPass.noProfile.alert.subtitle".localized, okTitle: "common.ok".localized, isOkDestructive: false)
        }
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

    func walletActivityCertificateDidUpdate() {
    }
    
    func walletFavoriteCertificateDidUpdate() {
        reloadUI(animated: false) { [weak self] in
            guard self?.mustScrollToTopAfterRefresh == true else { return }
            self?.mustScrollToTopAfterRefresh = false
            self?.tableView.scrollToTop()
        }
    }
    
    func walletSmartStateDidUpdate() {}
}
