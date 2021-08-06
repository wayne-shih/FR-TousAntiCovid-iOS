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
import PKHUD
import RobertSDK

final class WalletCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?
    private weak var flashCodeController: FlashWalletCodeController?
    private weak var walletViewController: WalletViewController?

    private var initialUrlToProcess: URL?

    private var isFlashingCode: Bool = false
    
    init(presentingController: UIViewController?, url: URL?, parent: Coordinator) {
        self.presentingController = presentingController
        self.initialUrlToProcess = url
        self.parent = parent
        start()
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

    private func start() {
        DeepLinkingManager.shared.walletCoordinator = self
        let areThereLoadedCertificates: Bool = WalletManager.shared.areThereLoadedCertificates
        if !areThereLoadedCertificates { HUD.show(.progress) }
        let walletController: WalletViewController = createWalletController()
        walletViewController = walletController
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: BottomButtonContainerController.controller(walletController))
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true) { [weak self] in
            if !areThereLoadedCertificates { HUD.hide() }
            self?.processUrl(url: self?.initialUrlToProcess)
            self?.initialUrlToProcess = nil
        }
    }
    
    private func createWalletController() -> WalletViewController {
        WalletViewController { [weak self] in
            self?.startFlashCode()
        } didTouchTermsOfUse: { [weak self] in
            self?.openTermsOfUse()
        } didTouchCertificate: { [weak self] certificate in
            self?.showCodeFullscreen(certificate)
        } didConvertToEuropeanCertifcate: { [weak self] certificate in
            self?.showCompletedVaccinationControllerIfNeeded(certificate: certificate)
        } didTouchDocumentExplanation: { [weak self] certificateType in
            self?.showDocumentExplanation(certificateType: certificateType)
        } didTouchWhenToUse: { [weak self]  in
            self?.showWhenToUseExplanations()
        } didTouchConvertToEuropeTermsOfUse: { [weak self] in
            self?.openConvertToEuropeTermsOfUse()
        } deinitBlock: { [weak self] in
            self?.didDeinit()
        }
    }
    
    private func openTermsOfUse() {
        URL(string: "walletController.termsOfUse.url".localized)?.openInSafari()
    }
    private func openConvertToEuropeTermsOfUse() {
        URL(string: "walletController.menu.convertToEurope.alert.termsUrl".localized)?.openInSafari()
    }

    private func showCodeFullscreen(_ certificate: WalletCertificate) {
        let codeDetails: [CodeDetail] = prepareCodeFullScreenData(certificate)
        guard !codeDetails.isEmpty else { return }
        let isFrenchCertificate: Bool = !((certificate as? EuropeanCertificate)?.isForeignCertificate ?? true)
        let controller: UIViewController = CodeFullScreenViewController.controller(codeDetails: codeDetails, showHeaderImage: isFrenchCertificate)
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        navigationController?.present(controller, animated: true)
    }

    private func prepareCodeFullScreenData(_ certificate: WalletCertificate) -> [CodeDetail] {
        guard let codeImage = certificate.codeImage else { return [] }
        let footerText: String? = certificate is EuropeanCertificate ? "europeanCertificate.fullscreen.type.minimum.footer".localized : nil
        var codeDetails: [CodeDetail] = [CodeDetail(segmentedControlTitle: "europeanCertificate.fullscreen.type.minimum".localized, codeImage: codeImage, codeBottomText: certificate.codeImageTitle, text: certificate.shortDescription, footerText: footerText)]

        if let europeanCertificate = certificate as? EuropeanCertificate {
            codeDetails.append(CodeDetail(segmentedControlTitle: "europeanCertificate.fullscreen.type.border".localized, codeImage: codeImage, codeBottomText: nil, text: europeanCertificate.fullDescriptionForFullscreen, footerText: europeanCertificate.uniqueHash))
        }
        return codeDetails
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

    private func showCertificateError(certificateType: WalletConstant.CertificateType, error: Error) {
        let coordinator: WalletCertificateErrorCoordinator = WalletCertificateErrorCoordinator(presentingController: presentingController?.topPresentedController, parent: self, certificateType: certificateType, error: error)
        addChild(coordinator: coordinator)
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
        if DccBlacklistManager.shared.isBlacklisted(certificate: certificate) {
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
        self.showWarningAlertIfNeeded(certificate: certificate, handler: { [weak self] in
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

    private func saveAndScrollToCertificate(certificate: WalletCertificate) {
        WalletManager.shared.saveCertificate(certificate)
        AnalyticsManager.shared.reportAppEvent(.e13)
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
        guard certificate.isLastDose == true  else { return }
        let completedVaccinationController: CompletedVaccinationController = CompletedVaccinationController(certificate: certificate)
        let navigationController: UIViewController = CVNavigationController(rootViewController: completedVaccinationController)
        self.navigationController?.topPresentedController.present(navigationController, animated: true)
    }
}
