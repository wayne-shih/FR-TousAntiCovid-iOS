// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  FullscreenCertificateViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import ServerSDK

final class FullscreenCertificateViewController: CVTableViewController {

    private enum Mode {
        case standard
        case activityPass
        case border
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    var deinitBlock: (() -> ())?
    var lastBrightness: CGFloat?
    
    @UserDefault(key: .autoBrightnessActivated)
    var autoBrightnessActivated: Bool = true {
        didSet {
            autoBrightnessActivated ? updateBrightnessForQRCodeReadabilityIfNeeded() : putBrightnessBackToOriginalValue()
        }
    }

    private var certificate: WalletCertificate
    private var isEligibleToActivityCertificateGeneration: Bool {
        guard let dccCertificate = certificate as? EuropeanCertificate else { return false }
        return dccCertificate.isEligibleToActivityCertificateGeneration && !DccBlacklistManager.shared.isBlacklisted(certificate: dccCertificate)
    }
    private let didTouchGenerateActivityPass: (_ didConfirmGeneration: @escaping () -> ()) -> ()
    private let didTouchShareCertificate: (_ didConfirmSharing: @escaping () -> ()) -> ()
    private let didTouchShowOptions: (_ brightnessParamDidChange: @escaping (_ activated: Bool) -> (), _ shareConfirmationHandler: @escaping () -> ()) -> ()
    private let dismissBlock: () -> ()
    private var isFirstLoad: Bool = true
    private var wasShowingCertificate: Bool = false
    private var mode: Mode = .standard {
        didSet {
            updateBrightnessForQRCodeReadabilityIfNeeded()
        }
    }

    private var currentActivityCertificate: ActivityCertificate?
    private var isHavingActivityCertificate: Bool { currentActivityCertificate != nil }
    private var wasCertificateValid: Bool = false
    private var timer: Timer?
    private weak var activityCertificateExpirationCell: ActivityPassExpirationCell?

