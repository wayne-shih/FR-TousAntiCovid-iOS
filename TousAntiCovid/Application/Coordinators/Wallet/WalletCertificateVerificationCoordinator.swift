// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletCertificateVerificationCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 17/03/2021 - for the TousAntiCovid project.
//

import UIKit
import PKHUD

final class WalletCertificateVerificationCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []

    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?

    init(presentingController: UIViewController?, parent: Coordinator) {
        self.presentingController = presentingController
        self.parent = parent
        start()
    }

    private func start() {
        let controller: UIViewController = FlashWallet2DDocController.controller(didFlash: { [weak self] doc in
            guard let doc = doc else { throw WalletError.parsing.error }
            let certificate: WalletCertificate = try WalletManager.shared.extractCertificateFrom(doc: doc)
            let verifiedController: UIViewController = WalletCertificateVerifiedController.controller(certificate: certificate) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            self?.navigationController?.pushViewController(verifiedController, animated: true)
        }, deinitBlock: { [weak self] in
            self?.didDeinit()
        })
        let navigationController: CVNavigationController
        navigationController = CVNavigationController(rootViewController: controller)
        self.navigationController = navigationController
        presentingController?.topPresentedController.present(navigationController, animated: true)
    }

}
