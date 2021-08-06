// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  FlashVenueCodeController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class FlashVenueCodeController: FlashCodeController {
    
    private var didFlash: ((_ code: String?) -> Bool)?
    private var didTouchMoreInfo: (() -> ())?

    class func controller(didTouchMoreInfo: @escaping () -> (), didFlash: @escaping (_ code: String?) -> Bool, deinitBlock: (() -> ())? = nil) -> FlashVenueCodeController {
        let flashCodeController: FlashVenueCodeController = StoryboardScene.FlashVenueCode.flashCodeController.instantiate()
        flashCodeController.didFlash = didFlash
        flashCodeController.deinitBlock = deinitBlock
        flashCodeController.didTouchMoreInfo = didTouchMoreInfo
        return flashCodeController
    }
    
    override func initUI() {
        super.initUI()
        explanationLabel.text = "venueFlashCodeController.explanation".localized
        explanationLabel.font = Appearance.Cell.Text.standardFont
        explanationLabel.adjustsFontForContentSizeCategory = true
        navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont,
                                                                   .foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "common.moreInfo".localized, style: .plain, target: self, action: #selector(didTouchMoreInfoButton))
        #if targetEnvironment(simulator)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Flash", style: .plain, target: self, action: #selector(didTouchFlashButton))
        #endif
    }

    override func processScannedQRCode(code: String?) {
        if didFlash?(code) == false {
            showErrorAlert()
        }
    }
    
    private func showErrorAlert() {
        showAlert(title: "venueFlashCodeController.alert.invalidCode.title".localized,
                  message: "venueFlashCodeController.alert.invalidCode.message".localized,
                  okTitle: "common.ok".localized, handler: {
                    self.restartScanning()
                  })
    }
    
    #if targetEnvironment(simulator)
    @objc private func didTouchFlashButton() {
        scanView.stopScanning()
        let url: String = ["https://tac.gouv.fr?v=0#AGaRdaXVh8OLMN-eNtZ_V6mLlr77DpCEzGcmRkNz1ZQ1Cv2GUXlkp2QzzYuVVjM8X3JIRXhPzpbW4OVDb9kgvqAQoP3K_thjGcf1Ei8CK90ZV1UvaXs8_N7ZThf3HKYhMC8wj3f3pKXRUtvBvuU%3D", "https://tac.gouv.fr?v=0#AGaRdaXVh8OLMN-eNtZ_V6mLlr77DpCEzGcmRkNz1ZQ1Cv2GUXlkp2QzzYuVVjM8X3JIRXhPzpbW4OVDb9kgvqAQoP3K_thjGcf1Ei8CK90ZV1UvaXs8_N7ZThf3HKYhMC8wj3f3pKXRUtvBvuU%3D"].randomElement()!
        if didFlash?(url) == false {
            showErrorAlert()
        }
    }
    #endif
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func didTouchMoreInfoButton() {
        didTouchMoreInfo?()
    }
}
