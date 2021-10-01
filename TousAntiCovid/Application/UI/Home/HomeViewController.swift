// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  HomeViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK

final class HomeViewController: CVTableViewController {

    var canActivateProximity: Bool { areNotificationsAuthorized == true && BluetoothStateManager.shared.isAuthorized && BluetoothStateManager.shared.isActivated }
    private let showCaptchaChallenge: (_ captcha: Captcha, _ didEnterCaptcha: @escaping (_ id: String, _ answer: String) -> (), _ didCancelCaptcha: @escaping () -> ()) -> ()
    private let didTouchAppUpdate: () -> ()
    private let didTouchDocument: () -> ()
    private let didTouchManageData: () -> ()
    private let didTouchPrivacy: () -> ()
    private let didTouchAbout: () -> ()
    private var didFinishLoad: (() -> ())?
    private var didTouchSupport: (() -> ())?
    private let didTouchHealth: () -> ()
    private let didTouchInfo: () -> ()
    private let didTouchKeyFigure: (_ keyFigure: KeyFigure) -> ()
    private let didTouchKeyFigures: () -> ()
    private let didTouchDeclare: () -> ()
    private let didTouchUsefulLinks: () -> ()
    private let didTouchRecordVenues: () -> ()
    private let didTouchVenuesHistory: () -> ()
    private let didRecordVenue: (_ url: URL) -> ()
    private let didRequestVenueScanAuthorization: (_ completion: @escaping (_ granted: Bool) -> ()) -> ()
    private(set) var didTouchOpenIsolationForm: () -> ()
    private let didTouchVaccination: () -> ()
    private let didTouchSanitaryCertificates: (_ url: URL?) -> ()
    private let didTouchVerifyWalletCertificate: () -> ()
    private let didTouchUniversalQrScan: () -> ()
    private let didTouchCertificate: (_ certificate: WalletCertificate) -> ()
    private let didEnterCodeFromDeeplink: (_ code: String) -> ()
    private let showUniversalQrScanExplanation: (_ initialButtonFrame: CGRect?, _ animationDidEnd: @escaping (_ animated: Bool) -> ()) -> ()
    private let showUserLanguage: () -> ()
    private let deinitBlock: () -> ()
    
    private var popRecognizer: InteractivePopGestureRecognizer?
    private var initialContentOffset: CGFloat?
    private var isActivated: Bool { canActivateProximity && RBManager.shared.isProximityActivated }
    private var wasActivated: Bool = false
    private var isChangingState: Bool = false
    private var didShowRobertErrorAlertOnce: Bool = false
    
    private var areNotificationsAuthorized: Bool?
    private weak var stateCell: StateAnimationCell?
    private var isWaitingForNeededInfo: Bool = true
    private var isSickWarningPeriod: Bool {
        if RBManager.shared.isImmune, let reportDate = RBManager.shared.reportDate {
            return reportDate.dateByAddingDays(ParametersManager.shared.covidPlusWarning) > Date()
        } else {
            return false
        }
    }

    @UserDefault(key: .latestAvailableBuild)
    private var latestAvailableBuild: Int?

    @UserDefault(key: .didAlreadyShowUniversalQrCodeExplanations)
    private var didAlreadyShowUniversalQrCodeExplanations: Bool = false
    
    @UserDefault(key: .didAlreadyShowUserLanguage)
    private var didAlreadyShowUserLanguage: Bool = false
    
    init(didTouchAbout: @escaping () -> (),
         showCaptchaChallenge: @escaping (_ captcha: Captcha, _ didEnterCaptcha: @escaping (_ id: String, _ answer: String) -> (), _ didCancelCaptcha: @escaping () -> ()) -> (),
         didTouchAppUpdate: @escaping () -> (),
         didTouchDocument: @escaping () -> (),
         didTouchManageData: @escaping () -> (),
         didTouchPrivacy: @escaping () -> (),
         didFinishLoad: (() -> ())?,
         didTouchSupport: (() -> ())? = nil,
         didTouchHealth: @escaping () -> (),
         didTouchInfo: @escaping () -> (),
         didTouchKeyFigure: @escaping (_ keyFigure: KeyFigure) -> (),
         didTouchKeyFigures: @escaping () -> (),
         didTouchDeclare: @escaping () -> (),
         didTouchUsefulLinks: @escaping () -> (),
         didTouchRecordVenues: @escaping () -> (),
         didTouchVenuesHistory: @escaping () -> (),
         didRecordVenue: @escaping (_ url: URL) -> (),
         didRequestVenueScanAuthorization: @escaping (_ completion: @escaping (_ granted: Bool) -> ()) -> (),
         didTouchOpenIsolationForm: @escaping () -> (),
         didTouchVaccination: @escaping () -> (),
         didTouchSanitaryCertificates: @escaping (_ url: URL?) -> (),
         didTouchVerifyWalletCertificate: @escaping () -> (),
         didTouchUniversalQrScan: @escaping () -> (),
         didTouchCertificate: @escaping (_ certificate: WalletCertificate) -> (),
         showUniversalQrScanExplanation: @escaping (_ initialButtonFrame: CGRect?, _ animationDidEnd: @escaping (_ animated: Bool) -> ()) -> (),
         didEnterCodeFromDeeplink: @escaping (_ code: String) -> (),
         showUserLanguage: @escaping () -> (),
         deinitBlock: @escaping () -> ()) {
        self.didTouchAppUpdate = didTouchAppUpdate
        self.didTouchDocument = didTouchDocument
        self.didTouchAbout = didTouchAbout
        self.didTouchManageData = didTouchManageData
        self.didTouchPrivacy = didTouchPrivacy
        self.showCaptchaChallenge = showCaptchaChallenge
        self.didFinishLoad = didFinishLoad
        self.didTouchSupport = didTouchSupport
        self.didTouchHealth = didTouchHealth
        self.didTouchInfo = didTouchInfo
        self.didTouchKeyFigure = didTouchKeyFigure
        self.didTouchKeyFigures = didTouchKeyFigures
        self.didTouchDeclare = didTouchDeclare
        self.didTouchUsefulLinks = didTouchUsefulLinks
        self.didTouchRecordVenues = didTouchRecordVenues
        self.didTouchVenuesHistory = didTouchVenuesHistory
        self.didRecordVenue = didRecordVenue
        self.didRequestVenueScanAuthorization = didRequestVenueScanAuthorization
        self.didTouchOpenIsolationForm = didTouchOpenIsolationForm
        self.didTouchVaccination = didTouchVaccination
        self.didTouchSanitaryCertificates = didTouchSanitaryCertificates
        self.didTouchVerifyWalletCertificate = didTouchVerifyWalletCertificate
        self.didTouchUniversalQrScan = didTouchUniversalQrScan
        self.showUniversalQrScanExplanation = showUniversalQrScanExplanation
        self.didTouchCertificate = didTouchCertificate
        self.didEnterCodeFromDeeplink = didEnterCodeFromDeeplink
        self.showUserLanguage = showUserLanguage
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        initBottomMessageContainer()
        addObserver()
        setInteractiveRecognizer()
        wasActivated = RBManager.shared.isProximityActivated
        if !RBManager.shared.isRegistered {
            areNotificationsAuthorized = true
            isWaitingForNeededInfo = false
        }
        updateNotificationsState { self.updateUIForAuthorizationChange() }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initInitialContentOffset()
        stateCell?.continuePlayingIfNeeded()
        showUniversalQrCodeExplanationsIfNeeded()
        showUserLanguageIfNeeded()
        displayRobertUnregisteredAlertIfNecessary()
    }
    
