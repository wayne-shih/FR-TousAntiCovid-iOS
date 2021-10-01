// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  FullscreenCertificateCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK

final class FullscreenCertificateCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []

    private var certificate: WalletCertificate
    private weak var presentingController: UIViewController?
    private weak var navigationController: UINavigationController?
    private weak var fullscreenController: FullscreenCertificateViewController?
    
    init(presentingController: UIViewController?, parent: Coordinator, certificate: WalletCertificate) {
        self.presentingController = presentingController
        self.parent = parent
        self.certificate = certificate
        start()
    }

    func updateCertificate(_ certificate: WalletCertificate) {
        self.certificate = certificate
        fullscreenController?.updateCertificate(certificate)
    }

    private func start() {
        let controller: FullscreenCertificateViewController = FullscreenCertificateViewController(certificate: certificate, didTouchGenerateActivityPass: { [weak self] confirmationHandler in
            self?.showActivityPassParametersController(confirmationHandler: confirmationHandler)
        }, dismissBlock: { [weak self] in
            self?.presentingController?.dismiss(animated: true)
        }, deinitBlock: { [weak self] in
            self?.didDeinit()
        })
        fullscreenController = controller
        let innerController: UIViewController = certificate.is2dDoc || !WalletManager.shared.isActivityPassActivated ? controller : BottomButtonContainerController.controller(controller)
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: innerController)
        navigationController.modalTransitionStyle = .crossDissolve
        navigationController.modalPresentationStyle = .fullScreen
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }

    private func showActivityPassParametersController(confirmationHandler: @escaping () -> ()) {
        let controller: ActivityPassParametersViewController = ActivityPassParametersViewController(didTouchConfirm: { [weak self] in
            self?.navigationController?.dismiss(animated: true) {
                confirmationHandler()
            }
        }, didTouchReadCGU: {
            URL(string: "activityPassParametersController.cguUrl".localized)?.openInSafari()
        }, dismissBlock: { [weak self] in
            self?.navigationController?.dismiss(animated: true)
        })
        navigationController?.present(CVNavigationController(rootViewController: controller), animated: true)
    }

}
