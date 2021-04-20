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
        let walletController: WalletViewController = WalletViewController(initialUrlToProcess: initialUrlToProcess) { [weak self] in
            self?.startFlashCode()
        } didTouchTermsOfUse: { [weak self] in
            self?.openTermsOfUse()
        } didTouchCertificate: { [weak self] dataMatrix, text in
            self?.showDataMatrixFullscreen(dataMatrix, text: text)
        } didRequestWalletScanAuthorization: { [weak self] completion in
            self?.requestWalletScanAuthorization(completion)
        } deinitBlock: { [weak self] in
            self?.didDeinit()
        }
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: walletController)
        DeepLinkingManager.shared.walletController = walletController
        self.navigationController = navigationController
        initialUrlToProcess = nil
        presentingController?.present(navigationController, animated: true)
    }
    
    private func openTermsOfUse() {
        URL(string: "walletController.termsOfUse.url".localized)?.openInSafari()
    }
    
    private func showDataMatrixFullscreen(_ dataMatrix: UIImage, text: String) {
        let controller: UIViewController = CodeFullScreenViewController.controller(codeImage: dataMatrix, text: text, codeBottomText: "2D-DOC")
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        navigationController?.present(controller, animated: true)
    }
    
    private func startFlashCode() {
        let controller: UIViewController = FlashWalletCodeController.controller(didFlash: { stringUrl in
            guard let stringUrl = stringUrl else { throw WalletError.parsing.error }
            guard let url = URL(string: stringUrl) else { throw WalletError.parsing.error }
            try WalletManager.shared.processWalletUrl(url)
            self.flashCodeController?.dismiss(animated: true)
        })
        flashCodeController = controller
        presentingController?.topPresentedController.present(CVNavigationController(rootViewController: controller), animated: true)
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

}
