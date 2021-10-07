// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UniversalQrScanController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 10/06/2021 - for the TousAntiCovid project.
//

import UIKit
import StorageSDK
import ServerSDK

final class UniversalQrScanController: FlashCodeController {
    
    private var didFlash: ((_ url: URL?) throws -> ())?
    private var confettiView: ConfettiView?
    
    static func controller(didFlash: @escaping (_ url: URL?) throws -> Void, deinitBlock: (() -> ())? = nil) -> UniversalQrScanController {
        let flashCodeController: UniversalQrScanController = StoryboardScene.UniversalQrScan.universalQrScanController.instantiate()
        flashCodeController.didFlash = didFlash
        flashCodeController.deinitBlock = deinitBlock
        flashCodeController.allowMediaPickers = true
        return flashCodeController
    }
    
    override func initUI() {
        super.initUI()
        explanationLabel.text = "universalQrScanController.explanation".localized
        explanationLabel.font = Appearance.Cell.Text.standardFont
        explanationLabel.adjustsFontForContentSizeCategory = true
        let buttonText: String = "universalQrScanController.footer.text".localizedOrEmpty
        if buttonText.isEmpty {
            bottomButton?.isHidden = true
            bottomGradientImageView?.isHidden = true
        } else {
            bottomButton?.setTitle("universalQrScanController.footer.text".localized, for: .normal)
            bottomButton?.setTitleColor(.white, for: .normal)
            bottomButton?.titleLabel?.font = Appearance.Cell.Text.accessoryFont
            bottomButton?.titleLabel?.adjustsFontForContentSizeCategory = true
            bottomButton?.titleLabel?.numberOfLines = 0
            bottomButton?.titleLabel?.textAlignment = .center
        }

        navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont,
                                                                   .foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = .white
        if #available(iOS 15, *) {
            // navigation bar transparency specified in child controller
            let appearence = UINavigationBarAppearance()
            appearence.configureWithTransparentBackground()
            navigationItem.scrollEdgeAppearance = appearence
            navigationItem.standardAppearance = appearence
        } else {
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
        }
        if navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
            navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
        }
    }
    
    override func processScannedQRCode(code: String?) {
        do {
            if code == "https://bonjour.tousanticovid.gouv.fr" {
                startConfettiWithHaptic()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.restartScanning() }
            } else {
                try didFlash?(DeepLinkingManager.shared.deeplinkForCode(code ?? ""))
            }
        } catch {
            let alertTitle: String = "universalQrScanController.error.title".localized
            let alertMessage: String = error.localizedDescription
            showAlert(title: alertTitle, message: alertMessage, okTitle: "common.ok".localized, handler: {
                self.restartScanning()
            })
        }
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func didTouchBottomButton(_ sender: Any) {
        URL(string: "universalQrScanController.footer.link.ios".localized)?.openInSafari()
    }
    
}

extension UniversalQrScanController {
    private func startConfettiWithHaptic() {
        stopConfetti()
        confettiView = ConfettiView(frame: view.bounds)
        guard let confettiView = confettiView else { return }
        view.window?.addSubview(confettiView)
        confettiView.startConfetti(birthRate: ParametersManager.shared.confettiBirthRate)
        haptic()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            confettiView.stopConfetti()
        }
    }

    private func stopConfetti() {
        if let oldConfetti = confettiView {
            oldConfetti.removeFromSuperview()
            confettiView = nil
        }
    }

    private func haptic() {
        if #available(iOS 13.0, *) {
            HapticManager.shared.hapticFirework()
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}
