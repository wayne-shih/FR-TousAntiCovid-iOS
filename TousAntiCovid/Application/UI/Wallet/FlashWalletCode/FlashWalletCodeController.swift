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
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        if navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
            navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
        }
        #if targetEnvironment(simulator)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Flash", style: .plain, target: self, action: #selector(didTouchFlashButton))
        #endif
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
    
    #if targetEnvironment(simulator)
    @objc private func didTouchFlashButton() {
        let url: URL = URL(string: "https://bonjour.tousanticovid.gouv.fr/app/walletdcc#HC1:NCFOXN%25TS3DHA%20SA6K85KFI60INA.Q/R8LF62FCKSU3*5I9C2L96LHC%20CZIE%25OM:UC*GPXS40%20LHZATG91PC/.DV2MGDIK3MXGG%20HGMJKB%25GLIA-D8+6JDJN%20XGUEERH9P1JXGGO.KKHG%203MRB8-JEY7A1JAA/CQ.CXCI*ZAVDJ.6LDDJU*INCIL7JRIK:BG26H-GFU4HLEKTSFS-K.-KYUJUECYJM.IA.C8KRDL4O54O4IGUJKPGGYIA%20GEMSH:8E3DE0OA0D9E2LBHHGKLO-K%25FGSKE%20MCTPI8%25MLPIY10UBR:34C3CS03K34XAPFZMXUAM.SY$NIS9N1B%2518J40T8AI%25KIR7./8T%20OG%255TW5A%206%20O6$L69/9L:9EMN*886EO-CRH76.JKTFNK%25C1MD:XERASU%25KBSIPPH88J2PM%20RJLAWQ0GU$CH6H.7LVNTO8B5+M5AVF%20BCXT*$8*GJSCRSKGX5HOLI.N1N-RZPE6PRY7O.40Z-A74")!
        do {
            try didFlash?(url)
        } catch {
            didGetCertificateError?(url.absoluteString, error)
        }
    }
    #endif
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func didTouchBottomButton(_ sender: Any) {
        URL(string: "flashWalletCodeController.footer.link.ios".localized)?.openInSafari()
    }

}
