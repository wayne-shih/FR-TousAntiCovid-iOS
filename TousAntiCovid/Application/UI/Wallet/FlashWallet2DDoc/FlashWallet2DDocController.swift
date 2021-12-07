// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  FlashWallet2DDocController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/03/2021 - for the TousAntiCovid project.
//

import UIKit
import StorageSDK

final class FlashWallet2DDocController: FlashCodeController {
    
    private var didFlash: ((_ code: String?) throws -> Void)?
    
    class func controller(didFlash: @escaping (_ code: String?) throws -> Void, deinitBlock: (() -> ())? = nil) -> FlashWallet2DDocController {
        let flashCodeController: FlashWallet2DDocController = StoryboardScene.FlashWallet2DDoc.flashWallet2DDocController.instantiate()
        flashCodeController.didFlash = didFlash
        flashCodeController.deinitBlock = deinitBlock
        return flashCodeController
    }
    
    override func initUI() {
        super.initUI()
        explanationLabel.text = "flashDataMatrixCodeController.explanation".localized
        explanationLabel.font = Appearance.Cell.Text.standardFont
        explanationLabel.adjustsFontForContentSizeCategory = true
        navigationController?.navigationBar.tintColor = .white
        if #available(iOS 13, *) {
            // navigation bar transparency specified in child controller
            let appearence = UINavigationBarAppearance()
            appearence.configureWithTransparentBackground()
            appearence.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont, .foregroundColor: UIColor.white]
            navigationItem.scrollEdgeAppearance = appearence
            navigationItem.standardAppearance = appearence
        } else {
            navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont, .foregroundColor: UIColor.white]
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
        }
        if navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
            navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
        }
        #if targetEnvironment(simulator)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Flash", style: .plain, target: self, action: #selector(didTouchFlashButton))
        #endif
    }

    override func processScannedQRCode(code: String?) {
        do {
            try didFlash?(code)
        } catch {
            showErrorAlert(error: error)
        }
    }
    
    private func showErrorAlert(error: Error) {
        let alertTitle: String = "wallet.proof.error.\((error as NSError).code).title".localized
        let alertMessage: String = error.localizedDescription
        showAlert(title: alertTitle,
                  message: alertMessage,
                  okTitle: "common.ok".localized, handler: {
                    self.restartScanning()
                  })
    }
    
    #if targetEnvironment(simulator)
    @objc private func didTouchFlashButton() {
        scanView.stopScanning()
        do {
            try didFlash?("DC04DHI0TST11E3C1E3CB201FRF0JEAN LOUIS/EDOUARD\u{1D}F1DUPOND\u{1D}F225111980F3MF494309\u{1D}F5NF6110320211452\u{1F}ZCQ5EDEXRCRYMU4U5U4YQSF5GOE2PMFFC6PDWOMZK64434TUCJWQLIXCRYMA5TWVT7TEZSF2S3ZCJSYK3JYFOBVUHNOEXQMEKWQDG3A")
        } catch {
            showErrorAlert(error: error)
        }
    }
    #endif
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
}
