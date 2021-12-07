// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UrgentDgsCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 04/10/2021 - for the TousAntiCovid project.
//

import UIKit

final class UrgentDgsCoordinator: Coordinator {
    
    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []

    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?

    init(presentingController: UIViewController?, parent: Coordinator) {
        self.presentingController = presentingController
        self.parent = parent
        start()
    }
}

// MARK: - Private functions -
private extension UrgentDgsCoordinator {
    func start() {
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: UrgentDgsDetailController(didTouchMoreInfo: { url in
            url.openInSafari()
        }, didTouchCloseButton: { [weak self] in
            self?.navigationController?.dismiss(animated: true)
        }, deinitBlock: { [weak self] in
            self?.didDeinit()
        }))
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }
}
