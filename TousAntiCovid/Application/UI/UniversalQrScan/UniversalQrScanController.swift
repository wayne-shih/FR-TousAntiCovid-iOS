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

final class UniversalQrScanController: FlashCodeController {
    
    private var didFlash: ((_ url: URL?) throws -> ())?
    
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
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        if navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
            navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
        }
    }
    
    override func processScannedQRCode(code: String?) {
        do {
            try didFlash?(DeepLinkingManager.shared.deeplinkForCode(code ?? ""))
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