    init(certificate: WalletCertificate,
         didTouchGenerateActivityPass: @escaping (_ didConfirmGeneration: @escaping () -> ()) -> (),
         didTouchShareCertificate: @escaping (_ didConfirmSharing: @escaping () -> ()) -> (),
         didTouchShowOptions: @escaping (_ brightnessParamDidChange: @escaping (_ activated: Bool) -> (), _ shareConfirmationHandler: @escaping () -> ()) -> (),
         dismissBlock: @escaping () -> (),
         deinitBlock: @escaping () -> ()) {
        self.certificate = certificate
        self.didTouchShareCertificate = didTouchShareCertificate
        self.didTouchGenerateActivityPass = didTouchGenerateActivityPass
        self.didTouchShowOptions = didTouchShowOptions
        self.dismissBlock = dismissBlock
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        initMode()
        updateActivityCertificate()
        reloadUI()
        updateBottomBarButton()
        addObservers()
        wasCertificateValid = currentActivityCertificate?.isValid == true
        if isHavingActivityCertificate { startTimer() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstLoad { updateBrightnessForQRCodeReadabilityIfNeeded() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstLoad {
            isFirstLoad = false
            showWidgetUpdateConfirmationIfNeeded()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        putBrightnessBackToOriginalValue()
        stopTimer()
    }

    deinit {
        removeObservers()
        deinitBlock?()
    }

    func updateCertificate(_ certificate: WalletCertificate) {
        self.certificate = certificate
        initMode()
        updateActivityCertificate()
        reloadUI()
        showWidgetUpdateConfirmationIfNeeded()
    }

    private func initUI() {
        tableView.backgroundColor = .white
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        let barButtonItem: UIBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        barButtonItem.accessibilityHint = "accessibility.closeModal.zGesture".localized
        (bottomButtonContainerController ?? self).navigationItem.leftBarButtonItem = barButtonItem
        updateRightBarButtonItems()
        bottomButtonContainerController?.button.buttonStyle = .primary
        if #available(iOS 13.0, *) { navigationController?.overrideUserInterfaceStyle = .light }
    }

    private func updateRightBarButtonItems() {
        let isShowingCertificate: Bool = mode == .standard || (mode == .activityPass && currentActivityCertificate?.isValid == true) || mode == .border
        let shareItem: UIBarButtonItem = .init(image: Asset.Images.shareItem.image, style: .done, target: self, action: #selector(didTouchShareCertificateButton))
        let optionsItem: UIBarButtonItem = .init(image: Asset.Images.moreColored.image, style: .plain, target: self, action: #selector(showOptions))
        let items: [UIBarButtonItem]? = isShowingCertificate ? [optionsItem, shareItem] : nil
        (bottomButtonContainerController ?? self).navigationItem.setRightBarButtonItems(items, animated: wasShowingCertificate != isShowingCertificate)
        wasShowingCertificate = isShowingCertificate
    }

    private func initMode() {
        mode = [.sanitary, .vaccination].contains(certificate.type) || !WalletManager.shared.isActivityPassActivated ? .standard : .activityPass
    }

    private func updateActivityCertificate() {
        let certificate: ActivityCertificate? = WalletManager.shared.activityCertificateFor(certificate: certificate as? EuropeanCertificate)
        currentActivityCertificate = certificate?.endDate ?? .distantPast > Date() ? certificate : nil
    }

    private func updateBackgroundColor() {
        let isShowingCertificate: Bool = mode != .activityPass || (mode == .activityPass && currentActivityCertificate?.isValid == true)
        tableView.backgroundColor = isShowingCertificate ? .white : Appearance.Controller.cardTableViewBackgroundColor
    }

    private func addObservers() {
        WalletManager.shared.addObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }

    private func removeObservers() {
        WalletManager.shared.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func didTouchCloseButton() {
        dismissBlock()
    }

    private func updateBottomBarButton() {
        let buttonTitle: String = "activityPass.fullscreen.button.generate".localized
        bottomButtonContainerController?.updateButton(title: buttonTitle) { [weak self] in
            self?.didTouchGenerateActivityCertificate()
        }
    }

    override func reloadUI(animated: Bool = false, animatedView: UIView? = nil, completion: (() -> ())? = nil) {
        super.reloadUI(animated: animated, animatedView: navigationController?.view, completion: completion)
        updateBackgroundColor()
        updateBottomBarButton()
        updateBottomButtonVisibility()
        updateRightBarButtonItems()
    }

    override func createSections() -> [CVSection] {
        makeSections {
            switch mode {
            case .standard:
                standardSection()
            case .activityPass:
                activityPassSection()
            case .border:
                borderSection()
            }
        }
    }

    private func standardSection() -> CVSection {
        CVSection {
            if !certificate.is2dDoc {
                modeSelectionRow()
                logosRow()
            }
            codeImageRow(certificate)
            if certificate.is2dDoc { codeLegendRow() }
            codeShortDescriptionRow(certificate)
            certificate.is2dDoc ? codeHashRow() : explanationsRow()
        }
    }
    
    private func activityPassSection() -> CVSection {
        if let activityCertificate = currentActivityCertificate {
            if activityCertificate.isValid {
                return CVSection {
                    modeSelectionRow()
                    logosRow()
                    codeImageRow(activityCertificate)
                    codeShortDescriptionRow(activityCertificate)
                    activityPassExpirationRow(activityCertificate)
                    explanationsRow()
                }
            } else {
                return CVSection {
                    modeSelectionRow()
                    activityPassAvailableSoonRow(availabilityDate: activityCertificate.startDate)
                    notifyMeButtonRow(availabilityDate: activityCertificate.startDate)
                    notifyMeFooterRow(for: activityCertificate.startDate)
                }
            }
        } else {
            return CVSection {
                modeSelectionRow()
                if isEligibleToActivityCertificateGeneration {
                    if (certificate as? EuropeanCertificate)?.didAlreadyGenerateActivityCertificates == true {
                        activityPassServerNotAvailableRow()
                    } else {
                        activityPassInfoRow()
                    }
                } else {
                    activityPassNotEligibleRow()
                }
            }
        }
    }

    private func borderSection() -> CVSection {
        CVSection {
            modeSelectionRow()
            if (certificate as? EuropeanCertificate)?.type == .exemptionEurope { exemptionWarningRow() }
            if (certificate as? EuropeanCertificate)?.isForeignCertificate == false { logosRow() }
            codeImageRow(certificate)
            codeFullDescriptionRow()
            codeHashRow()
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        dismissBlock()
        return true
    }

    private func didTouchGenerateActivityCertificate() {
        if WalletManager.shared.isGeneratingActivityPasses {
            showAlert(title: "activityPass.fullscreen.alreadyGenerating.alert.title".localized,
                      message: "activityPass.fullscreen.alreadyGenerating.alert.message".localized,
                      okTitle: "common.ok".localized)
        } else {
            didTouchGenerateActivityPass { [weak self] in
                self?.generateActivtyCertificate()
            }
        }
        bottomButtonContainerController?.unlockButtons()
    }

    @objc private func didTouchShareCertificateButton() {
        didTouchShareCertificate { [weak self] in
            self?.shareCertificate()
        }
        bottomButtonContainerController?.unlockButtons()
    }
    
    @objc private func showOptions() {
        didTouchShowOptions({ [weak self] activated in
            self?.autoBrightnessActivated = activated
        }, { [weak self] in
            self?.shareCertificate()
        })
    }

    private func generateActivtyCertificate() {
        HUD.show(.progress)
        WalletManager.shared.generateActivityDccFrom(certificate: certificate) { [weak self] error in
            guard error == nil else {
                self?.showActivityCertiticateGenerationErrorAlert()
                HUD.hide()
                return
            }
            self?.updateActivityCertificate()
            self?.wasCertificateValid = self?.currentActivityCertificate?.isValid == true
            self?.reloadUI(animated: true)
            if self?.isHavingActivityCertificate == true {
                self?.startTimer()
                self?.showAutoRenewActivityPassAlertIfNecessary()
            }
            HUD.hide()
        }
    }

    private func shareCertificate() {
        guard let screenshot = navigationController?.view.cvScreenshot() else { return }
        ScreenshotAnimator.shared.generateScreenshotAnimation(for: screenshot) { [weak self] in
            guard let self = self else { return }
            screenshot.share(from: self)
        }
    }

    private func updateBottomButtonVisibility() {
        let showButtomButton: Bool = mode == .activityPass && currentActivityCertificate == nil && isEligibleToActivityCertificateGeneration
        bottomButtonContainerController?.setBottomBarHidden(!showButtomButton, animated: false)
    }

    private func showActivityCertiticateGenerationErrorAlert() {
        showAlert(title: "activityPass.fullscreen.unavailable.alert.title".localized,
                  message: "activityPass.fullscreen.unavailable.alert.message".localized,
                  okTitle: "common.show".localized,
                  cancelTitle: "common.cancel".localized,
                  handler: { [weak self] in
                    self?.selectBorderMode()
                    self?.tableView.scrollToTop()
                  })
    }

    private func showAutoRenewActivityPassAlertIfNecessary() {
        guard ParametersManager.shared.activityPassAutoRenewable && !WalletManager.shared.activityPassAutoRenewalActivated else { return }
        showAlert(title: "activityPass.fullscreen.renew.alert.title".localized,
                  message: "activityPass.fullscreen.renew.alert.message".localized,
                  okTitle: "common.activate".localized,
                  cancelTitle: "common.cancel".localized,
                  handler: {
                    WalletManager.shared.activityPassAutoRenewalActivated = true
                  })
    }
    
    private func selectBorderMode() {
        mode = .border
        reloadUI(animated: true)
    }
    
    private func selectActivityMode() {
        mode = WalletManager.shared.isActivityPassActivated ? .activityPass : .standard
        reloadUI(animated: true)
    }

    private func showWidgetUpdateConfirmationIfNeeded() {
        guard certificate.id == WalletManager.shared.favoriteDccId && wasCertificateValid else { return }
        if #available(iOS 14.0, *) { WidgetDCCManager.shared.showActivityCertificateRefreshConfirmationIfNeeded() }
    }

}

extension FullscreenCertificateViewController {
    private func modeSelectionRow() -> CVRow {
        let activityModeSelectionAction: () -> () = { [weak self] in
            self?.selectActivityMode()
        }
        let borderModeSelectionAction: () -> () = { [weak self] in
            self?.selectBorderMode()
        }
        let activitySegmentTitle: String
        let borderSegmentTitle: String
        let minimumSegmentTitle: String
        if #available(iOS 13.0, *) {
            minimumSegmentTitle = "europeanCertificate.fullscreen.type13.minimum".localized
            borderSegmentTitle = "europeanCertificate.fullscreen.type13.border".localized
            activitySegmentTitle = "europeanCertificate.fullscreen.type13.activityPass".localized
        } else {
            minimumSegmentTitle = "europeanCertificate.fullscreen.type.minimum".localized
            borderSegmentTitle = "europeanCertificate.fullscreen.type.border".localized
            activitySegmentTitle = "europeanCertificate.fullscreen.type.activityPass".localized
        }
        let modeSelectionRow: CVRow = CVRow(segmentsTitles: [ WalletManager.shared.isActivityPassActivated ? activitySegmentTitle : minimumSegmentTitle,
                                                              borderSegmentTitle],
                                            selectedSegmentIndex: mode == .border ? 1 : 0,
                                            xibName: .segmentedCell,
                                            theme:  CVRow.Theme(backgroundColor: .clear,
                                                                topInset: Appearance.Cell.Inset.medium,
                                                                bottomInset: Appearance.Cell.Inset.small / 2,
                                                                textAlignment: .natural,
                                                                titleFont: { Appearance.SegmentedControl.selectedFont },
                                                                subtitleFont: { Appearance.SegmentedControl.normalFont }),
                                            segmentsActions: [activityModeSelectionAction, borderModeSelectionAction])
        return modeSelectionRow
    }

    private func logosRow() -> CVRow {
        let margin: CGFloat = .zero
        return CVRow(image: Asset.Images.logosPasseport.image,
                     xibName: .imageCell,
                     theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                        bottomInset: .zero,
                                        leftInset: margin,
                                        rightInset: margin,
                                        imageRatio: 375.0 / 79.0))
    }

    private func codeImageRow(_ certificate: WalletCertificate) -> CVRow {
        let margin: CGFloat = 80.0
        return CVRow(image: Asset.Images.screenshotLogo.image,
                     xibName: .protectedQrCodeCell,
                     theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                        bottomInset: .zero,
                                        leftInset: margin,
                                        rightInset: margin,
                                        imageRatio: 1.0),
                     associatedValue: certificate.codeImage)
    }

    private func codeLegendRow() -> CVRow {
        CVRow(title: certificate.codeImageTitle,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: .zero,
                                 bottomInset: .zero,
                                 titleFont: { Appearance.Cell.Text.headTitleFont4 }))
    }

    private func codeShortDescriptionRow(_ certificate: WalletCertificate) -> CVRow {
        CVRow(title: certificate.shortDescription,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.small,
                                 bottomInset: mode == .activityPass ? Appearance.Cell.Inset.medium : .zero,
                                 titleFont: { .regular(size: Appearance.Cell.Inset.medium) }))
    }

    private func codeFullDescriptionRow() -> CVRow {
        CVRow(title: certificate.fullDescriptionForFullscreen,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.small,
                                 bottomInset: .zero,
                                 titleFont: { .regular(size: 20.0) }))
    }

    private func explanationsRow() -> CVRow {
        CVRow(title: "europeanCertificate.fullscreen.type.minimum.footer".localized,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.large,
                                 bottomInset: .zero,
                                 textAlignment: .natural,
                                 titleFont: { .regular(size: 17.0) }))
    }

