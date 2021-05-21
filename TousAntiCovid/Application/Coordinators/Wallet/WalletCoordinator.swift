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
    private weak var flashCodeController: UIViewController?
    private var initialUrlToProcess: URL?
    
    init(presentingController: UIViewController?, url: URL?, parent: Coordinator) {
        self.presentingController = presentingController
        self.initialUrlToProcess = url
        self.parent = parent
        start()
    }
    
    private func start() {
        let walletController: WalletViewController = createWalletController()
        let isHavingCertificates: Bool = !WalletManager.shared.walletCertificates.isEmpty
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: isHavingCertificates ? walletController : BottomButtonContainerController.controller(walletController))
        DeepLinkingManager.shared.walletController = walletController
        self.navigationController = navigationController
        initialUrlToProcess = nil
        presentingController?.present(navigationController, animated: true)
    }
    
    private func createWalletController() -> WalletViewController {
        WalletViewController(initialUrlToProcess: initialUrlToProcess) { [weak self] in
            self?.showAddCertificate()
        } didTouchTermsOfUse: { [weak self] in
            self?.openTermsOfUse()
        } didTouchCertificate: { [weak self] dataMatrix, text in
            self?.showDataMatrixFullscreen(dataMatrix, text: text)
        } didRequestWalletScanAuthorization: { [weak self] completion in
            self?.requestWalletScanAuthorization(completion)
        } didTouchDocumentExplanation: { [weak self] certificateType in
            self?.showDocumentExplanation(certificateType: certificateType)
        } didTouchWhenToUse: { [weak self]  in
            self?.showWhenToUseExplanations()
        } changeControllerContainer: { [weak self]  in
            self?.changeContainerController()
        } didGetCertificateError: { [weak self] certificateType, error in
            self?.showCertificateError(certificateType: certificateType, error: error)
        } deinitBlock: { [weak self] in
            self?.didDeinit()
        }
    }
    
    private func openTermsOfUse() {
        URL(string: "walletController.termsOfUse.url".localized)?.openInSafari()
    }
    
    private func showDataMatrixFullscreen(_ dataMatrix: UIImage, text: String) {
        let controller: UIViewController = CodeFullScreenViewController.controller(codeImage: dataMatrix, text: text, codeBottomText: "2D-DOC", codeType: .dataMatrix)
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        navigationController?.present(controller, animated: true)
    }
    
    private func showAddCertificate() {
        let coordinator: WalletAddCertificateCoordinator = WalletAddCertificateCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: coordinator)
    }

    private func requestWalletScanAuthorization(_ completion: @escaping (_ granted: Bool) -> ()) {
        let walletScanAuthorizationController: WalletScanAuthorizationController = WalletScanAuthorizationController { [weak self] granted in
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
    
    private func changeContainerController() {
        guard let navigationController = navigationController else { return }
        let isHavingCertificates: Bool = !WalletManager.shared.walletCertificates.isEmpty
        let walletController: WalletViewController = createWalletController()
        let controller: UIViewController = isHavingCertificates ? walletController : BottomButtonContainerController.controller(walletController)
        UIView.transition(with: navigationController.view, duration: isHavingCertificates ? 0.0 : 0.3, options: .transitionCrossDissolve) {
            navigationController.setViewControllers([controller], animated: false)
        } completion: { _ in }

        DeepLinkingManager.shared.walletController = walletController
    }

    private func showCertificateError(certificateType: WalletConstant.CertificateType, error: Error) {
        let coordinator: WalletCertificateErrorCoordinator = WalletCertificateErrorCoordinator(presentingController: presentingController?.topPresentedController, parent: self, certificateType: certificateType, error: error)
        addChild(coordinator: coordinator)
    }

}
