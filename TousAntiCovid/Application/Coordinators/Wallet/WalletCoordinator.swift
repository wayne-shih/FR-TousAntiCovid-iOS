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

final class WalletCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?
    private weak var flashCodeController: FlashWalletCodeController?
    private var initialUrlToProcess: URL?

    private var isFlashingCode: Bool = false
    
    init(presentingController: UIViewController?, url: URL?, parent: Coordinator) {
        self.presentingController = presentingController
        self.initialUrlToProcess = url
        self.parent = parent
        start()
    }
    
    private func start() {
        let areThereLoadedCertificates: Bool = WalletManager.shared.areThereLoadedCertificates
        if !areThereLoadedCertificates { HUD.show(.progress) }
        let walletController: WalletViewController = createWalletController()
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: BottomButtonContainerController.controller(walletController))
        DeepLinkingManager.shared.walletController = walletController
        self.navigationController = navigationController
        initialUrlToProcess = nil
        presentingController?.present(navigationController, animated: true) {
            if !areThereLoadedCertificates { HUD.hide() }
        }
    }
    
    private func createWalletController() -> WalletViewController {
        WalletViewController(initialUrlToProcess: initialUrlToProcess) { [weak self] in
            self?.startFlashCode()
        } didTouchTermsOfUse: { [weak self] in
            self?.openTermsOfUse()
        } didTouchCertificate: { [weak self] certificate in
            self?.showDataMatrixFullscreen(certificate)
        } didRequestWalletScanAuthorization: { [weak self] comingFromTheApp, completion in
            self?.requestWalletScanAuthorization(comingFromTheApp: comingFromTheApp, completion: completion)
        } didScanEuropeanCertifcate: { [weak self] certificate in
            self?.showCompletedVaccinationControllerIfNeeded(certificate: certificate)
        } didTouchDocumentExplanation: { [weak self] certificateType in
            self?.showDocumentExplanation(certificateType: certificateType)
        } didTouchWhenToUse: { [weak self]  in
            self?.showWhenToUseExplanations()
        } didGetCertificateError: { [weak self] certificateType, error in
            self?.showCertificateError(certificateType: certificateType, error: error)
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

    private func showDataMatrixFullscreen(_ certificate: WalletCertificate) {
        guard let codeImage = certificate.codeImage else { return }
        let controller: UIViewController = CodeFullScreenViewController.controller(codeImage: codeImage, text: certificate.shortDescription ?? "", codeBottomText: certificate.codeImageTitle)
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        navigationController?.present(controller, animated: true)
    }

    private func requestWalletScanAuthorization(comingFromTheApp: Bool, completion: @escaping (_ granted: Bool) -> ()) {
        let walletScanAuthorizationController: WalletScanAuthorizationController = WalletScanAuthorizationController(comingFromTheApp: comingFromTheApp) { [weak self] granted in
            self?.navigationController?.topPresentedController.dismiss(animated: true) {
                completion(granted)
            }
        }
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
        let controller: FlashWalletCodeController = FlashWalletCodeController.controller(didFlash: { [weak self] stringUrl in
            guard let stringUrl = stringUrl else { throw WalletError.parsing.error }
            guard let url = URL(string: stringUrl) else { throw WalletError.parsing.error }
            let certificate: WalletCertificate? = try WalletManager.shared.getWalletCertificate(from: url)
            if let certificate = certificate {
                WalletManager.shared.saveCertificate(certificate)
            }
            self?.navigationController?.dismiss(animated: true) { [weak self] in
                if let europeanCertificate = certificate as? EuropeanCertificate {
                    self?.showCompletedVaccinationControllerIfNeeded(certificate: europeanCertificate)
                }
            }
        }, didGetCertificateError: { [weak self] code, error in
            self?.showCertificateError(code: code, error: error)
        }, deinitBlock: { [weak self] in
            self?.isFlashingCode = false
        })
        flashCodeController = controller
        presentingController?.topPresentedController.present(CVNavigationController(rootViewController: controller), animated: true)
    }

    private func showCertificateError(code: String?, error: Error) {
        var certificateType: WalletConstant.CertificateType = .sanitary
        if let url = URL(string: code ?? "") {
            certificateType = WalletManager.certificateTypeFromHeaderInUrl(url) ?? .sanitary
        }
        let coordinator: WalletCertificateErrorCoordinator = WalletCertificateErrorCoordinator(presentingController: presentingController?.topPresentedController, parent: self, certificateType: certificateType, error: error, dismissBlock: {
            [weak self] in
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