    private func exemptionWarningRow() -> CVRow {
        CVRow(title: "europeanCertificate.fullscreen.exemption.border.warning".localized,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                 bottomInset: .zero,
                                 textAlignment: .natural,
                                 titleFont: { .regular(size: 17.0) }))
    }

    private func codeHashRow() -> CVRow {
        CVRow(title: certificate.uniqueHash,
              xibName: .protectedHashCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.large,
                                 bottomInset: .zero,
                                 titleFont: { .regular(size: 11.0) },
                                 titleColor: .darkGray,
                                 accessoryType: UITableViewCell.AccessoryType.none),
              selectionAction: { [weak self] _ in
                guard let hash = self?.certificate.uniqueHash else { return }
                UIPasteboard.general.string = hash
                HUD.flash(.labeledSuccess(title: "common.copied".localized, subtitle: nil))
              }, willDisplay: { cell in
                cell.selectionStyle = .none
              })
    }

    private func kidRow() -> CVRow {
        CVRow(title: (certificate as? EuropeanCertificate)?.kid,
              xibName: .protectedHashCell,
              theme: CVRow.Theme(topInset: 0.0,
                                 bottomInset: 0.0,
                                 titleFont: { .regular(size: 11.0) },
                                 titleColor: .darkGray,
                                 accessoryType: UITableViewCell.AccessoryType.none),
              selectionAction: { [weak self] _ in
            guard let kid = (self?.certificate as? EuropeanCertificate)?.kid else { return }
            UIPasteboard.general.string = kid
            HUD.flash(.labeledSuccess(title: "common.copied".localized, subtitle: nil))
        }, willDisplay: { cell in
            cell.selectionStyle = .none
        })
    }

    private func activityPassInfoRow() -> CVRow {
        let url: URL? = URL(string: "activityPass.fullscreen.readMore.url".localized)
        return CVRow(title: "activityPass.fullscreen.title".localized,
                     subtitle: "activityPass.fullscreen.explanation".localized,
                     buttonTitle: url == nil ? nil : "activityPass.fullscreen.readMore".localized,
                     xibName: .paragraphCell,
                     theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                        topInset: Appearance.Cell.Inset.medium,
                                        bottomInset: .zero,
                                        textAlignment: .center,
                                        titleFont: { Appearance.Cell.Text.headTitleFont }),
                     selectionAction: url == nil ? nil : { _ in
                        url?.openInSafari()
                     })
    }
    
    private func activityPassNotEligibleRow() -> CVRow {
        CVRow(title: "activityPass.fullscreen.title".localized,
              subtitle: "activityPass.fullscreen.notValid.message".localized,
              xibName: .paragraphCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.medium,
                                 bottomInset: .zero,
                                 textAlignment: .center,
                                 titleFont: { Appearance.Cell.Text.headTitleFont }))
    }

    private func activityPassServerNotAvailableRow() -> CVRow {
        CVRow(title: "activityPass.fullscreen.title".localized,
              subtitle: "activityPass.fullscreen.serverUnavailable.message".localized,
              xibName: .paragraphCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.medium,
                                 bottomInset: .zero,
                                 textAlignment: .center,
                                 titleFont: { Appearance.Cell.Text.headTitleFont }))
    }

    private func activityPassAvailableSoonRow(availabilityDate: Date) -> CVRow {
        CVRow(title: "activityPass.fullscreen.title".localized,
              subtitle: String(format: "activityPass.fullscreen.notAvailable.message".localized, availabilityDate.dayMonthYearTimeFormatted()),
              xibName: .paragraphCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.medium,
                                 bottomInset: .zero,
                                 textAlignment: .center,
                                 titleFont: { Appearance.Cell.Text.headTitleFont }))
    }
    
    private func notifyMeButtonRow(availabilityDate: Date) -> CVRow {
        CVRow(title: "activityPass.fullscreen.notAvailable.button.notify.title".localized,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                 bottomInset: .zero),
              selectionAction: { _ in
            NotificationsManager.shared.scheduleActivityPassAvailable(triggerDate: availabilityDate)
            HUD.flash(.success)
        })
    }
    
    private func notifyMeFooterRow(for availabilityDate: Date) -> CVRow {
        let footer: String = String(format: "activityPass.fullscreen.notAvailable.footer.notify".localized, availabilityDate.dayMonthYearTimeFormatted())
        return CVRow(title: footer,
                     xibName: .textCell,
                     theme: CVRow.Theme(topInset: Appearance.Cell.Inset.small,
                                        bottomInset: .zero,
                                        textAlignment: .natural,
                                        titleFont: { Appearance.Cell.Text.accessoryFont },
                                        titleColor: Appearance.Cell.Text.captionTitleColor))
    }

    private func activityPassExpirationRow(_ certificate: ActivityCertificate) -> CVRow {
        CVRow(xibName: .activityPassExpirationCell,
              theme: CVRow.Theme(backgroundColor: Appearance.tintColor,
                                 textAlignment: .center,
                                 titleFont: { .regular(size: 15.0) },
                                 titleColor: .white),
              associatedValue: certificate.endDate.timeIntervalSince1970,
              willDisplay: { [weak self] cell in
            self?.activityCertificateExpirationCell = cell as? ActivityPassExpirationCell
        })
    }
}

