// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  FlashWalletCodeController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/03/2021 - for the TousAntiCovid project.
//

import UIKit
import StorageSDK

final class FlashWalletCodeController: FlashCodeController {

    private var didFlash: ((_ url: URL?) throws -> ())?
    private var didGetCertificateError: ((_ code: String?, _ error: Error) -> ())?
    
    class func controller(didFlash: @escaping (_ url: URL?) throws -> Void, didGetCertificateError: @escaping (_ code: String?, _ error: Error) -> (), deinitBlock: (() -> ())? = nil) -> FlashWalletCodeController {
        let flashCodeController: FlashWalletCodeController = StoryboardScene.FlashWalletCode.flashWalletCodeController.instantiate()
        flashCodeController.didFlash = didFlash
        flashCodeController.didGetCertificateError = didGetCertificateError
        flashCodeController.deinitBlock = deinitBlock
        flashCodeController.allowMediaPickers = true
        return flashCodeController
    }
    
    override func initUI() {
        super.initUI()
        explanationLabel.text = "flashWalletCodeController.explanation".localized
        explanationLabel.font = Appearance.Cell.Text.standardFont
        explanationLabel.adjustsFontForContentSizeCategory = true
        let buttonText: String = "flashWalletCodeController.footer.text".localizedOrEmpty
        if buttonText.isEmpty {
            bottomButton?.isHidden = true
            bottomGradientImageView?.isHidden = true
        } else {
            bottomButton?.setTitle("flashWalletCodeController.footer.text".localized, for: .normal)
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
        dismissPickerIfNeeded { [weak self] in
            do {
                try self?.didFlash?(DeepLinkingManager.shared.deeplinkForCode(code ?? ""))
            } catch {
                self?.didGetCertificateError?(code, error)
            }
        }
    }
    
    private func dismissPickerIfNeeded(_ completion: @escaping () -> ()) {
        guard navigationController?.presentedViewController != nil else {
            completion()
            return
        }
        navigationController?.dismiss(animated: true) { completion() }
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func didTouchBottomButton(_ sender: Any) {
        URL(string: "flashWalletCodeController.footer.link.ios".localized)?.openInSafari()
    }

}