    deinit {
        removeObservers()
        deinitBlock()
    }
    
    private func initInitialContentOffset() {
        if initialContentOffset == nil {
            initialContentOffset = tableView.contentOffset.y
        }
    }
    
    private func updateTitle() {
        title = isActivated ? "home.title.activated".localized : "home.title.deactivated".localized
        navigationChildController?.updateTitle(title)
    }
    
    private func updateNotificationsState(_ completion: (() -> ())? = nil) {
        NotificationsManager.shared.areNotificationsAuthorized { notificationsAuthorized in
            self.areNotificationsAuthorized = notificationsAuthorized
            if !BluetoothStateManager.shared.isUnknown {
                self.isWaitingForNeededInfo = false
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    private func updateUIForAuthorizationChange() {
        guard let areNotificationsAuthorized = areNotificationsAuthorized, !isWaitingForNeededInfo else { return }
        let messageFont: UIFont? = Appearance.BottomMessage.font
        let messageTextColor: UIColor = .black
        let messageBackgroundColor: UIColor = Asset.Colors.info.color
        if RBManager.shared.isImmune {
            bottomMessageContainerController?.updateMessage { [weak self] in self?.updateTableViewBottomInset() }
        } else if !areNotificationsAuthorized && !BluetoothStateManager.shared.isAuthorized {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.noNotificationsOrBluetooth".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor,
                                                            actionHint: "accessibility.hint.proximity.alert.touchToGoToSettings.ios".localized) { [weak self] in
                self?.updateTableViewBottomInset()
            }
        } else if !areNotificationsAuthorized {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.noNotifications".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor,
                                                            actionHint: "accessibility.hint.proximity.alert.touchToGoToSettings.ios".localized) { [weak self] in
                self?.updateTableViewBottomInset()
            }
        } else if !BluetoothStateManager.shared.isAuthorized {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.noBluetooth".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor,
                                                            actionHint: "accessibility.hint.proximity.alert.touchToGoToSettings.ios".localized) { [weak self] in
                self?.updateTableViewBottomInset()
            }
        } else if !BluetoothStateManager.shared.isActivated {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.bluetoothOff".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor) {
                [weak self] in self?.updateTableViewBottomInset()
            }
        } else if !RBManager.shared.isProximityActivated {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.activateProximity".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor) { [weak self] in
                self?.updateTableViewBottomInset()
            }
        } else if UIApplication.shared.backgroundRefreshStatus == .denied {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.noBackgroundAppRefresh".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor) { [weak self] in
                self?.updateTableViewBottomInset()
            }
        } else {
            bottomMessageContainerController?.updateMessage { [weak self] in self?.updateTableViewBottomInset() }
        }
        updateTitle()
        reloadUI(animated: true) {
            if self.wasActivated != self.isActivated {
                self.wasActivated = self.isActivated
                if self.isActivated == true {
                    self.stateCell?.setOn()
                } else {
                    self.stateCell?.setOff()
                }
            }
            self.didFinishLoad?()
            self.didFinishLoad = nil
        }
    }

    private func showUserLanguageIfNeeded() {
        guard !didAlreadyShowUserLanguage else { return }
        guard Constant.appLanguage.isNil else { return }
        guard !Locale.isCurrentLanguageSupported else { return }
        didAlreadyShowUserLanguage = true
        showUserLanguage()
    }
    
    private func showUniversalQrCodeExplanationsIfNeeded() {
        guard !didAlreadyShowUniversalQrCodeExplanations else { return }
        guard !DeepLinkingManager.shared.appLaunchedFromDeeplinkOrShortcut else { return }
        didAlreadyShowUniversalQrCodeExplanations = true
        navigationChildController?.rightBarButtonItemView?.alpha = 0.0
        showUniversalQrScanExplanation(navigationChildController?.rightBarButtonItemFrame(in: navigationController?.view ?? view)) { [weak self] animated in
            self?.navigationChildController?.rightBarButtonItemView?.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            UIView.animate(withDuration: animated ? 0.7 : 0.0, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 1.0, options: .curveEaseInOut) {
                self?.navigationChildController?.rightBarButtonItemView?.alpha = 1.0
                self?.navigationChildController?.rightBarButtonItemView?.transform = .identity
            }
        }
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let titleRow: CVRow = CVRow.titleRow(title: title) { [weak self] cell in
            self?.navigationChildController?.updateLabel(titleLabel: cell.cvTitleLabel, containerView: cell)
            cell.isAccessibilityElement = false
            cell.accessibilityElements = []
            cell.accessibilityElementsHidden = true
        }
        rows.append(titleRow)
        let stateRow: CVRow = CVRow(xibName: .stateAnimationCell,
                                    theme: CVRow.Theme(topInset: 30.0, separatorLeftInset: nil),
                                    willDisplay: { [weak self] cell in
                                        self?.stateCell = cell as? StateAnimationCell
                                        if self?.wasActivated == true {
                                            self?.stateCell?.setOn(animated: false)
                                        } else {
                                            self?.stateCell?.setOff(animated: false)
                                        }
        })
        rows.append(stateRow)
        rows.append(activationButtonRow(isRegistered: RBManager.shared.isRegistered))
        rows.append(qrScanRow())
        if let latestAvailableBuild = latestAvailableBuild, latestAvailableBuild > Int(UIApplication.shared.buildNumber) ?? 0 {
            rows.append(appUpdateRow())
        }
        rows.append(contentsOf: walletSectionRows())
        rows.append(contentsOf: healthSectionRows())
        if VenuesManager.shared.isVenuesRecordingActivated {
            rows.append(contentsOf: venuesSectionRows())
        }
        if ParametersManager.shared.displayAttestation {
            rows.append(contentsOf: attestationSectionRows())
        }
        rows.append(contentsOf: infoSectionRows())
        rows.append(contentsOf: moreSectionRows())
        return rows
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if canActivateProximity && RBManager.shared.isProximityActivated {
            let distance: CGFloat = abs((initialContentOffset ?? 0.0) - tableView.contentOffset.y) + (tableView.tableFooterView?.frame.height ?? 0.0)
            if tableView.contentInset.bottom != 0.0 && distance < tableView.contentInset.bottom {
                tableView.contentInset.bottom = 0.0
            }
        }
        navigationChildController?.scrollViewDidScroll(scrollView)
    }

    private func initUI() {
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: navigationChildController?.navigationBarHeight ?? 0.0))
        updateTableViewBottomInset()
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.canCancelContentTouches = true
        navigationController?.setNavigationBarHidden(true, animated: false)

        let scanBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: Asset.Images.qrScanItem.image, style: .plain, target: self, action: #selector(scanQrButtonPressed))
        scanBarButtonItem.accessibilityLabel = "home.qrScan.button.title".localized
        navigationChildController?.updateRightBarButtonItem(scanBarButtonItem)
        navigationChildController?.navigationBar.isAccessibilityElement = false
    }

    private func updateTableViewBottomInset() {
        let bottomSafeArea: CGFloat = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: max(bottomMessageContainerController?.messageHeight ?? bottomSafeArea, bottomSafeArea) + 20.0))
    }

    private func initBottomMessageContainer() {
        bottomMessageContainerController?.messageDidTouch = { [weak self] in
            guard let self = self else { return }
            if self.canActivateProximity {
                if UIApplication.shared.backgroundRefreshStatus == .denied {
                    UIApplication.shared.openSettings()
                } else {
                    self.didChangeSwitchValue(isOn: true)
                }
            } else if self.areNotificationsAuthorized != true || !BluetoothStateManager.shared.isAuthorized {
                UIApplication.shared.openSettings()
            }
        }
    }

    private func addObserver() {
        LocalizationsManager.shared.addObserver(self)
        BluetoothStateManager.shared.addObserver(self)
        InfoCenterManager.shared.addObserver(self)
        KeyFiguresManager.shared.addObserver(self)
        AttestationsManager.shared.addObserver(self)
        IsolationManager.shared.addObserver(self)
        WalletManager.shared.addObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(statusDataChanged), name: .statusDataDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(requestRegister), name: .requestRegister, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didTouchProximityReactivationNotification), name: .didTouchProximityReactivationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openFullVenueRecordingFlowFromDeeplink), name: .openFullVenueRecordingFlowFromDeeplink, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newVenueRecordingFromDeeplink(_:)), name: .newVenueRecordingFromDeeplink, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newWalletCertificateFromDeeplink(_:)), name: .newWalletCertificateFromDeeplink, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(lastAvailableBuildDidUpdate), name: .lastAvailableBuildDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openQrScan), name: .openQrScan, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterCodeFromDeeplink(_:)), name: .didEnterCodeFromDeeplink, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newAttestationFromDeeplink), name: .newAttestationFromDeeplink, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didCompletedVaccinationNotification), name: .didCompletedVaccinationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openWallet), name: .openWallet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openCertificateQRCode), name: .openCertificateQRCode, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(voiceOverStatusDidChange), name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(displayRobertUnregisteredAlertIfNecessary), name: .gotRobert430Error, object: nil)
    }
    
    private func removeObservers() {
        LocalizationsManager.shared.removeObserver(self)
        BluetoothStateManager.shared.removeObserver(self)
        InfoCenterManager.shared.removeObserver(self)
        KeyFiguresManager.shared.removeObserver(self)
        IsolationManager.shared.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func scanQrButtonPressed() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        AnalyticsManager.shared.reportAppEvent(.e18)
        // This asyncAfter is here not to have a freeze for the Haptic feedback.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.openQrScan()
        }
    }

    @objc private func openQrScan() {
        CameraAuthorizationManager.requestAuthorization { granted, isFirstTimeRequest in
            if granted {
                self.didTouchUniversalQrScan()
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

    @objc private func didEnterCodeFromDeeplink(_ notification: Notification) {
        guard let code = notification.object as? String else { return }
        didEnterCodeFromDeeplink(code)
    }

    @objc private func newAttestationFromDeeplink() {
        didTouchDocument()
    }

    private func didTouchIsSickReadMore() {
        showAlert(title: "home.activation.sick.alert.title".localized,
                  message: "home.activation.sick.alert.message".localized,
                  okTitle: "common.ok".localized)
    }

    @objc private func didCompletedVaccinationNotification() {
        didTouchSanitaryCertificates(nil)
    }
    
    @objc private func openWallet() {
        didTouchSanitaryCertificates(nil)
    }
    
    @objc private func openCertificateQRCode() {
        guard let certificate = WalletManager.shared.favoriteCertificate else { return }
        didTouchCertificate(certificate)
    }
    
    private func didChangeSwitchValue(isOn: Bool) {
        guard !isChangingState else { return }
        isChangingState = true
        if isOn {
            cancelReactivationReminder()
            if RBManager.shared.isRegistered {
                if RBManager.shared.currentEpoch == nil {
                    processStatus()
                } else {
                    processRegistrationDone()
                    isChangingState = false
                }
            } else {
                HUD.show(.progress)
                ConfigManager.shared.fetch { result in
                    HUD.hide()
                    self.processRegisterWithCaptcha { _ in
                        self.isChangingState = false
                    }
                }
            }
        } else {
            RBManager.shared.isProximityActivated = false
            RBManager.shared.stopProximityDetection()
            isChangingState = false
            showDeactivationReminderActionSheet()
            AnalyticsManager.shared.proximityDidStop()
        }
    }
    
    private func processOnlyRegistrationIfNeeded(_ completion: @escaping (_ error: Error?) -> ()) {
        if RBManager.shared.isRegistered {
            completion(nil)
        } else {
            processRegisterWithCaptcha(activateProximityAfterRegistration: false) { error in
                self.reloadUI(animated: true)
                completion(error)
            }
        }
    }
    
    private func processRegisterWithCaptcha(activateProximityAfterRegistration: Bool = true, completion: @escaping (_ error: Error?) -> ()) {
        HUD.show(.progress)
        generateCaptcha { result in
            HUD.hide()
            switch result {
            case let .success(captcha):
                self.showCaptchaChallenge(captcha, { id, answer in
                    self.processRegister(answer: answer, captchaId: id, activateProximityAfterRegistration: activateProximityAfterRegistration) { error in
                        completion(error)
                    }
                }, { [weak self] in
                    self?.isChangingState = false
                })
            case let .failure(error):
                self.showAlert(title: "common.error".localized,
                               message: "common.error.server".localized,
                               okTitle: "common.retry".localized,
                               cancelTitle: "common.cancel".localized, handler: { [weak self] in
                                self?.didChangeSwitchValue(isOn: true)
                })
                completion(error)
            }
        }
    }
    
    private func processStatus() {
        HUD.show(.progress)
        StatusManager.shared.status(force: true) { error in
            HUD.hide()
            self.isChangingState = false
            if let error = error {
                if (error as NSError).code == -1 {
                    self.showAlert(title: "common.error.clockNotAligned.title".localized,
                                   message: "common.error.clockNotAligned.message".localized,
                                   okTitle: "common.ok".localized)
                } else {
                    self.showAlert(title: "common.error".localized,
                                   message: "common.error.server".localized,
                                   okTitle: "common.ok".localized)
                }
            } else {
                self.processRegistrationDone()
            }
        }
    }
    
    private func processRegister(answer: String, captchaId: String, activateProximityAfterRegistration: Bool = true, completion: @escaping (_ error: Error?) -> ()) {
        HUD.show(.progress)
        RBManager.shared.register(captcha: answer, captchaId: captchaId) { error in
            HUD.hide()
            if let error = error {
                AnalyticsManager.shared.reportError(serviceName: "register", apiVersion: ParametersManager.shared.apiVersion, code: (error as NSError).code)
                if (error as NSError).code == -1 {
                    self.showAlert(title: "common.error.clockNotAligned.title".localized,
                                   message: "common.error.clockNotAligned.message".localized,
                                   okTitle: "common.ok".localized)
                } else if (error as NSError).code == 401 {
                    self.showAlert(title: "captchaController.alert.invalidCode.title".localized,
                                   message: "captchaController.alert.invalidCode.message".localized,
                                   okTitle: "common.retry".localized,
                                   cancelTitle: "common.cancel".localized, handler: { [weak self] in
                                    self?.didChangeSwitchValue(isOn: true)
                    })
                } else {
                    self.showAlert(title: "common.error".localized,
                                   message: "common.error.server".localized,
                                   okTitle: "common.retry".localized,
                                   cancelTitle: "common.cancel".localized, handler: { [weak self] in
                                    self?.didChangeSwitchValue(isOn: true)
                    })
                }
                completion(error)
            } else {
                if activateProximityAfterRegistration {
                    self.processRegistrationDone()
                }
                completion(nil)
            }
        }
    }
    
    private func generateCaptcha(_ completion: @escaping (_ result: Result<Captcha, Error>) -> ()) {
        if UIAccessibility.isVoiceOverRunning {
            CaptchaManager.shared.generateCaptchaAudio { result in
                completion(result)
            }
        } else {
            CaptchaManager.shared.generateCaptchaImage { result in
                completion(result)
            }
        }
    }
    
    private func processRegistrationDone() {
        RBManager.shared.isProximityActivated = true
        RBManager.shared.startProximityDetection()
        AnalyticsManager.shared.proximityDidStart()
    }
    
    @objc private func appDidBecomeActive() {
        updateNotificationsState {
            self.updateUIForAuthorizationChange()
        }
    }
    
    @objc private func statusDataChanged() {
        updateUIForAuthorizationChange()
    }
    
    @objc private func requestRegister() {
        didChangeSwitchValue(isOn: true)
    }
    
    @objc private func didTouchProximityReactivationNotification() {
        dismiss(animated: true) {
            self.didChangeSwitchValue(isOn: true)
        }
    }
    
    @objc private func openFullVenueRecordingFlowFromDeeplink() {
        processOnlyRegistrationIfNeeded { error in
            guard error == nil else { return }
            self.didTouchRecordVenues()
        }
    }
    
    @objc private func newVenueRecordingFromDeeplink(_ notification: Notification) {
        if isSickWarningPeriod {
            showAlert(title: "home.venuesSection.sickAlert.title".localized,
                      message: "home.venuesSection.sickAlert.message".localized,
                      okTitle: "home.venuesSection.sickAlert.positiveButton".localized,
                      cancelTitle: "home.venuesSection.sickAlert.negativeButton".localized,
                      handler: { [weak self] in
                        guard let url = notification.object as? URL else { return }
                        self?.newVenueRecordingFromDeeplink(url: url)
                      })
        }  else {
            guard let url = notification.object as? URL else { return }
            newVenueRecordingFromDeeplink(url: url)
        }
    }

    private func newVenueRecordingFromDeeplink(url: URL) {
        didRequestVenueScanAuthorization { granted in
            guard granted else { return }
            self.processOnlyRegistrationIfNeeded { error in
                guard error == nil else { return }
                if VenuesManager.shared.processVenueUrl(url) != nil {
                    self.didRecordVenue(url)
                    self.reloadUI(animated: true)
                } else {
                    self.showVenueRecordingAlertError()
                }
            }
        }
    }
    
    @objc private func newWalletCertificateFromDeeplink(_ notification: Notification) {
        guard let url = notification.object as? URL else { return }
        didTouchSanitaryCertificates(url)
    }

    @objc private func lastAvailableBuildDidUpdate() {
        reloadUI(animated: true)
    }
    
    private func showVenueRecordingAlertError() {
        showAlert(title: "venueFlashCodeController.alert.invalidCode.title".localized,
                  message: "venueFlashCodeController.alert.invalidCode.message".localized,
                  okTitle: "common.ok".localized)
    }
    
    private func setInteractiveRecognizer() {
        guard let navigationController = navigationController else { return }
        popRecognizer = InteractivePopGestureRecognizer(controller: navigationController)
        navigationController.interactivePopGestureRecognizer?.delegate = popRecognizer
    }
    
    private func showDeactivationReminderActionSheet() {
        let alertController: UIAlertController = UIAlertController(title: "home.deactivate.actionSheet.title".localized,
                                                                   message: "home.deactivate.actionSheet.subtitle".localized,
                                                                   preferredStyle: .actionSheet)
        ParametersManager.shared.proximityReactivationReminderHours.forEach { hours in
            let hoursString: String = hours == 1 ? "home.deactivate.actionSheet.hours.singular" : "home.deactivate.actionSheet.hours.plural"
            alertController.addAction(UIAlertAction(title: String(format: hoursString.localized, Int(hours)), style: .default) { [weak self] _ in
                self?.triggerReactivationReminder(hours: Double(hours))
            })
        }
        alertController.addAction(UIAlertAction(title: "home.deactivate.actionSheet.noReminder".localized, style: .cancel) { [weak self] _ in
            self?.cancelReactivationReminder()
        })
        present(alertController, animated: true)
    }
    
    private func triggerReactivationReminder(hours: Double) {
        NotificationsManager.shared.scheduleProximityReactivationNotification(hours: hours)
    }
    
    private func cancelReactivationReminder() {
        NotificationsManager.shared.cancelProximityReactivationNotification()
    }

}

extension HomeViewController {
    
    private func activationButtonRow(isRegistered: Bool) -> CVRow {
        let buttonAccessibilityLabel: String = isActivated ? "accessibility.home.mainButton.deactivate".localized : "accessibility.home.mainButton.activate".localized
        if isRegistered {
            let activationTitle: String = isActivated ? "home.mainButton.deactivate".localized : "home.mainButton.activate".localized
            let activationButtonRow: CVRow = CVRow(title: RBManager.shared.isImmune ? "common.readMore".localized : activationTitle,
                                                   xibName: .buttonCell,
                                                   theme: CVRow.Theme(topInset: 0.0, bottomInset: 0.0, buttonStyle: isActivated ? .secondary : .primary),
                                                   enabled: canActivateProximity,
                                                   selectionAction: { [weak self] in
                                                    guard let self = self else { return }
                                                    if RBManager.shared.isImmune {
                                                        self.didTouchIsSickReadMore()
                                                    } else {
                                                        self.didChangeSwitchValue(isOn: !self.isActivated)
                                                    }
                                                   }, willDisplay: { cell in
                                                    guard let buttonCell = cell as? ButtonCell else { return }
                                                    buttonCell.button.accessibilityLabel = buttonAccessibilityLabel
                                                   })
            return activationButtonRow
        } else {
            let activationButtonRow: CVRow = CVRow(title: isActivated ? "home.mainButton.deactivate".localized : "home.mainButton.activate".localized,
                                                   subtitle: "home.activationExplanation".localized,
                                                   xibName: .activationButtonCell,
                                                   theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                                      topInset: 0.0,
                                                                      bottomInset: 0.0,
                                                                      textAlignment: .natural,
                                                                      buttonStyle: isActivated ? .secondary : .primary),
                                                   enabled: canActivateProximity,
                                                   selectionAction: { [weak self] in
                                                    guard let self = self else { return }
                                                    self.didChangeSwitchValue(isOn: !self.isActivated)
                                                   }, willDisplay: { cell in
                                                    guard let buttonCell = cell as? ActivationButtonCell else { return }
                                                    buttonCell.button.accessibilityLabel = buttonAccessibilityLabel
                                                   })
            return activationButtonRow
        }
    }

    private func qrScanRow() -> CVRow {
        CVRow(title: "home.qrScan.button.title".localized,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.leftMargin, bottomInset: 0.0, buttonStyle: .secondary),
              selectionAction: { [weak self] in
                AnalyticsManager.shared.reportAppEvent(.e19)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.openQrScan()
                }
              })
    }
    
    private func appUpdateRow() -> CVRow {
        CVRow(title: "home.appUpdate.cell.title".localized,
              subtitle: "home.appUpdate.cell.subtitle".localized,
              image: Asset.Images.updateApp.image,
              xibName: .updateAppCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.leftMargin,
                                 bottomInset: 0.0,
                                 textAlignment: .natural),
              selectionAction: { [weak self] in
                self?.didTouchAppUpdate()
              })
    }
    
    private func healthSectionRows() -> [CVRow] {
        var rows: [CVRow] = []
        
        if !StatusManager.shared.hideStatus {
            if RBManager.shared.isImmune {
                let row: CVRow = contactStatusRow(header: nil,
                                                  title: "home.healthSection.isSick.standaloneTitle".localized,
                                                  subtitle: nil,
                                                  startColor: Asset.Colors.gradientStartBlue.color,
                                                  endColor: Asset.Colors.gradientEndBlue.color,
                                                  effectAlpha: Appearance.sickEffectAlpha)
                rows.append(row)
            } else if let currentRiskLevel = RisksUIManager.shared.currentLevel {
                let isStatusOnGoing: Bool = StatusManager.shared.isStatusOnGoing
                let notificationDate: Date? = RBManager.shared.lastStatusReceivedDate
                let notificationDateString: String? = currentRiskLevel.riskLevel == 0 ? notificationDate?.relativelyFormatted() : nil
                let row: CVRow = contactStatusRow(header: notificationDateString,
                                                  title: currentRiskLevel.labels.homeTitle.localized,
                                                  subtitle: currentRiskLevel.labels.homeSub.localized,
                                                  startColor: currentRiskLevel.color.fromColor,
                                                  endColor: currentRiskLevel.color.toColor,
                                                  effectAlpha: currentRiskLevel.effectAlpha,
                                                  isStatusOnGoing: isStatusOnGoing)
                rows.append(row)
                if isStatusOnGoing {
                    rows.append(statusVerificationRow(for: currentRiskLevel))
                }
            }
        }

        let showDeclare: Bool = RBManager.shared.isRegistered && !RBManager.shared.isImmune
        let displayVaccination: Bool = ParametersManager.shared.displayVaccination
        if ParametersManager.shared.displayIsolation {
            rows.append(contentsOf: isolationRows(isLastSectionBlock: !showDeclare && !displayVaccination))
        }

        if showDeclare {
            let declareRow: CVRow = CVRow(title: "home.declareSection.cellTitle".localized,
                                          subtitle: "home.declareSection.cellSubtitle".localized,
                                          image: Asset.Images.declareCard.image,
                                          xibName: .declareCell,
                                          theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                             topInset: 0.0,
                                                             bottomInset: Appearance.Cell.leftMargin,
                                                             textAlignment: .natural),
                                          selectionAction: { [weak self] in
                                            self?.didTouchDeclare()
                                          })
            
            rows.append(declareRow)
        }
        if displayVaccination {
            let vaccinationRow: CVRow = CVRow(title: "home.vaccinationSection.cellTitle".localized,
                                              subtitle: "home.vaccinationSection.cellSubtitle".localized,
                                              image: Asset.Images.pharmacy.image,
                                              xibName: .vaccinationCell,
                                              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                                 topInset: 0.0,
                                                                 bottomInset: 0.0,
                                                                 textAlignment: .natural,
                                                                 titleColor: Asset.Colors.gradientEndGreen.color,
                                                                 imageTintColor: Asset.Colors.gradientEndGreen.color),
                                              selectionAction: { [weak self] in
                                                self?.didTouchVaccination()
                                              })
            
            rows.append(vaccinationRow)
        }
        if !rows.isEmpty {
            let healthSectionRow: CVRow = CVRow(title: "home.healthSection.title".localized,
                                                xibName: .textCell,
                                                theme: CVRow.Theme(topInset: 30.0,
                                                                   bottomInset: 10.0,
                                                                   textAlignment: .natural,
                                                                   titleFont: { Appearance.Cell.Text.headTitleFont }))
            rows.insert(healthSectionRow, at: 0)
        }
        return rows
    }

    private func contactStatusRow(header: String?, title: String, subtitle: String?, startColor: UIColor, endColor: UIColor, effectAlpha: CGFloat, isStatusOnGoing: Bool = false) -> CVRow {
        let contactStatusRow: CVRow = CVRow(title: title,
                                            subtitle: subtitle,
                                            accessoryText: header,
                                            image: Asset.Images.healthCard.image,
                                            xibName: .contactStatusCell,
                                            theme: CVRow.Theme(topInset: 0.0,
                                                               bottomInset: (RBManager.shared.isImmune && !ParametersManager.shared.displayIsolation || isStatusOnGoing) ? 0.0 : Appearance.Cell.leftMargin,
                                                               textAlignment: .natural,
                                                               titleColor: .white,
                                                               subtitleColor: .white,
                                                               maskedCorners: isStatusOnGoing ? .top : .all),
                                            associatedValue: (startColor, endColor, effectAlpha),
                                            selectionAction: { [weak self] in
                                                self?.didTouchHealth()
                                            })
        return contactStatusRow
    }

    private func statusVerificationRow(for currentRiskLevel: RisksUILevel) -> CVRow {
        CVRow(title: "home.healthSection.statusState".localized,
              xibName: .statusVerificationCell,
              theme: CVRow.Theme(topInset: -2.0,
                                 bottomInset: Appearance.Cell.leftMargin,
                                 textAlignment: .natural,
                                 maskedCorners: .bottom),
              associatedValue: currentRiskLevel,
              selectionAction: { [weak self] in
                self?.didTouchHealth()
              })
        
    }
    
    private func venuesSectionRows() -> [CVRow] {
        var rows: [CVRow] = []
        let venuesSectionRow: CVRow = CVRow(title: "home.venuesSection.title".localized,
                                            xibName: .textCell,
                                            theme: CVRow.Theme(topInset: 30.0,
                                                               bottomInset: 10.0,
                                                               textAlignment: .natural,
                                                               titleFont: { Appearance.Cell.Text.headTitleFont }))
        rows.append(venuesSectionRow)
        let recordRow: CVRow = CVRow(title: "home.venuesSection.recordCell.title".localized,
                                     subtitle: "home.venuesSection.recordCell.subtitle".localized,
                                     image: Asset.Images.shops.image,
                                     xibName: .venueRecordCell,
                                     theme: CVRow.Theme(backgroundColor: Appearance.tintColor,
                                                        topInset: 0.0,
                                                        bottomInset: 0.0,
                                                        textAlignment: .natural,
                                                        titleColor: Appearance.Button.Primary.titleColor,
                                                        subtitleColor: Appearance.Button.Primary.titleColor),
                                     selectionAction: { [weak self] in
                                        guard let self = self else { return }
                                        self.processOnlyRegistrationIfNeeded { error in
                                            guard error == nil else { return }
                                            CameraAuthorizationManager.requestAuthorization { granted, isFirstTimeRequest in
                                                if granted {
                                                    if self.isSickWarningPeriod {
                                                        self.showAlert(title: "home.venuesSection.sickAlert.title".localized,
                                                                        message: "home.venuesSection.sickAlert.message".localized,
                                                                        okTitle: "home.venuesSection.sickAlert.positiveButton".localized,
                                                                        cancelTitle: "home.venuesSection.sickAlert.negativeButton".localized,
                                                                        handler: { self.didTouchRecordVenues() })
                                                    }  else {
                                                        self.didTouchRecordVenues()
                                                    }
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
                                     })
        rows.append(recordRow)
        return rows
    }

    private func infoSectionRows() -> [CVRow] {
        var rows: [CVRow] = []
        let infoSectionRow: CVRow = CVRow(title: "home.infoSection.title".localized,
                                          xibName: .textCell,
                                          theme: CVRow.Theme(topInset: 30.0,
                                                             bottomInset: 10.0,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Cell.Text.headTitleFont }))
        rows.append(infoSectionRow)

        let isHavingFeaturedKeyFigures: Bool = !KeyFiguresManager.shared.featuredKeyFigures.isEmpty
        if isHavingFeaturedKeyFigures && !KeyFiguresManager.shared.canShowCurrentlyNeededFile {
            rows.append(contentsOf: keyFiguresWarningRows())
        }
        let highlightedKeyFigure: KeyFigure? = KeyFiguresManager.shared.highlightedKeyFigure
        if let highlightedKeyFigure = highlightedKeyFigure, highlightedKeyFigure.isLabelReady {
            let highlightedKeyFigureRow: CVRow = CVRow(title: ["home.infoSection.newCases".localized, "(\("common.country.france".localized))"].joined(separator: " "),
                                                       subtitle: highlightedKeyFigure.valueGlobalToDisplay.formattingValueWithThousandsSeparatorIfPossible(),
                                                       accessoryText: "keyfigure.dailyUpdates".localized,
                                                       image: Asset.Images.flag.image,
                                                       xibName: .highlightedKeyFigureCell,
                                                       theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                                          topInset: 0.0,
                                                                          bottomInset: Appearance.Cell.leftMargin,
                                                                          textAlignment: .natural,
                                                                          titleColor: highlightedKeyFigure.color,
                                                                          subtitleFont: { Appearance.Cell.Text.headTitleFont3 },
                                                                          subtitleColor: Appearance.Cell.Text.titleColor,
                                                                          accessoryTextFont: { Appearance.Cell.Text.captionTitleFont },
                                                                          accessoryTextColor: Appearance.Cell.Text.captionTitleColor,
                                                                          imageTintColor: highlightedKeyFigure.color),
                                                       selectionAction: { [weak self] in
                                                        self?.didTouchKeyFigure(highlightedKeyFigure)
                                                       })
            rows.append(highlightedKeyFigureRow)
        }
        if isHavingFeaturedKeyFigures {
            let keyFiguresRow: CVRow = CVRow(title: highlightedKeyFigure?.isLabelReady == true ? "home.infoSection.otherKeyFigures".localized : "home.infoSection.keyFigures".localized,
                                             accessoryText: highlightedKeyFigure?.isLabelReady == true ? nil :  "keyfigure.dailyUpdates".localized,
                                             buttonTitle: "home.infoSection.seeAll".localized,
                                             xibName: .keyFiguresCell,
                                             theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                                topInset: 0.0,
                                                                bottomInset: Appearance.Cell.leftMargin,
                                                                textAlignment: .natural),
                                             associatedValue: KeyFiguresManager.shared.featuredKeyFigures.filter { $0.isLabelReady },
                                             selectionAction: { [weak self] in
                                                self?.didTouchKeyFigures()
                                             })
            rows.append(keyFiguresRow)
        }
        if KeyFiguresManager.shared.displayDepartmentLevel {
            if let currentPostalCode = KeyFiguresManager.shared.currentPostalCode {
                let title: String = String(format: "common.updatePostalCode".localized, currentPostalCode)
                let updatePostalCodeRow: CVRow = CVRow(title: title,
                                                       subtitle: "common.updatePostalCode.end".localized,
                                                       image: Asset.Images.location.image,
                                                       xibName: .standardCardHorizontalCell,
                                                       theme:  CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                                           topInset: 0.0,
                                                                           bottomInset: Appearance.Cell.leftMargin,
                                                                           textAlignment: .natural,
                                                                           subtitleFont: { Appearance.Cell.Text.standardFont },
                                                                           subtitleColor: Appearance.Cell.Text.headerTitleColor,
                                                                           imageTintColor: Appearance.Cell.Text.headerTitleColor),
                                                       selectionAction: { [weak self] in
                                                        self?.didTouchUpdateLocation()
                                                       }, willDisplay: { [weak self] cell in
                                                        guard let self = self else { return }
                                                        cell.accessibilityLabel = title
                                                        cell.accessibilityTraits = []
                                                        cell.accessibilityCustomActions = [
                                                            UIAccessibilityCustomAction(name: "common.updatePostalCode.end".localized, target: self, selector: #selector(self.accessibilityDidActivateChangeLocation)),
                                                            UIAccessibilityCustomAction(name: "common.delete".localized, target: self, selector: #selector(self.accessibilityDidActivateDeleteLocation))
                                                        ]
                                                       })
                rows.append(updatePostalCodeRow)
            } else {
                let newPostalCodeRow: CVRow = CVRow(title: "home.infoSection.newPostalCode".localized,
                                                    subtitle: "home.infoSection.newPostalCode.subtitle".localized,
                                                    image: Asset.Images.location.image,
                                                    xibName: .isolationTopCell,
                                                    theme:  CVRow.Theme(backgroundColor: Appearance.tintColor,
                                                                        topInset: 0.0,
                                                                        bottomInset: 0.0,
                                                                        textAlignment: .natural,
                                                                        titleColor: Appearance.Button.Primary.titleColor,
                                                                        subtitleColor: Appearance.Button.Primary.titleColor,
                                                                        imageTintColor: Appearance.Button.Primary.titleColor,
                                                                        separatorLeftInset: Appearance.Cell.leftMargin,
                                                                        separatorRightInset: Appearance.Cell.leftMargin,
                                                                        maskedCorners: UIAccessibility.isVoiceOverRunning ? .all : .top),
                                                    selectionAction: { [weak self] in
                                                        self?.didTouchUpdateLocation()
                                                    })
                rows.append(newPostalCodeRow)
                if !UIAccessibility.isVoiceOverRunning {
                    var addActionRow: CVRow = actionRow(title: "home.infoSection.newPostalCode.button".localized,
                                                        isLastAction: true) { [weak self] in
                        self?.didTouchUpdateLocation()
                    }
                    addActionRow.willDisplay = { cell in
                        cell.isAccessibilityElement = false
                        cell.accessibilityElementsHidden = true
                    }
                    rows.append(addActionRow)
                }
            }
        }
        if let info = InfoCenterManager.shared.info.sorted(by: { $0.timestamp > $1.timestamp }).first {
            let lastInfoRow: CVRow = CVRow(title: info.title,
                                           subtitle: info.description,
                                           accessoryText: info.formattedDate,
                                           buttonTitle: "home.infoSection.readAll".localized,
                                           xibName: .lastInfoCell,
                                           theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                              topInset: UIAccessibility.isVoiceOverRunning ? Appearance.Cell.leftMargin : 0.0,
                                                              bottomInset: 0.0,
                                                              textAlignment: .natural),
                                           associatedValue: InfoCenterManager.shared.didReceiveNewInfo,
                                           selectionAction: { [weak self] in
                                            InfoCenterManager.shared.didReceiveNewInfo = false
                                            self?.didTouchInfo()
                                           })
            rows.append(lastInfoRow)
        }

        return rows
    }

    private func keyFiguresWarningRows() -> [CVRow] {
        let warningRow: CVRow = CVRow(subtitle: "keyFiguresController.fetchError.message".localized,
                                      xibName: .cardCell,
                                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                         topInset: 0.0,
                                                         bottomInset: 0.0,
                                                         textAlignment: .center,
                                                         maskedCorners: .top),
                                      selectionAction: {
                                        HUD.show(.progress)
                                        KeyFiguresManager.shared.fetchKeyFigures {
                                            HUD.hide()
                                        }
                                      })
        let retryRow: CVRow = CVRow(title: "keyFiguresController.fetchError.button".localized,
                                    xibName: .standardCardCell,
                                    theme:  CVRow.Theme(backgroundColor: Appearance.Button.Secondary.backgroundColor,
                                                        topInset: 0.0,
                                                        bottomInset: Appearance.Cell.leftMargin,
                                                        textAlignment: .center,
                                                        titleFont: { Appearance.Cell.Text.actionTitleFont },
                                                        titleColor: Appearance.Button.Secondary.titleColor,
                                                        separatorLeftInset: nil,
                                                        separatorRightInset: nil,
                                                        maskedCorners: .bottom),
                                    selectionAction: {
                                        HUD.show(.progress)
                                        KeyFiguresManager.shared.fetchKeyFigures {
                                            HUD.hide()
                                        }
                                    })
        return [warningRow, retryRow]
    }

    private func attestationSectionRows() -> [CVRow] {
        let attestationSectionRow: CVRow = CVRow(title: "home.attestationsSection.title".localized,
                                                 xibName: .textCell,
                                                 theme: CVRow.Theme(topInset: 30.0,
                                                                    bottomInset: 10.0,
                                                                    textAlignment: .natural,
                                                                    titleFont: { Appearance.Cell.Text.headTitleFont }))
        let attestationsCount: Int = AttestationsManager.shared.attestations.filter { !$0.isExpired }.count
        let subtitle: String
        switch attestationsCount {
        case 0:
            subtitle = "home.attestationSection.cell.subtitle.noAttestations".localized
        case 1:
            subtitle = "home.attestationSection.cell.subtitle.oneAttestation".localized
        default:
            subtitle = String(format: "home.attestationSection.cell.subtitle.multipleAttestations".localized, attestationsCount)
        }

        let attestationRow: CVRow = CVRow(title: "home.attestationSection.cell.title".localized,
                                          subtitle: subtitle,
                                          image: Asset.Images.attestationCard.image,
                                          xibName: .attestationCell,
                                          theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                             topInset: 0.0,
                                                             bottomInset: 0.0,
                                                             textAlignment: .natural),
                                          selectionAction: { [weak self] in
                                            self?.didTouchDocument()
                                          })
        return [attestationSectionRow, attestationRow]
    }

    private func walletSectionRows() -> [CVRow] {
        guard WalletManager.shared.isWalletActivated else { return [] }
        var rows: [CVRow] = []
        let attestationSectionRow: CVRow = CVRow(title: "home.walletSection.title".localized,
                                                 xibName: .textCell,
                                                 theme: CVRow.Theme(topInset: 30.0,
                                                                    bottomInset: 10.0,
                                                                    textAlignment: .natural,
                                                                    titleFont: { Appearance.Cell.Text.headTitleFont }))
        rows.append(attestationSectionRow)
        if let certificate = WalletManager.shared.favoriteCertificate {
            let favoriteCertificateRow: CVRow = CVRow(title: "home.walletSection.favoriteCertificate.cell.title".localized,
                                                      subtitle: "home.walletSection.favoriteCertificate.cell.subtitle".localized,
                                                      image: certificate.value.qrCode(small: true),
                                                      xibName: .favoriteCertificateCell,
                                                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                                         topInset: 0.0,
                                                                         bottomInset: Appearance.Cell.leftMargin,
                                                                         textAlignment: .natural),
                                                      selectionAction: { [weak self] in
                                                        self?.didTouchCertificate(certificate)
                                                      })
            rows.append(favoriteCertificateRow)
        }
        let sanitaryCertificatesRow: CVRow = CVRow(title: "home.attestationSection.sanitaryCertificates.cell.title".localized,
                                                   subtitle: "home.attestationSection.sanitaryCertificates.cell.subtitle".localized,
                                                   image: Asset.Images.walletCard.image,
                                                   xibName: .sanitaryCertificatesWalletCell,
                                                   theme: CVRow.Theme(backgroundColor: Appearance.tintColor,
                                                                      topInset: 0.0,
                                                                      bottomInset: 0.0,
                                                                      textAlignment: .natural,
                                                                      titleColor: Appearance.Button.Primary.titleColor,
                                                                      subtitleColor: Appearance.Button.Primary.titleColor),
                                                   selectionAction: { [weak self] in
                                                    self?.didTouchSanitaryCertificates(nil)
                                                   })
        rows.append(sanitaryCertificatesRow)
        return rows
    }

    private func didTouchUpdateLocation() {
        KeyFiguresManager.shared.updateLocation(from: self)
    }

    @objc private func accessibilityDidActivateChangeLocation() {
        KeyFiguresManager.shared.defineNewPostalCode(from: self)
    }

    @objc private func accessibilityDidActivateDeleteLocation() {
        KeyFiguresManager.shared.deletePostalCode()
    }

    private func moreSectionRows() -> [CVRow] {
        var rows: [CVRow] = []
        let moreSectionRow: CVRow = CVRow(title: "home.moreSection.title".localized,
                                          xibName: .textCell,
                                          theme: CVRow.Theme(topInset: 30.0,
                                                             bottomInset: 10.0,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Cell.Text.headTitleFont }),
                                          willDisplay: { cell in
                                            cell.accessibilityLabel = "accessibility.home.otherOptions".localized
                                          })
        rows.append(moreSectionRow)

        var menuEntries: [GroupedMenuEntry] = [GroupedMenuEntry(image: Asset.Images.usefulLinks.image,
                                                                title: "home.moreSection.usefulLinks".localized,
                                                                actionBlock: { [weak self] in
                                                                    self?.didTouchUsefulLinks()
                                                                }),
                                               GroupedMenuEntry(image: Asset.Images.bubble.image,
                                                                title: "home.moreSection.appSharing".localized,
                                                                actionBlock: { [weak self] in
                                                                    self?.didTouchShare()
                                                                })]

        if VenuesManager.shared.isVenuesRecordingActivated || !VenuesManager.shared.venuesQrCodes.isEmpty {
            menuEntries.append(GroupedMenuEntry(image: Asset.Images.history.image,
                                                title: "home.moreSection.venuesHistory".localized,
                                                actionBlock: { [weak self] in
                                                    self?.didTouchVenuesHistory()
                                                }))
        }

        menuEntries.append(GroupedMenuEntry(image: Asset.Images.manageData.image,
                                            title: "home.moreSection.manageData".localized,
                                            actionBlock: { [weak self] in
                                                self?.didTouchManageData()
                                            }))

        if ParametersManager.shared.displaySanitaryCertificatesValidation {
            menuEntries.append(GroupedMenuEntry(image: Asset.Images.dataMatrix.image,
                                                title: "home.moreSection.verifySanitaryCertificate".localized,
                                                actionBlock: { [weak self] in
                                                    self?.didTouchVerifyWalletCertificate()
                                                }))
        }

        menuEntries.append(contentsOf: [GroupedMenuEntry(image: Asset.Images.privacy.image,
                                                         title: "home.moreSection.privacy".localized,
                                                         actionBlock: { [weak self] in
                                                            self?.didTouchPrivacy()
                                                         }),
                                        GroupedMenuEntry(image: Asset.Images.about.image,
                                                         title: "home.moreSection.aboutStopCovid".localized,
                                                         actionBlock: { [weak self] in
                                                            self?.didTouchAbout()
                                                         })])
        rows.append(contentsOf: menuRowsForEntries(menuEntries))
        return rows
    }

    private func menuRowsForEntries(_ entries: [GroupedMenuEntry]) -> [CVRow] {
        let rows: [CVRow] = entries.map {
            var row: CVRow = standardCardRow(title: $0.title, image: $0.image, actionBlock: $0.actionBlock)
            row.theme.imageSize = CGSize(width: 24.0, height: 24.0)
            if $0 == entries.first {
                row.theme.maskedCorners = .top
                row.theme.separatorLeftInset = 2 * Appearance.Cell.leftMargin
                row.theme.separatorRightInset = Appearance.Cell.leftMargin
            } else if $0 == entries.last {
                row.theme.maskedCorners = .bottom
            } else {
                row.theme.maskedCorners = .none
                row.theme.separatorLeftInset = 2 * Appearance.Cell.leftMargin
                row.theme.separatorRightInset = Appearance.Cell.leftMargin
            }
            return row
        }
        return rows
    }

    private func standardCardRow(title: String, subtitle: String? = nil, image: UIImage, actionBlock: @escaping () -> ()) -> CVRow {
        let row: CVRow = CVRow(title: title,
                               subtitle: subtitle,
                               image: image,
                               xibName: .standardCardCell,
                               theme:  CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                   topInset: 0.0,
                                                   bottomInset: 0.0,
                                                   textAlignment: .natural,
                                                   titleFont: { Appearance.Cell.Text.standardFont },
                                                   titleColor: Appearance.Cell.Text.headerTitleColor,
                                                   imageTintColor: Appearance.Cell.Text.headerTitleColor),
                               selectionAction: {
                                actionBlock()
                               })
        return row
    }

    @objc private func voiceOverStatusDidChange() {
        reloadUI()
    }

}

