// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MultiPassCertificateSelectionViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/01/2022 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK

final class MultiPassCertificateSelectionViewController: CVTableViewController {
    
    // MARK: - Enum
    private enum Mode {
        case empty
        case certificates
        
        var controllerTitle: String {
            switch self {
            case .empty: return "multiPass.selectionScreen.error.title".localized
            case .certificates: return "multiPass.selectionScreen.title".localized
            }
        }
    }
    
    // MARK: - Constants
    private let certificates: [EuropeanCertificate]
    private let didChose: (_ certificates: [EuropeanCertificate]) -> ()
    private let didTouchClose: () -> ()
    private let deinitBlock: () -> ()
    
    // MARK: - Variables
    private var mode: Mode { filteredCertificates.count >= ParametersManager.shared.multiPassConfiguration.minDcc ? .certificates : .empty }
    private var controller: UIViewController { bottomButtonContainerController ?? self }
    private var selectedCertificates: [EuropeanCertificate] = [] {
        didSet {
            updateBottomBarState()
        }
    }
    private var profileName: String { certificates.first?.fullName.capitalized ?? "" }
    private lazy var filteredCertificates: [EuropeanCertificate] = {
        WalletManager.shared.relevantCertificateForMultiPass(in: certificates).sorted { $0.timestamp > $1.timestamp }
    }()
    
    init(availableCertificates: [EuropeanCertificate],
         didChose: @escaping (_ certificates: [EuropeanCertificate]) -> (),
         didTouchClose: @escaping () -> (),
         deinitBlock: @escaping () -> ()) {
        self.certificates = availableCertificates
        self.didChose = didChose
        self.didTouchClose = didTouchClose
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }
    
    deinit {
        deinitBlock()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        reloadUI()
        updateBottomBarButton()
    }
    
    override func createSections() -> [CVSection] {
        let rows: [CVRow]
        let header: CVFooterHeaderSection? = mode == .empty ? nil : CVFooterHeaderSection.header(title: String(format: "multiPass.selectionScreen.header.title".localized, profileName))
        switch mode {
        case .empty:
            rows = [errorRow(), phoneRow()]
        case .certificates:
            rows = filteredCertificates.compactMap { certificateSelectionRow($0) }
        }
        return [CVSection(header: header, rows: rows)]
    }
}

// MARK: - Private functions
private extension MultiPassCertificateSelectionViewController {
    func initUI() {
        controller.title = mode.controllerTitle
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.cancel".localized, style: .plain, target: self, action: #selector(didTouchLeftBarButtonItem))
        controller.navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }
    
    @objc func didTouchLeftBarButtonItem() {
        didTouchClose()
    }
    
    func updateBottomBarButton() {
        bottomButtonContainerController?.updateButton(title: "multiPass.selectionScreen.button.validate".localized) { [weak self] in
            guard let self = self else { return }
            self.didChose(self.selectedCertificates)
            self.bottomButtonContainerController?.unlockButtons()
        }
        updateBottomBarState()
    }
    
    func updateBottomBarState() {
        bottomButtonContainerController?.setBottomBarHidden(selectedCertificates.count < ParametersManager.shared.multiPassConfiguration.minDcc, animated: true)
    }
    
    func select(certificate: EuropeanCertificate) {
        if isCertificateSelected(certificate) {
            selectedCertificates = selectedCertificates.filter { $0.uniqueHash != certificate.uniqueHash }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            if selectedCertificates.count < ParametersManager.shared.multiPassConfiguration.maxDcc {
                selectedCertificates.append(certificate)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                showAlert(title: "multiPass.selectionScreen.alert.mximumSelection.title".localized, message: "multiPass.selectionScreen.alert.mximumSelection.subtitle".localized, okTitle: "common.ok".localized)
            }
        }
    }
    
    func isCertificateSelected(_ certificate: EuropeanCertificate) -> Bool {
        selectedCertificates.contains(certificate)
    }
}

// MARK: - Rows
private extension MultiPassCertificateSelectionViewController {
    func certificateSelectionRow(_ certificate: EuropeanCertificate) -> CVRow {
        buttonRow(title: certificate.titleForSelection,
                  subtitle: certificate.detailsForSelection,
                  isSelected: isCertificateSelected(certificate),
                  separatorLeftInset: .zero) { [weak self] in
            self?.select(certificate: certificate)
            self?.reloadUI()
        }
    }
    
    func errorRow() -> CVRow {
        CVRow(title: "multiPass.selectionScreen.error.explanation.title".localized,
              subtitle: String(format: "multiPass.selectionScreen.error.explanation.subtitle".localized, profileName),
              xibName: .standardCardCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.normal,
                                 bottomInset: .zero,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.headTitleFont }))
    }
    
    func phoneRow() -> CVRow {
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
    }
    
    func buttonRow(title: String, subtitle: String, isSelected: Bool, separatorLeftInset: CGFloat? = nil, handler: @escaping () -> ()) -> CVRow {
        CVRow(title: title,
              subtitle: subtitle,
              isOn: isSelected,
              xibName: .certificateSelectionCell,
              theme:  CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                  topInset: Appearance.Cell.Inset.normal,
                                  bottomInset: Appearance.Cell.Inset.normal,
                                  textAlignment: .natural,
                                  titleFont: { Appearance.Cell.Text.titleHighlightFont },
                                  titleColor: Appearance.Cell.Text.headerTitleColor,
                                  subtitleColor: Appearance.Cell.Text.subtitleColor ,
                                  subtitleLinesCount: 3,
                                  imageTintColor: Appearance.Cell.Text.headerTitleColor,
                                  imageSize: Appearance.Cell.Image.size,
                                  separatorLeftInset: Appearance.Cell.leftMargin),
              selectionAction: { _ in
            handler()
        })
    }
}

// MARK: - utils on EuropeanCertificate
private extension EuropeanCertificate {
    var titleForSelection: String { (pillTitles.first?.text ?? "").uppercased() }
    var detailsForSelection: String {
        var dateFormatted: String = Date(timeIntervalSince1970: timestamp).dayMonthYearFormatted()
        switch type {
        case .vaccinationEurope:
            return "multiPass.selectionScreen.vaccine.description".localized
                .replacingOccurrences(of: "<VACCINE_NAME>", with: l10n("vac.product.\(medicalProductCode ?? "")"))
                .replacingOccurrences(of: "<VACCINE_DOSES>", with: "\(dosesNumber ?? 0)/\(dosesTotal ?? 0)")
                .replacingOccurrences(of: "<DATE>", with: dateFormatted)
        case .recoveryEurope:
            return dateFormatted
        case .sanitaryEurope:
            let testResultKey: String = isTestNegative == true ? "negative" : "positive"
            dateFormatted = Date(timeIntervalSince1970: timestamp).dayShortMonthYearTimeFormatted()
            return "multiPass.selectionScreen.test.description".localized
                .replacingOccurrences(of: "<ANALYSIS_RESULT>", with: "wallet.proof.europe.test.\(testResultKey)".localized)
                .replacingOccurrences(of: "<FROM_DATE>", with: dateFormatted)
        default:
            return fullDescription ?? ""
        }
    }
}
