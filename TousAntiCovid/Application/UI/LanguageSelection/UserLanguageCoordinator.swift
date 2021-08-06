// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UserLanguageCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 19/07/2021 - for the TousAntiCovid project.
//

import UIKit

final class UserLanguageCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var presentingController: UIViewController?
    
    init(presentingController: UIViewController?, parent: Coordinator) {
        self.presentingController = presentingController
        self.parent = parent
        start()
    }

    private func start() {
        let controller: UIViewController = UserLanguageController { [weak self] in
            self?.didDeinit()
        }
        if #available(iOS 13.0, *) {
            controller.isModalInPresentation = true
        }
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: controller)
        presentingController?.present(navigationController, animated: true, completion: nil)
    }

}
