// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AttestationsCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD

final class AttestationsCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?
    private weak var attestationsViewController: AttestationsViewController?
    private var wasVoiceOverActivated: Bool = UIAccessibility.isVoiceOverRunning
    
    init(presentingController: UIViewController?, parent: Coordinator) {
        self.presentingController = presentingController
        self.parent = parent
        addObserver()
        start()
    }
    
    deinit {
        removeObserver()
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(voiceOverStatusDidChange), name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
    }

    private func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func start() {
        let attestationController: AttestationsViewController = createAttestationController()
        attestationsViewController = attestationController
        let innerController: UIViewController = BottomButtonContainerController.controller(attestationController)
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: innerController)
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }
    
    private func updateCurrentController() {
        attestationsViewController?.deinitBlock = nil
        let attestationsViewController: AttestationsViewController = createAttestationController()
        self.attestationsViewController = attestationsViewController
        let innerController: UIViewController = UIAccessibility.isVoiceOverRunning ? attestationsViewController : BottomButtonContainerController.controller(attestationsViewController)
        navigationController?.setViewControllers([innerController], animated: false)
    }
    
    private func createAttestationController() -> AttestationsViewController {
        AttestationsViewController { [weak self] in
            self?.openNewAttestation()
        } didTouchTermsOfUse: { [weak self] in
            self?.openTermsOfUse()
        } didTouchWebAttestation: { [weak self] in
            self?.openWebAttestation()
        } didTouchAttestationQrCode: { [weak self] qrCode, text in
            self?.showAttestationQRCodeFullscreen(qrCode, text: text)
        } deinitBlock: { [weak self] in
            self?.didDeinit()
        }
    }
    
    private func openNewAttestation() {
        HUD.show(.progress)
        AttestationsManager.shared.fetchAttestationForm(timeout: 2.0) {
            HUD.hide()
            let newAttestationCoordinator: NewAttestationCoordinator = NewAttestationCoordinator(presentingController: self.navigationController, parent: self)
            self.addChild(coordinator: newAttestationCoordinator)
        }
    }
    
    private func openTermsOfUse() {
        URL(string: "attestationsController.termsOfUse.url".localized)?.openInSafari()
    }
    
    private func openWebAttestation() {
        URL(string: "home.moreSection.curfewCertificate.url".localized)?.openInSafari()
    }
    
    private func showAttestationQRCodeFullscreen(_ qrCode: UIImage, text: String) {
        let controller: UIViewController = CodeFullScreenViewController.controller(codeDetails: [CodeDetail(codeImage: qrCode, text: text)], showHeaderImage: false)
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        navigationController?.present(controller, animated: true)
    }
    
    @objc private func voiceOverStatusDidChange() {
        guard wasVoiceOverActivated != UIAccessibility.isVoiceOverRunning else { return }
        wasVoiceOverActivated = UIAccessibility.isVoiceOverRunning
        updateCurrentController()
    }
    
}