extension FullscreenCertificateViewController {
    
    private func updateBrightnessForQRCodeReadabilityIfNeeded() {
        switch mode {
        case .activityPass:
            isHavingActivityCertificate ? updateBrightnessForQRCodeReadability() : putBrightnessBackToOriginalValue()
        default:
            updateBrightnessForQRCodeReadability()
        }
    }

    private func updateBrightnessForQRCodeReadability() {
        guard autoBrightnessActivated else { return }
        if lastBrightness == nil { lastBrightness = round(UIScreen.main.brightness * 100.0) / 100.0 }
        UIScreen.main.brightness = 1.0
    }

    private func putBrightnessBackToOriginalValue() {
        lastBrightness.map { UIScreen.main.brightness = $0 }
    }

    @objc private func appDidBecomeActive() {
        updateBrightnessForQRCodeReadabilityIfNeeded()
    }

    @objc private func appWillResignActive() {
        putBrightnessBackToOriginalValue()
    }

}

extension FullscreenCertificateViewController {

    private func startTimer() {
        print("⏰ Start Timer")
        timer?.invalidate()
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }

    @objc private func timerFired() {
        print("⏰ Timer fired")
        processCertificatesUpdatesIfNeeded()
    }

    private func stopTimer() {
        print("⏰ Stop Timer")
        timer?.invalidate()
        timer = nil
    }

