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
        let url: URL = URL(string: Bool.random() ? "https://bonjour.tousanticovid.gouv.fr/app/walletdcc#HC1:6BFOXN%25TSMAHN-HJTK6.Q837FEMYV6NF4LR5+T9YJ1OGIFT2E7V:X9ZLS*4FCV4*XUA2PSGH.+H$NI4L6PUC6VH6ZL4XP:N6ON13:LHNGPF0%25U94OG3W1-N8KK44ZINTICZUIQN*LA%20436IAXPMHQ1*P13W1+ZEAW1OH6TPA-:VH*F/IE%25TE6UG+ZEAT1HQ1BT1VW55NI5K1*TB3:U-1VVS1UU1MX1FTIWMA-RI%20PQVW5/O16%25HAT1Z%25PHOP*SQ%20R1-%25JHQ15SI:TU+MMPZ56Q1ZRR.T1UVI/E2$4JY/K:*KM%25VHLV+3HLS4HBT:KVAWCC%25C3%202NS431TL88F%25DYZQ4H9H-VUU7IS7TRG4PIQJAZGA+1V2:U2E4AO09SOO0BZCWJRU+HA7/NU1QB*B.%20HK/0N87ZWA:667FPTGULTCC4FI5D/KGG1GWYTVXLO1222G+HM3UA6UJ9MN-RB-7RZNNE9325LO-JE8E" :  "https://bonjour.tousanticovid.gouv.fr/app/wallet?v=DC04FR03AV011E791E79L101FRL0PAVOINE%1DL1EUGENE%1DL219081951L3COVID-19%1DL4J07BX03%1DL5MODERNA%1DL6MODERNA%1DL72L82L924032021LATE%1FKWT3FZQ726IFU6RUYD2KLOVYJUS7TMUGRNJNG55DIAN5BTBBM2Q6V3YXGM6YKRZVSD5GZZPY3RH7QNFFW5VZOT5MPULJOJBS7S567IA")!
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
