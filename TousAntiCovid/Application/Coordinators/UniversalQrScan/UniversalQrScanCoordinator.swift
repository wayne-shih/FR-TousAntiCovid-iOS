// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UniversalQrScanCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 02/08/2021 - for the TousAntiCovid project.
//

import UIKit
import PKHUD

final class UniversalQrScanCoordinator: Coordinator {
    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var presentingController: UIViewController?
    private weak var navigationController: UINavigationController?

    init(presentingController: UIViewController?, parent: Coordinator) {
        self.presentingController = presentingController
        self.parent = parent
        start()
    }
    
    private func start() {
        HUD.show(.progress)
        let controller: UniversalQrScanController = UniversalQrScanController.controller(didFlash: { [weak self] url in
            guard let url = url else { throw NSError.localizedError(message: "universalQrScanController.error.noCodeFound".localized, code: 0) }
            self?.navigationController?.dismiss(animated: true) {
                HUD.show(.progress)
                DispatchQueue.main.async {
                    DeepLinkingManager.shared.processUrl(url, fromApp: true)
                    HUD.hide()
                }
            }
        }, deinitBlock: { [weak self] in
            self?.didDeinit()
        })
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: controller)
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true) { HUD.hide() }
    }
}
