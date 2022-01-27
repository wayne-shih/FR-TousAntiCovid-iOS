// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  HomeCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 07/10/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import RobertSDK
import StoreKit
import LBBottomSheet

final class HomeCoordinator: NSObject, WindowedCoordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator]
    var window: UIWindow!
    
    private weak var navigationController: UINavigationController?
    private var launchScreenWindow: UIWindow?
    private var showLaunchScreen: Bool = true
    private var isLoadingAppUpdate: Bool = false

    private var animationWindow: UIWindow?

    init(parent: Coordinator) {
        self.parent = parent
        self.childCoordinators = []
        super.init()
        start()
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    private func start() {
        let navigationChildController: UIViewController = CVNavigationChildController.controller(HomeViewController(didTouchAbout: { [weak self] in
            self?.showAbout()
        }, showCaptchaChallenge: { [weak self] captcha, didEnterCaptcha, didCancelCaptcha in
            self?.showCaptchaChallenge(captcha: captcha, didEnterCaptcha: didEnterCaptcha, didCancelCaptcha: didCancelCaptcha)
        }, didTouchAppUpdate: { [weak self] in
            self?.updateApp()
        }, didTouchDocument: { [weak self] in
            self?.showAttestations()
        }, didTouchManageData: { [weak self] in
            self?.showManageData()
        }, didTouchPrivacy: { [weak self] in
            self?.showPrivacy()
        }, didFinishLoad: { [weak self] in
            self?.didFinishLoadingController()
        }, didTouchHealth: { [weak self] in
            self?.showMyHealth()
        }, didTouchInfo: { [weak self] info in
            self?.showInfo(info)
        }, didTouchKeyFigure: { [weak self] keyFigure in
            self?.showKeyFigureDetailFor(keyFigure: keyFigure)
        }, didTouchKeyFigures: { [weak self] in
            self?.showKeyFigures()
        }, didTouchComparisonChart: { [weak self] in
            self?.showKeyFiguresComparison()
        }, didTouchComparisonChartSharing: { [weak self] image in
            self?.showSharingScreen(for: image)
        }, didTouchDeclare: { [weak self] in
            self?.showDeclare()
        }, didTouchUsefulLinks: { [weak self] in
            self?.showUsefulLinks()
        }, didTouchRecordVenues: { [weak self] in
            self?.showRecordVenues()
        }, didTouchVenuesHistory: { [weak self] in
            self?.showVenuesHistory()
        }, didRecordVenue: { [weak self] url in
            self?.showVenueRecordingConfirmation(url: url)
        }, didRequestVenueScanAuthorization: { [weak self] completion in
            self?.requestVenueScanAuthorization(completion)
        }, didTouchOpenIsolationForm: { [weak self] in
            self?.showIsolationForm()
        }, didTouchVaccination: { [weak self] in
            self?.showVaccination()
        }, didTouchSanitaryCertificates: { [weak self] url in
            self?.showSanitaryCertificates(url)
        }, didTouchUniversalQrScan: { [weak self] in
            self?.showUniversalQrScan()
        }, didTouchCertificate: { [weak self] certificate in
            self?.showCodeFullscreen(certificate)
        }, showUniversalQrScanExplanation: { [weak self] rect, animationDidEnd in
            self?.showUniversalQrCodeScanningExplanations(initialButtonFrame: rect, animationDidEnd: animationDidEnd)
        }, didEnterCodeFromDeeplink: { [weak self] code in
            self?.didEnterCodeFromDeeplink(code)
        }, showUserLanguage: { [weak self] in
            self?.showUserLanguage()
        }, didTouchUrgentDgs: { [weak self] in
            self?.showUrgentDgs()
        },
        deinitBlock: { [weak self] in
            self?.didDeinit()
        }))
        
        let controller: UIViewController = BottomMessageContainerViewController.controller(navigationChildController)
        let navigationController: UINavigationController = CVNavigationController(rootViewController: controller)
        self.navigationController = navigationController
        createWindow(for: navigationController)
        window?.accessibilityViewIsModal = false
        if showLaunchScreen {
            loadLaunchScreen()
        }
    }
    
    private func didFinishLoadingController() {
        if showLaunchScreen {
            hideLaunchScreen()
        }
    }
    
    private func updateApp() {
        guard !isLoadingAppUpdate else { return }
        isLoadingAppUpdate = true
        #if targetEnvironment(simulator)
        URL(string: "https://apps.apple.com/in/app/TousAntiCovid/id\(Constant.appStoreId)")?.openInSafari()
        isLoadingAppUpdate = false
        #else
        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = self
        let parameters: [String: String] = [SKStoreProductParameterITunesItemIdentifier: Constant.appStoreId]
        HUD.show(.progress)
        storeViewController.loadProduct(withParameters: parameters) { [weak self] loaded, error in
            HUD.hide()
            self?.isLoadingAppUpdate = false
            guard loaded && error == nil else {
                URL(string: "itms-apps://apple.com/app/id\(Constant.appStoreId)")?.openInSafari()
                return
            }
            self?.navigationController?.present(storeViewController, animated: true)
        }
        #endif
    }
    
    private func showUserLanguage() {
        let userLanguageCoordinator: UserLanguageCoordinator = UserLanguageCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: userLanguageCoordinator)
    }
    
    private func showAbout() {
        let aboutCoordinator: AboutCoordinator = AboutCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: aboutCoordinator)
    }
    
    private func showUsefulLinks() {
        let linksCoordinator: LinksCoordinator = LinksCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: linksCoordinator)
    }
    
    private func showPrivacy() {
        let privacyCoordinator: PrivacyCoordinator = PrivacyCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: privacyCoordinator)
    }

    private func showAttestations() {
        let attestationsCoordinator: AttestationsCoordinator = AttestationsCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: attestationsCoordinator)
        AnalyticsManager.shared.reportAppEvent(.e11)
    }
    
    private func showSanitaryCertificates(_ url: URL?) {
        if let coordinator = DeepLinkingManager.shared.walletCoordinator {
            coordinator.processUrl(url: url)
        } else {
            dismissAllModalsIfNeeded { [weak self] in
                guard let self = self else { return }
                let sanitaryCertificatesCoordinator: WalletCoordinator = WalletCoordinator(presentingController: self.navigationController?.topPresentedController,
                                                                                           url: url,
                                                                                           parent: self)
                self.addChild(coordinator: sanitaryCertificatesCoordinator)
            }
        }
    }

    private func dismissAllModalsIfNeeded(_ completion: @escaping () -> ()) {
        guard navigationController?.presentedViewController != nil else {
            completion()
            return
        }
        navigationController?.dismiss(animated: true) { completion() }
    }

    private func showVenueRecordingConfirmation(url: URL) {
        let venuesRecordingCoordinator: VenuesRecordingCoordinator = VenuesRecordingCoordinator(presentingController: navigationController?.topPresentedController, parent: self, showOnlyConfirmation: true, openingUrl: url)
        addChild(coordinator: venuesRecordingCoordinator)
    }
    
    private func requestVenueScanAuthorization(_ completion: @escaping (_ granted: Bool) -> ()) {
        let venueScanAuthorizationController: VenuesScanAuthorizationController = VenuesScanAuthorizationController { [weak self] granted in
            if granted {
                self?.navigationController?.topPresentedController.dismiss(animated: true) {
                    completion(true)
                }
            } else {
                self?.navigationController?.topPresentedController.dismiss(animated: true)
                completion(false)
            }
        }
        let navigationController: UIViewController = CVNavigationController(rootViewController: venueScanAuthorizationController)
        self.navigationController?.topPresentedController.present(navigationController, animated: true)
    }
    
    private func showManageData() {
        let manageDataController: UIViewController = ManageDataController()
        let navigationController: UIViewController = CVNavigationController(rootViewController: manageDataController)
        self.navigationController?.present(navigationController, animated: true)
    }
    
    private func showMyHealth() {
        let sickCoordinator: MyHealthCoordinator = MyHealthCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: sickCoordinator)
        AnalyticsManager.shared.reportAppEvent(.e5)
    }
    
    private func showInfo(_ info: Info?) {
        if let info = info {
            let controller: HomeInfoBottomSheetController = .init(content: info) { [weak self] in
                self?.showAllInfo()
            }
            navigationController?.presentAsBottomSheet(controller, theme: controller.bottomSheetTheme, behavior: controller.bottomSheetBehavior)
        } else {
            showAllInfo()
        }
    }
    
    func showAllInfo() {
        let infoCenterCoordinator: InfoCenterCoordinator = InfoCenterCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: infoCenterCoordinator)
        AnalyticsManager.shared.reportAppEvent(.e10)
    }
    
    private func showDeclare() {
        let declareCoordinator: DeclareCoordinator = DeclareCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: declareCoordinator)
    }
    
    private func showRecordVenues() {
        let venuesRecordingCoordinator: VenuesRecordingCoordinator = VenuesRecordingCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: venuesRecordingCoordinator)
        AnalyticsManager.shared.reportAppEvent(.e12)
    }
    
    private func showVenuesHistory() {
        let venuesHistoryController: UIViewController = VenuesHistoryViewController()
        let navigationController: UIViewController = CVNavigationController(rootViewController: venuesHistoryController)
        self.navigationController?.present(navigationController, animated: true)
    }
    
    private func showIsolationForm() {
        let isolationFormCoordinator: IsolationFormCoordinator = IsolationFormCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: isolationFormCoordinator)
        AnalyticsManager.shared.reportAppEvent(.e6)
    }
    
    private func showCaptchaChallenge(captcha: Captcha, didEnterCaptcha: @escaping (_ id: String, _ answer: String) -> (), didCancelCaptcha: @escaping () -> ()) {
        dismissAllModalsIfNeeded { [weak self] in
            guard let self = self else { return }
            let captchaCoordinator: CaptchaCoordinator = CaptchaCoordinator(presentingController: self.navigationController?.topPresentedController, parent: self, captcha: captcha, didEnterCaptcha: { [weak self] id, answer in
                self?.navigationController?.topPresentedController.dismiss(animated: true) {
                    didEnterCaptcha(id, answer)
                }
            }, didCancelCaptcha: { [weak self] in
                self?.navigationController?.topPresentedController.dismiss(animated: true)
                didCancelCaptcha()
            })
            self.addChild(coordinator: captchaCoordinator)
        }
    }

    private func showEnterCode(code: String?) {
        let enterCodeCoordinator: EnterCodeCoordinator = EnterCodeCoordinator(presentingController: navigationController?.topPresentedController, parent: self, initialCode: code)
        addChild(coordinator: enterCodeCoordinator)
    }
    
    private func showKeyFigures() {
        let keyFiguresCoordinator: KeyFiguresCoordinator = KeyFiguresCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: keyFiguresCoordinator)
        AnalyticsManager.shared.reportAppEvent(.e8)
    }
    
    private func showKeyFiguresComparison() {
        let comparisonCoordinator: KeyFiguresComparisonCoordinator = .init(presentingController: navigationController, parent: self)
        addChild(coordinator: comparisonCoordinator)
    }
    
    private func showKeyFigureDetailFor(keyFigure: KeyFigure) {
        let detailCoordinator: KeyFigureDetailCoordinator = KeyFigureDetailCoordinator(presentingController: navigationController, parent: self, keyFigure: keyFigure)
        addChild(coordinator: detailCoordinator)
    }
    
    private func showVaccination() {
        let vaccinationCoordinator: VaccinationCoordinator = VaccinationCoordinator(presentingController: navigationController?.topViewController, parent: self)
        addChild(coordinator: vaccinationCoordinator)
        AnalyticsManager.shared.reportAppEvent(.e7)
    }

    private func showUniversalQrCodeScanningExplanations(initialButtonFrame: CGRect?, animationDidEnd: @escaping (_ animated: Bool) -> ()) {
        let explanationsAnimationController: UniversalQrCodeExplanationsAnimationController = UniversalQrCodeExplanationsAnimationController.controller(initialButtonFrame: initialButtonFrame)
        animationWindow = createAnimationWindow(for: explanationsAnimationController)

        let explanationsController: UniversalQrCodeExplanationsController = UniversalQrCodeExplanationsController(didTouchClose: { [weak self] imageView in
            let canAnimate: Bool = explanationsAnimationController.positionImageViewToMatchView(imageView)
            if canAnimate {
                imageView?.alpha = 0.0
                self?.animationWindow?.alpha = 1.0
                self?.navigationController?.dismiss(animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    explanationsAnimationController.animateDisappearing { [weak self] in
                        animationDidEnd(false)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self?.animationWindow?.resignKey()
                            self?.animationWindow?.isHidden = true
                            self?.animationWindow = nil
                        }
                    }
                }
            } else {
                self?.navigationController?.dismiss(animated: true) {
                    animationDidEnd(true)
                    self?.animationWindow = nil
                }
            }
        }, didDismissManually: { [weak self] in
            animationDidEnd(true)
            self?.animationWindow = nil
        })
        navigationController?.present(CVNavigationController(rootViewController: explanationsController), animated: true)
    }

    private func createAnimationWindow(for controller: UIViewController) -> UIWindow {
        let animationWindow = UIWindow(frame: UIScreen.main.bounds)
        animationWindow.backgroundColor = .clear
        animationWindow.rootViewController = controller
        animationWindow.alpha = 0.0
        animationWindow.makeKeyAndVisible()
        return animationWindow
    }

    private func showUniversalQrScan() {
        guard childCoordinators.first(where: { $0 is UniversalQrScanCoordinator }).isNil else { return }
        let coordinator: UniversalQrScanCoordinator = UniversalQrScanCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: coordinator)
    }

    private func showCodeFullscreen(_ certificate: WalletCertificate) {
        if let coordinator = childCoordinators.first(where: { $0 is FullscreenCertificateCoordinator }) as? FullscreenCertificateCoordinator {
            coordinator.updateCertificate(certificate)
        } else if let walletCoordinator = childCoordinators.first(where: { $0 is WalletCoordinator }) as? WalletCoordinator,
                  let coordinator = walletCoordinator.childCoordinators.first(where: { $0 is FullscreenCertificateCoordinator }) as? FullscreenCertificateCoordinator {
            coordinator.updateCertificate(certificate)
        } else  {
            let coordinator: FullscreenCertificateCoordinator = FullscreenCertificateCoordinator(presentingController: navigationController?.topPresentedController, parent: self, certificate: certificate)
            addChild(coordinator: coordinator)
        }
    }
    
    private func showUrgentDgs() {
        let urgentDgsCoordinator: UrgentDgsCoordinator = UrgentDgsCoordinator(presentingController: navigationController?.topViewController, parent: self)
        addChild(coordinator: urgentDgsCoordinator)
    }
    
    private func loadLaunchScreen() {
        guard let launchScreen = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController() else { return }
        let window: UIWindow = UIWindow(frame: UIScreen.main.bounds)
        launchScreenWindow = window
        window.windowLevel = .statusBar
        window.rootViewController = launchScreen
        window.isHidden = false
    }
    
    private func hideLaunchScreen() {
        UIView.animate(withDuration: 0.3, animations: {
            self.launchScreenWindow?.alpha = 0.0
        }) { _ in
            self.launchScreenWindow?.resignKey()
            self.launchScreenWindow = nil
        }
    }
    
}

