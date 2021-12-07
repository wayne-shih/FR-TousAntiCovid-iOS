// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesInformationCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/05/2021 - for the TousAntiCovid project.
//

import UIKit

final class VenuesInformationCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []

    private weak var presentingController: UIViewController?

    init(presentingController: UIViewController?, parent: Coordinator?, didTouchContinue: (() -> ())?) {
        self.presentingController = presentingController
        self.parent = parent
        start(didTouchContinue: didTouchContinue)
    }

    private func start(didTouchContinue: (() -> ())?) {
        let venuesInfoController: VenuesInformationController = VenuesInformationController(didTouchContinue: didTouchContinue, deinitBlock: { [weak self] in self?.didDeinit() })
        let rootController: UIViewController = didTouchContinue != nil ? BottomButtonContainerController.controller(venuesInfoController) : venuesInfoController
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: rootController)
        presentingController?.topPresentedController.present(navigationController, animated: true)
    }
}
