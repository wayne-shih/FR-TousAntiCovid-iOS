// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  FlashReportCodeController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class FlashReportCodeController: FlashCodeController {
    
    private var didFlash: ((_ code: String?) -> ())?
    
    class func controller(didFlash: @escaping (_ code: String?) -> (), deinitBlock: (() -> ())? = nil) -> UIViewController {
        let flashCodeController: FlashReportCodeController = StoryboardScene.FlashReportCode.flashCodeController.instantiate()
        flashCodeController.didFlash = didFlash
        flashCodeController.deinitBlock = deinitBlock
        return flashCodeController
    }
    
    override func initUI() {
        super.initUI()
        title = "declareController.button.flash".localized
        explanationLabel.text = "scanCodeController.explanation".localized
        explanationLabel.font = Appearance.Cell.Text.standardFont
        explanationLabel.adjustsFontForContentSizeCategory = true
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
        navigationController?.navigationBar.tintColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }

    override func processScannedQRCode(code: String?) {
        if isValidCode(code: code) == true {
            didFlash?(code)
        } else {
            showAlert(title: "enterCodeController.alert.invalidCode.title".localized,
                      message: "enterCodeController.alert.invalidCode.message".localized,
                      okTitle: "common.ok".localized, handler: {
                        self.restartScanning()
                      })
        }
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    private func isValidCode(code: String?) -> Bool {
        guard let code = code else { return false }
        if let url = URL(string: code), DeepLinkingManager.shared.isComboDeeplink(url) {
            return true
        } else {
            return code.isUuidCode || code.isShortCode || code.contains("/app/code")
        }
    }
    
}