extension HomeCoordinator {
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(dismissAllAndShowRecommandations), name: .dismissAllAndShowRecommandations, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shouldShowStorageAlert(_:)), name: .shouldShowStorageAlert, object: nil)
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    private func didEnterCodeFromDeeplink(_ code: String) {
        dismissAllModalsIfNeeded {
            if let controller = DeepLinkingManager.shared.enterCodeController {
                controller.enterCode(code)
            } else {
                self.showEnterCode(code: code)
            }
        }
    }
    
    @objc private func dismissAllAndShowRecommandations() {
        navigationController?.dismiss(animated: true) {
            self.showMyHealth()
        }
    }
    
    @objc private func shouldShowStorageAlert(_ notification: Notification) {
        guard let alertType = notification.object as? StorageAlertManager.StorageAlertType else { return }
        let bottomSheetAlert: BottomSheetAlertController = .init(
            title: nil,
            message: alertType.localizedDescription,
            image: Asset.Images.tacHorizontalAlert.image,
            imageTintColor: Appearance.tintColor,
            okTitle: alertType.localizedConfirmationButtonTitle)
        bottomSheetAlert.show()
    }
}

extension HomeCoordinator: SKStoreProductViewControllerDelegate {
    
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        navigationController?.dismiss(animated: true)
    }
    
}

// MARK: - sharing related functions
private extension HomeCoordinator {
    func showSharingScreen(for chartImage: UIImage?) {
        let activityItems: [Any?] = [chartImage]
        let controller: UIActivityViewController = UIActivityViewController(activityItems: activityItems.compactMap { $0 }, applicationActivities: nil)
        controller.excludedActivityTypes = [.saveToCameraRoll, .print]
        navigationController?.present(controller, animated: true, completion: nil)
    }
}
