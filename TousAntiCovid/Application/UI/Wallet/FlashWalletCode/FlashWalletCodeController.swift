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
    
    private var didFlash: ((_ code: String?) throws -> ())?
    private var didGetCertificateError: ((_ error: Error) -> ())?
    
    class func controller(didFlash: @escaping (_ code: String?) throws -> Void, didGetCertificateError: @escaping (_ error: Error) -> (), deinitBlock: (() -> ())? = nil) -> FlashWalletCodeController {
        let flashCodeController: FlashWalletCodeController = StoryboardScene.FlashWalletCode.flashWalletCodeController.instantiate()
        flashCodeController.didFlash = didFlash
        flashCodeController.didGetCertificateError = didGetCertificateError
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
            didGetCertificateError?(error)
        }
    }
    
    #if targetEnvironment(simulator)
    @objc private func didTouchFlashButton() {
        let url: String = "https://bonjour.tousanticovid.gouv.fr/app/wallet?v=DC04FR03AV011E791E79L101FRL0PAVOINE%1DL1EUGENE%1DL219081951L3COVID-19%1DL4J07BX03%1DL5MODERNA%1DL6MODERNA%1DL72L82L924032021LATE%1FKWT3FZQ726IFU6RUYD2KLOVYJUS7TMUGRNJNG55DIAN5BTBBM2Q6V3YXGM6YKRZVSD5GZZPY3RH7QNFFW5VZOT5MPULJOJBS7S567IA"
        do {
            try didFlash?(url)
        } catch {
            didGetCertificateError?(error)
        }
    }
    #endif
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
}
