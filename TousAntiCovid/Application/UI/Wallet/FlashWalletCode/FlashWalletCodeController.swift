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
    
    private var didFlash: ((_ code: String?) throws -> Void)?
    
    class func controller(didFlash: @escaping (_ code: String?) throws -> Void, deinitBlock: (() -> ())? = nil) -> FlashWalletCodeController {
        let flashCodeController: FlashWalletCodeController = StoryboardScene.FlashWalletCode.flashWalletCodeController.instantiate()
        flashCodeController.didFlash = didFlash
        flashCodeController.deinitBlock = deinitBlock
        return flashCodeController
    }
    
    override func initUI() {
        title = "flashWalletCodeController.title".localized
        explanationLabel.text = "flashWalletCodeController.explanation".localized
        explanationLabel.font = Appearance.Cell.Text.standardFont
        explanationLabel.adjustsFontForContentSizeCategory = true
        navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont]
        if navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
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
        let url: String = "https://bonjour.tousanticovid.gouv.fr/app/wallet?v=DC04DHI0TST11E3C1E3CB201FRF0JEAN%20LOUIS/EDOUARD%1DF1DUPOND%1DF225111980F3MF494309%1DF5NF6110320211452%1FZCQ5EDEXRCRYMU4U5U4YQSF5GOE2PMFFC6PDWOMZK64434TUCJWQLIXCRYMA5TWVT7TEZSF2S3ZCJSYK3JYFOBVUHNOEXQMEKWQDG3A"
        do {
            try didFlash?(url)
        } catch {
            showErrorAlert(error: error)
        }
    }
    #endif
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
}
