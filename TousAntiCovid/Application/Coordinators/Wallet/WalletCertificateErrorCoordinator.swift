// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletCertificateErrorCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 17/03/2021 - for the TousAntiCovid project.
//

import UIKit
import PKHUD

final class WalletCertificateErrorCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    private let certificateType: WalletConstant.CertificateType
    private let error: Error
    private let dismissBlock: (() -> ())?
    
    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?
    
    init(presentingController: UIViewController?, parent: Coordinator, certificateType: WalletConstant.CertificateType, error: Error, dismissBlock: (() -> ())? = nil) {
        self.presentingController = presentingController
        self.parent = parent
        self.certificateType = certificateType
        self.error = error
        self.dismissBlock = dismissBlock
        start()
    }
    
    private func start() {
        let walletController: WalletCertificateErrorViewController = WalletCertificateErrorViewController(certificateType: certificateType, error: error) { [weak self] certificateType in
            self?.showDocumentExplanation(certificateType: certificateType)
        } deinitBlock: { [weak self] in
            self?.dismissBlock?()
            self?.didDeinit()
        }
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: walletController)
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }
    
    private func showDocumentExplanation(certificateType: WalletConstant.CertificateType) {
        let controller: DocumentExplanationViewController = DocumentExplanationViewController(certificateType: certificateType)
        self.navigationController?.pushViewController(controller, animated: true)
    }

}
