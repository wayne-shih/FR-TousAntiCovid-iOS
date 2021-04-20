// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WalletCertificateVerifiedController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 26/03/2021 - for the TousAntiCovid project.
//

import UIKit

final class WalletCertificateVerifiedController: UIViewController {
    
    @IBOutlet private var bodyLabel: UILabel!
    @IBOutlet private var restartButton: CVButton!
    
    private var certificate: WalletCertificate!
    private var didTouchValidateAnotherProof: (() -> ())?

    static func controller(certificate: WalletCertificate, didTouchValidateAnotherProof: @escaping () -> ()) -> UIViewController {
        let verifiedController: WalletCertificateVerifiedController = StoryboardScene.WalletCertificateVerified.walletCertificateVerifiedController.instantiate()
        verifiedController.certificate = certificate
        verifiedController.didTouchValidateAnotherProof = didTouchValidateAnotherProof
        return verifiedController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupContent()
        LocalizationsManager.shared.addObserver(self)
    }

    deinit {
        LocalizationsManager.shared.removeObserver(self)
    }

    private func setupUI() {
        view.backgroundColor = Asset.Colors.tacBlue.color
        bodyLabel.font = Appearance.Cell.Text.body2
        bodyLabel.textColor = .white
        restartButton.setTitle("walletCertificateVerifiedController.validateAnotherProof".localized, for: .normal)
        restartButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        restartButton.setTitleColor(.white, for: .normal)
        navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont,
                                                                   .foregroundColor: UIColor.white]
    }

    private func setupContent() {
        title = "walletCertificateVerifiedController.title".localized
        bodyLabel.text = certificate.fullDescription
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func restartButtonPressed(_ sender: Any) {
        didTouchValidateAnotherProof?()
    }
    
}

extension WalletCertificateVerifiedController: LocalizationsChangesObserver {

    func localizationsChanged() {
        setupContent()
    }

}
