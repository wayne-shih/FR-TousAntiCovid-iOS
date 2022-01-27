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
import LBBottomSheet

final class FullscreenCertificateCoordinator: Coordinator {
    
    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private var certificate: WalletCertificate {
        didSet {
            AnalyticsManager.shared.reportAppEvent(certificate.is2dDoc ? .e27 : .e26)
        }
    }
    private weak var presentingController: UIViewController?
    private weak var navigationController: UINavigationController?
    private weak var fullscreenController: FullscreenCertificateViewController?
    private weak var bottomSheetController: BottomSheetController?
    
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
        }, didTouchShareCertificate: { [weak self] confirmationHandler in
            self?.showSharingConfirmationController(confirmationHandler: confirmationHandler)
        }, didTouchShowOptions: { [weak self] brightnessParamDidChange, shareConfirmationHandler in
            self?.showOptionsController(brightnessParamDidChange: brightnessParamDidChange, shareConfirmationHandler: shareConfirmationHandler)
        }, dismissBlock: { [weak self] in
            self?.presentingController?.dismiss(animated: true)
        }, deinitBlock: { [weak self] in
            self?.didDeinit()
        })
        fullscreenController = controller
        let innerController: UIViewController = BottomButtonContainerController.controller(controller)
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: innerController)
        navigationController.modalTransitionStyle = .crossDissolve
        navigationController.modalPresentationStyle = .fullScreen
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }

    private func showActivityPassParametersController(confirmationHandler: @escaping () -> ()) {
        let controller: ActivityPassParametersViewController = .init(didTouchConfirm: { [weak self] in
            self?.bottomSheetController?.dismiss {
                confirmationHandler()
            }
        }, didTouchReadCGU: {
            URL(string: "activityPassParametersController.cguUrl".localized)?.openInSafari()
        }, dismissBlock: { [weak self] in
            self?.bottomSheetController?.dismiss()
        })
        showBottomSheet(controller: controller)
    }
    
    private func showSharingConfirmationController(confirmationHandler: @escaping () -> ()) {
        let bottomSheet: BottomSheetAlertController = .init(
            title: "certificateSharingController.title".localized,
            message: "certificateSharingController.message".localized,
            okTitle: "common.confirm".localized,
            cancelTitle: "common.cancel".localized,
            interfaceStyle: .light) {
                confirmationHandler()
            }
        bottomSheet.show()
    }
    
    private func showOptionsController(brightnessParamDidChange: @escaping (_ activated: Bool) -> (), shareConfirmationHandler: @escaping () -> ()) {
        let optionsController: FullscreenOptionsController = .init() { activated in
            brightnessParamDidChange(activated)
        } didTouchShareCertificateButton: { [weak self] in
            self?.showSharingConfirmationController {
                shareConfirmationHandler()
            }
        }
        if #available(iOS 13.0, *) {
            navigationController?.presentAsBottomSheet(optionsController, theme: optionsController.bottomSheetTheme).overrideUserInterfaceStyle = .light
        } else {
            navigationController?.presentAsBottomSheet(optionsController, theme: optionsController.bottomSheetTheme)
        }
    }

    private func showBottomSheet(controller: UIViewController) {
        let behavior: BottomSheetController.Behavior = .init(swipeMode: .full)
        var grabberBackground: BottomSheetController.Theme.Grabber.Background = .color(isTranslucent: false)
        if #available(iOS 13.0, *) {
            let effect: UIBlurEffect = .init(style: .light)
            let blurEffectView: UIVisualEffectView = .init(effect: effect)
            grabberBackground = .view(blurEffectView, isTranslucent: true)
        }
        var theme: BottomSheetController.Theme = .init()
        theme.grabber?.background = grabberBackground
        bottomSheetController = navigationController?.presentAsBottomSheet(controller, theme: theme, behavior: behavior)
        if #available(iOS 13.0, *) {
            bottomSheetController?.overrideUserInterfaceStyle = .light
        }
    }
}
