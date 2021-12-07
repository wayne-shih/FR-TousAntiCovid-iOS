// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DeclareController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/09/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK
import MessageUI

final class DeclareController: CVTableViewController {
    
    private let didTouchFlash: () -> ()
    private let didTouchTap: () -> ()
    private let didTouchShowVideo: (_ url: URL) -> ()
    private let deinitBlock: () -> ()
    
    init(didTouchFlash: @escaping () -> (), didTouchTap: @escaping () -> (), didTouchShowVideo: @escaping (_ url: URL) -> (), deinitBlock: @escaping () -> ()) {
        self.didTouchFlash = didTouchFlash
        self.didTouchTap = didTouchTap
        self.didTouchShowVideo = didTouchShowVideo
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()
        initUI()
        reloadUI()
        addObservers()
        updateBottomBarButton()
    }
    
    deinit {
        removeObservers()
        deinitBlock()
    }
    
    private func updateTitle() {
        bottomButtonContainerController?.title = "declareController.title".localized
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                CVRow(image: Asset.Images.declare.image,
                      xibName: .imageCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                         imageRatio: 375.0 / 116.0))

                if RBManager.shared.isRegistered {
                    CVRow(title: "declareController.message.testedPositive.title".localized,
                          subtitle: "declareController.message.testedPositive.subtitle".localized,
                          buttonTitle: "declareController.codeNotReceived.buttonTitle".localized,
                          xibName: .paragraphCell,
                          theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                             topInset: .zero,
                                             bottomInset: .zero,
                                             textAlignment: .natural,
                                             titleFont: { Appearance.Cell.Text.headTitleFont }),
                          selectionAction: { [weak self] in
                        self?.didTouchCodeNotReceivedButton()
                    })
                } else {
                    CVRow(title: "declareController.notRegistered.mainMessage.title".localized,
                          subtitle: "declareController.notRegistered.mainMessage.subtitle".localized,
                          xibName: .textCell,
                          theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium))
                }
            }
        }
    }
    
    private func initUI() {
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        bottomButtonContainerController?.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        bottomButtonContainerController?.navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }
    
    private func updateBottomBarButton() {
        bottomButtonContainerController?.updateButton(title: "declareController.button.enterCode".localized) { [weak self] in
            self?.showEnterCodeOptions()
            self?.bottomButtonContainerController?.unlockButtons()
        }
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    private func addObservers() {
        LocalizationsManager.shared.addObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(statusDataChanged), name: .statusDataDidChange, object: nil)
    }
    
    private func removeObservers() {
        LocalizationsManager.shared.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    private func showEnterCodeOptions() {
        showActionSheet(title: nil, message: "declareController.enterCodeOptions.title".localized, firstActionTitle: "declareController.button.flash".localized, secondActionTitle: "declareController.button.tap".localized, showCancel: true, firstActionHandler: { [weak self] in
            self?.didTouchFlashButton()
        }) { [weak self] in
            self?.didTouchTapButton()
        }
    }
    
    @objc private func didTouchFlashButton() {
        CameraAuthorizationManager.requestAuthorization { granted, isFirstTimeRequest in
            if granted {
                self.didTouchFlash()
            } else if !isFirstTimeRequest {
                self.showAlert(title: "scanCodeController.camera.authorizationNeeded.title".localized,
                               message: "scanCodeController.camera.authorizationNeeded.message".localized,
                               okTitle: "common.settings".localized,
                               cancelTitle: "common.cancel".localized, handler:  {
                    UIApplication.shared.openSettings()
                })
            }
        }
    }
    
    @objc private func didTouchTapButton() {
        didTouchTap()
    }
    
    @objc private func didTouchCodeNotReceivedButton() {
        let alertController: UIAlertController = UIAlertController(title: "declareController.codeNotReceived.alert.title".localized,
                                                                   message: "declareController.codeNotReceived.alert.message".localized,
                                                                   preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
        alertController.addAction(UIAlertAction(title: "declareController.codeNotReceived.alert.showVideo".localized, style: .default, handler: { [weak self] _ in
            self?.didTouchShowVideo(URL(string: "declareController.codeNotReceived.alert.video.url".localized)!)
        }))
        alertController.addAction(UIAlertAction(title: "declareController.codeNotReceived.alert.contactUs".localized, style: .default, handler: { _ in
            URL(string: "contactUs.url".localized)?.openInSafari()
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func statusDataChanged() {
        reloadUI()
    }

}

extension DeclareController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}

extension DeclareController: MFMailComposeViewControllerDelegate {
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}
