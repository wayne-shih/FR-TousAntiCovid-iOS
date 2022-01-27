// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 17/03/2021 - for the TousAntiCovid project.
//

import UIKit
import LBBottomSheet
import PKHUD
import RobertSDK
import ServerSDK

final class WalletCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?
    private weak var flashCodeController: FlashWalletCodeController?
    private weak var walletViewController: WalletViewController?
    private weak var bottomSheetController: BottomSheetController?

    private var initialUrlToProcess: URL?

    private var isFlashingCode: Bool = false
    private var wasVoiceOverActivated: Bool = UIAccessibility.isVoiceOverRunning
    
    init(presentingController: UIViewController?, url: URL?, parent: Coordinator) {
        self.presentingController = presentingController
        self.initialUrlToProcess = url
        self.parent = parent
        addObserver()
        start()
    }

    deinit {
        removeObserver()
    }

    func processUrl(url: URL?) {
        guard let url = url else { return }
        do {
            try processScannedQrCodeUrl(url, fromFlashWalletCodeController: false)
        } catch {
            let certificateType: WalletConstant.CertificateType = WalletManager.certificateTypeFromHeaderInUrl(url) ?? .vaccinationEurope
            showCertificateError(certificateType: certificateType, error: error)
        }
    }

    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(voiceOverStatusDidChange), name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
    }

    private func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }

    private func start() {
        DeepLinkingManager.shared.walletCoordinator = self
        let walletController: WalletViewController = createWalletController()
        walletViewController = walletController
        let innerController: UIViewController = UIAccessibility.isVoiceOverRunning ? walletController : BottomButtonContainerController.controller(walletController)
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: innerController)
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true) { [weak self] in
            self?.processUrl(url: self?.initialUrlToProcess)
            self?.initialUrlToProcess = nil
        }
    }
    
    private func createWalletController() -> WalletViewController {
        WalletViewController { [weak self] in
            self?.startFlashCode()
        } didTouchCertificate: { [weak self] certificate in
            self?.showCodeFullscreen(certificate)
        } didConvertToEuropeanCertifcate: { [weak self] certificate in
            self?.showCompletedVaccinationControllerIfNeeded(certificate: certificate)
        } didTouchDocumentExplanation: { [weak self] certificateType in
            self?.showDocumentExplanation(certificateType: certificateType)
        } didTouchWhenToUse: { [weak self] in
            self?.showWhenToUseExplanations()
        } didTouchMultiPassMoreInfo: { [weak self] in
            self?.showMultiPassMoreInfo()
        } didTouchMultiPassInstructions: { [weak self] in
            self?.showMultiPassInstructions()
        } didTouchContinueOnFraud: { [weak self] in
            self?.openFraudHelp()
        } didTouchConvertToEuropeTermsOfUse: { [weak self] in
            self?.openConvertToEuropeTermsOfUse()
        } didTouchCertificateAdditionalInfo: { [weak self] info in
            self?.showDetailsBottomSheet(with: info)
        } didSelectProfileForMultiPass: { [weak self] certificates in
            self?.showMultiPassCertificateSelection(with: certificates)
        } deinitBlock: { [weak self] in
            self?.didDeinit()
        }
    }

    private func updateCurrentController() {
        walletViewController?.deinitBlock = nil
        let walletController: WalletViewController = createWalletController()
        walletViewController = walletController
        let innerController: UIViewController = UIAccessibility.isVoiceOverRunning ? walletController : BottomButtonContainerController.controller(walletController)
        navigationController?.setViewControllers([innerController], animated: false)
    }

    @objc private func voiceOverStatusDidChange() {
        guard wasVoiceOverActivated != UIAccessibility.isVoiceOverRunning else { return }
        wasVoiceOverActivated = UIAccessibility.isVoiceOverRunning
        updateCurrentController()
    }
    
    private func openConvertToEuropeTermsOfUse() {
        URL(string: "walletController.menu.convertToEurope.alert.termsUrl".localized)?.openInSafari()
    }
    
    private func openFraudHelp() {
        URL(string: "walletController.info.fraud.url".localized)?.openInSafari()
    }

    private func showCodeFullscreen(_ certificate: WalletCertificate) {
        if let coordinator = childCoordinators.first(where: { $0 is FullscreenCertificateCoordinator }) as? FullscreenCertificateCoordinator {
            coordinator.updateCertificate(certificate)
        } else  {
            let coordinator: FullscreenCertificateCoordinator = .init(presentingController: navigationController?.topPresentedController,
                                                                      parent: self,
                                                                      certificate: certificate)
            addChild(coordinator: coordinator)
        }
    }

    private func requestWalletScanAuthorization(comingFromTheApp: Bool, url: URL, completion: @escaping (_ granted: Bool) -> ()) {
        let walletScanAuthorizationController: WalletScanAuthorizationController = WalletScanAuthorizationController(comingFromTheApp: comingFromTheApp, didAnswer: completion)
        let navigationController: UIViewController = CVNavigationController(rootViewController: walletScanAuthorizationController)
        self.navigationController?.topPresentedController.present(navigationController, animated: true)
    }

    private func showDocumentExplanation(certificateType: WalletConstant.CertificateType) {
        let controller: DocumentExplanationViewController = DocumentExplanationViewController(certificateType: certificateType)
        self.navigationController?.pushViewController(controller, animated: true)
    }

    private func showWhenToUseExplanations() {
        URL(string: "walletController.whenToUse.url".localized)?.openInSafari()
    }
    
    private func showMultiPassMoreInfo() {
        URL(string: "multiPass.tab.explanation.url".localized)?.openInSafari()
    }
    
    private func showMultiPassInstructions() {
        URL(string: "multiPass.tab.similarProfile.url".localized)?.openInSafari()
    }

    private func showCertificateError(certificateType: WalletConstant.CertificateType, error: Error) {
        let coordinator: WalletCertificateErrorCoordinator = WalletCertificateErrorCoordinator(presentingController: presentingController?.topPresentedController, parent: self, certificateType: certificateType, error: error)
        addChild(coordinator: coordinator)
    }
    
    private func showDetailsBottomSheet(with content: AdditionalInfo) {
        let controller: WalletInfoBottomSheetController = .init(content: content)
        var theme: BottomSheetController.Theme = controller.bottomSheetTheme
        switch content.category {
        case .warning:
            theme.grabber?.color = .black.withAlphaComponent(0.25)
        case .info:
            theme.grabber?.color = .white.withAlphaComponent(0.35)
        default:
            break
        }
        navigationController?.presentAsBottomSheet(controller, theme: theme)
    }
    
    private func showMultiPassCertificateSelection(with certificates: [EuropeanCertificate]) {
        let selectionController: MultiPassCertificateSelectionViewController = .init(availableCertificates: certificates) { [weak self] certificates in
            self?.navigationController?.topPresentedController.showLinkAlert(title: "multiPass.CGU.alert.title".localized, message: "multiPass.CGU.alert.subtitle".localized, okTitle: "common.ok".localized, okHandler: {
                self?.generateMultiPass(for: certificates)
            }, linkTitle: "multiPass.CGU.alert.linkButton.title".localized, linkHandler: { [weak self] in
                self?.showMultiPassCGU()
            }, cancelTitle: "common.cancel".localized, cancelHandler: { [weak self] in
                self?.navigationController?.dismiss(animated: true, completion: nil)
            })
        } didTouchClose: { [weak self] in
            self?.navigationController?.dismiss(animated: true, completion: nil)
        } deinitBlock: { }
        let bottomButtonContainer: UIViewController = BottomButtonContainerController.controller(selectionController)
        navigationController?.present(CVNavigationController(rootViewController: bottomButtonContainer), animated: true, completion: nil)
    }
    
    private func showMultiPassCGU() {
        URL(string: "multiPass.CGU.alert.url".localized)?.openInSafari()
    }
    
    private func generateMultiPass(for certificates: [EuropeanCertificate]) {
        HUD.show(.progress)
        WalletManager.shared.generateMultiPassDccFrom(certificates: certificates) { [weak self] result in
            DispatchQueue.main.async {
                HUD.hide()
                switch result {
                case .success(let generatedCertificate):
                    self?.showGenerationSuccessAlert(generatedCertificate: generatedCertificate)
                case .failure(let error):
                    self?.showGenerationError(for: (error as NSError).userInfo["codes"] as? [String])
                }
            }
        }
    }
    
    private func showGenerationError(for errorsCodes: [String]?) {
        let controller: MultiPassGenerationErrorViewController = .init(errorsCodes: errorsCodes) { [weak self] in
            self?.navigationController?.topPresentedController.dismiss(animated: true, completion: nil)
        } deinitBlock: {}
        navigationController?.topPresentedController.present(CVNavigationController(rootViewController: controller), animated: true, completion: nil)
    }
    
    private func showGenerationSuccessAlert(generatedCertificate: WalletCertificate) {
        navigationController?.showAlert(title: "multiPass.generation.successAlert.title".localized,
                                        message: "multiPass.generation.successAlert.subtitle".localized,
                                        okTitle: "multiPass.generation.successAlert.buttonTitle".localized,
                                        handler: { [weak self] in
            self?.walletViewController?.scrollTo(generatedCertificate, animated: false)
            self?.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
    private func startFlashCode() {
        guard !isFlashingCode else { return }
        isFlashingCode = true
        let controller: FlashWalletCodeController = FlashWalletCodeController.controller(didFlash: { [weak self] url in
            try self?.processScannedQrCodeUrl(url, fromFlashWalletCodeController: true)
        }, didGetCertificateError: { [weak self] code, error in
            self?.showCertificateError(code: code, error: error)
        }, deinitBlock: { [weak self] in
            self?.isFlashingCode = false
        })
        flashCodeController = controller
        presentingController?.topPresentedController.present(CVNavigationController(rootViewController: controller), animated: true)
    }

    private func showforeignCertificateAlert(handler: @escaping () -> (), cancelHandler: @escaping () -> ()) {
        navigationController?.topPresentedController.showAlert(title: "common.warning".localized,
                  message: "walletController.addForeignCertificate.alert.message".localized,
                  okTitle: "walletController.addForeignCertificate.alert.add".localized,
                  cancelTitle: "common.cancel".localized,
                  handler: handler,
                  cancelHandler: cancelHandler)
    }

    private func showWarningAlertIfNeeded(certificate: WalletCertificate, handler: @escaping () -> (), cancelHandler: @escaping () -> ()) {
        var warningMessages: [String] = []
        var okTitle: String = "common.ok".localized
        if DccBlacklistManager.shared.isBlacklisted(certificate: certificate) || Blacklist2dDocManager.shared.isBlacklisted(certificate: certificate) {
            warningMessages.append("wallet.blacklist.warning".localized)
        }
        if WalletManager.shared.isDuplicatedCertificate(certificate) {
            warningMessages.append("walletController.alert.duplicatedCertificate.subtitle".localized)
            okTitle = "walletController.alert.duplicatedCertificate.confirm".localized
        }
        if !warningMessages.isEmpty  {
            navigationController?.topPresentedController.showAlert(title: "common.warning".localized,
                                                                   message: warningMessages.joined(separator: "\n\n"),
                                                                   okTitle: okTitle,
                                                                   cancelTitle: "common.cancel".localized,
                                                                   handler: handler,
                                                                   cancelHandler: cancelHandler)
        } else {
            handler()
        }
    }

    private func processScannedQrCodeUrl(_ url: URL?, fromFlashWalletCodeController: Bool) throws {
        guard let url = url else {
            throw WalletError.parsing.error
        }
        if DeepLinkingManager.shared.isComboDeeplink(url), RBManager.shared.isRegistered {
            if fromFlashWalletCodeController {
                flashCodeController?.dismiss(animated: true) { [weak self] in
                    self?.showComboDeclareWalletCertificate(url: url)
                }
            } else {
                showComboDeclareWalletCertificate(url: url)
            }
        } else {
            let certificate: WalletCertificate = try WalletManager.shared.getWalletCertificate(from: url)
            if fromFlashWalletCodeController {
                postProcessScannedQrCodeUrl(certificate: certificate)
            } else {
                requestWalletScanAuthorization(comingFromTheApp: DeepLinkingManager.shared.lastDeeplinkScannedDirectlyFromApp, url: url) { [weak self] granted in
                    guard granted else {
                        self?.navigationController?.dismiss(animated: true)
                        return
                    }
                    self?.postProcessScannedQrCodeUrl(certificate: certificate)
                }
            }
        }
    }

    private func postProcessScannedQrCodeUrl(certificate: WalletCertificate) {
        requestToSaveCertificate(certificate) { [weak self] granted in
            if granted {
                self?.saveAndScrollToCertificate(certificate: certificate)
                self?.navigationController?.dismiss(animated: true) { [weak self] in
                    if let europeanCertificate = certificate as? EuropeanCertificate {
                        self?.showCompletedVaccinationControllerIfNeeded(certificate: europeanCertificate)
                    }
                }
            } else {
                self?.navigationController?.dismiss(animated: true)
            }
        }
    }

    private func requestToSaveCertificate(_ certificate: WalletCertificate, _ completion: @escaping (_ granted: Bool) -> ()) {
        showQuantityWarningControllerIfNeeded { [weak self] in
            self?.showWarningAlertIfNeeded(certificate: certificate, handler: {
                if (certificate as? EuropeanCertificate)?.isForeignCertificate == true {
                    self?.showforeignCertificateAlert(handler: {
                        completion(true)
                    }, cancelHandler: {
                        completion(false)
                    })
                } else {
                    completion(true)
                }
            }, cancelHandler: {
                completion(false)
            })
        }
    }

    private func showQuantityWarningControllerIfNeeded(_ continueCompletion: @escaping () -> ()) {
        guard WalletManager.shared.walletCertificates.count >= ParametersManager.shared.maxCertBeforeWarning else {
            continueCompletion()
            return
        }
        let controller: WalletQuantityWarningViewController = WalletQuantityWarningViewController {
            continueCompletion()
        } didCancel: { [weak self] in
            self?.navigationController?.topPresentedController.dismiss(animated: true)
        }
        controller.modalPresentationStyle = .fullScreen
        navigationController?.topPresentedController.present(controller, animated: true)
    }

    private func saveAndScrollToCertificate(certificate: WalletCertificate) {
        WalletManager.shared.saveCertificate(certificate)
        HUD.flash(.success)
        walletViewController?.scrollTo(certificate)
    }

    private func showComboDeclareWalletCertificate(url: URL) {
        let positiveTestController: PositiveTestStepsController = positiveTestStepsController(url: url)
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: BottomButtonContainerController.controller(positiveTestController))
        presentingController?.topPresentedController.present(navigationController, animated: true)
    }

    private func positiveTestStepsController(url: URL) -> PositiveTestStepsController {
        PositiveTestStepsController(
            comboUrl: url,
            didTouchAddCertificate: { [weak self] completion in
                do {
                    let certificate: WalletCertificate = try WalletManager.shared.getWalletCertificate(from: url)
                    self?.requestToSaveCertificate(certificate) { granted in
                        if granted {
                            self?.saveAndScrollToCertificate(certificate: certificate)
                        }
                        completion(granted)
                    }
                } catch {
                    let certificateType: WalletConstant.CertificateType = WalletManager.certificateTypeFromHeaderInUrl(url) ?? .vaccinationEurope
                    self?.showCertificateError(certificateType: certificateType, error: error)
                    completion(false)
                }
            }, didTouchDeclare: { code in
                guard let code = code else { return }
                NotificationCenter.default.post(Notification(name: .didEnterCodeFromDeeplink, object: code))
            })
    }

    private func showCertificateError(code: String?, error: Error) {
        var certificateType: WalletConstant.CertificateType = .vaccinationEurope
        if let url = URL(string: code ?? "") {
            certificateType = WalletManager.certificateTypeFromHeaderInUrl(url) ?? certificateType
        }
        let coordinator: WalletCertificateErrorCoordinator = WalletCertificateErrorCoordinator(presentingController: presentingController?.topPresentedController,
                                                                                               parent: self,
                                                                                               certificateType: certificateType,
                                                                                               error: error,
                                                                                               dismissBlock: { [weak self] in
                                                                                                self?.flashCodeController?.restartScanning()
                                                                                               })
        addChild(coordinator: coordinator)
    }

    private func showCompletedVaccinationControllerIfNeeded(certificate: EuropeanCertificate) {
        guard certificate.type == .vaccinationEurope else { return }
        guard certificate.isLastDose == true else { return }
        guard !DccBlacklistManager.shared.isBlacklisted(certificate: certificate) else { return }
        guard !certificate.isExpired else { return }
        guard !isPassExpired(for: certificate) else { return }
        let completedVaccinationController: CompletedVaccinationController = CompletedVaccinationController(certificate: certificate)
        let navigationController: UIViewController = CVNavigationController(rootViewController: completedVaccinationController)
        self.navigationController?.topPresentedController.present(navigationController, animated: true)
    }
    
    private func isPassExpired(for certificate: EuropeanCertificate) -> Bool {
        guard WalletManager.shared.shouldUseSmartWallet else { return false }
        return WalletManager.shared.isPassExpired(for: certificate)
    }
}
