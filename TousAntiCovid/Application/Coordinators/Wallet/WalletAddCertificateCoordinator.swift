// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletAddCertificateCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 17/03/2021 - for the TousAntiCovid project.
//

import UIKit
import PKHUD

final class WalletAddCertificateCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?
    private weak var flashCodeController: FlashWalletCodeController?
    
    private var isFlashingCode: Bool = false
    
    init(presentingController: UIViewController?, parent: Coordinator) {
        self.presentingController = presentingController
        self.parent = parent
        start()
    }
    
    private func start() {
        let walletController: WalletAddCertificateViewController = WalletAddCertificateViewController { [weak self] certificateType in
            self?.startFlashCode(certificateType: certificateType)
        } didTouchDocumentExplanation: { [weak self] certificateType in
            self?.showDocumentExplanation(certificateType: certificateType)
        } deinitBlock: { [weak self] in
            self?.didDeinit()
        }
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: walletController)
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }
    
    private func startFlashCode(certificateType: WalletConstant.CertificateType) {
        guard !isFlashingCode else { return }
        isFlashingCode = true
        let controller: FlashWalletCodeController = FlashWalletCodeController.controller(didFlash: { [weak self] stringUrl in
            guard let stringUrl = stringUrl else { throw WalletError.parsing.error }
            guard let url = URL(string: stringUrl) else { throw WalletError.parsing.error }
            try WalletManager.shared.processWalletUrl(url)
            self?.presentingController?.dismiss(animated: true)
        }, didGetCertificateError: { [weak self] error in
            self?.showCertificateError(certificateType: certificateType, error: error)
        }, deinitBlock: { [weak self] in
            self?.isFlashingCode = false
        })
        flashCodeController = controller
        presentingController?.topPresentedController.present(CVNavigationController(rootViewController: controller), animated: true)
    }
    
    private func showCertificateError(certificateType: WalletConstant.CertificateType, error: Error) {
        let coordinator: WalletCertificateErrorCoordinator = WalletCertificateErrorCoordinator(presentingController: presentingController?.topPresentedController, parent: self, certificateType: certificateType, error: error, dismissBlock: {
            [weak self] in
            self?.flashCodeController?.restartScanning()
        })
        addChild(coordinator: coordinator)
    }
    
    private func showDocumentExplanation(certificateType: WalletConstant.CertificateType) {
        let controller: DocumentExplanationViewController = DocumentExplanationViewController(certificateType: certificateType)
        self.navigationController?.pushViewController(controller, animated: true)
    }

}