    private func processCertificatesUpdatesIfNeeded() {
        if WalletManager.shared.activityCertificateIdFor(certificate: certificate as? EuropeanCertificate) != currentActivityCertificate?.id {
            // We can arrive here due to 2 reasons:
            //  • We had a valid certificate, it expired and a new one is available.
            //  • We had a valid certificate, it expired and we don't have certificates anymore.
            updateActivityCertificate()
            wasCertificateValid = currentActivityCertificate?.isValid == true
            if !isHavingActivityCertificate { stopTimer() }
            if mode == .activityPass {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                reloadUI(animated: true)
            }
        } else if !wasCertificateValid && currentActivityCertificate?.isValid == true {
            // In this case, it means that the current certificate was valid in the future and it just becomes valid now.
            wasCertificateValid = true
            if mode == .activityPass {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                reloadUI(animated: true)
            }
        } else if mode == .activityPass {
            activityCertificateExpirationCell?.reload()
        }
    }

}

extension FullscreenCertificateViewController: WalletChangesObserver {
    
    func walletCertificatesDidUpdate() { }
    func walletFavoriteCertificateDidUpdate() {}
    func walletActivityCertificateDidUpdate() {
        processCertificatesUpdatesIfNeeded()
        if isHavingActivityCertificate && timer == nil { startTimer() }
        showWidgetUpdateConfirmationIfNeeded()
        updateBrightnessForQRCodeReadabilityIfNeeded()
    }
    func walletSmartStateDidUpdate() {}

}