extension HomeViewController {

    private func didTouchShare() {
        let controller: UIActivityViewController = UIActivityViewController(activityItems: ["sharingController.appSharingMessage".localized], applicationActivities: nil)
        present(controller, animated: true, completion: nil)
        AnalyticsManager.shared.reportAppEvent(.e4)
    }

}

extension HomeViewController: LocalizationsChangesObserver {

    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }

}

extension HomeViewController: BluetoothStateObserver {

    func bluetoothStateDidUpdate() {
        if !BluetoothStateManager.shared.isUnknown && areNotificationsAuthorized != nil {
            isWaitingForNeededInfo = false
        }
        updateUIForAuthorizationChange()
    }

}

extension HomeViewController: InfoCenterChangesObserver {

    func infoCenterDidUpdate() {
        reloadUI()
    }

}

extension HomeViewController: KeyFiguresChangesObserver {

    func keyFiguresDidUpdate() {
        reloadUI(animated: true)
    }

    func postalCodeDidUpdate(_ postalCode: String?) {}

}

extension HomeViewController: AttestationsChangesObserver {

    func attestationsDidUpdate() {
        reloadUI(animated: true)
    }

}

extension HomeViewController: IsolationChangesObserver {

    func isolationDidUpdate() {
        reloadUI(animated: true)
    }

}

extension HomeViewController: RisksUIChangesObserver {
    func risksUIChanged() {
        reloadUI(animated: true)
    }
}


extension HomeViewController: WalletChangesObserver {
    func walletCertificatesDidUpdate() {}
    func walletActivityCertificateDidUpdate() {}

    func walletFavoriteCertificateDidUpdate() {
        reloadUI(animated: true)
    }

}

extension HomeViewController {
    // In order to help user who has added venues to the app but is not registered to reregister to Robert to add more venues
    @objc private func displayRobertUnregisteredAlertIfNecessary() {
        if !RBManager.shared.isRegistered && !VenuesManager.shared.venuesQrCodes.isEmpty && !didShowRobertErrorAlertOnce {
            didShowRobertErrorAlertOnce = true
            showAlert(
                title: "robertStatus.error.alert.title".localized,
                message: "robertStatus.error.alert.message".localized,
                okTitle: "robertStatus.error.alert.later".localized,
                cancelTitle: "robertStatus.error.alert.action".localized,
                cancelHandler: { [weak self] in
                    self?.requestRegister()
                })
        }
    }
}
