// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AboutController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit
import MessageUI

final class AboutController: CVTableViewController {
    
    private var deinitBlock: (() -> ())?
    
    init(deinitBlock: @escaping () -> ()) {
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }
    
    deinit {
        LocalizationsManager.shared.removeObserver(self)
        deinitBlock?()
    }
    
    private func updateTitle() {
        title = "aboutController.title".localized
    }
    
    private func initUI() {
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                CVRow(image: Asset.Images.logo.image,
                      xibName: .onboardingImageCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                         imageRatio: Appearance.Cell.Image.defaultRatio))
                CVRow(title: "app.name".localized,
                      subtitle: String(format: "aboutController.appVersion".localized, UIApplication.shared.marketingVersion, UIApplication.shared.buildNumber),
                      xibName: .textCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                         separatorLeftInset: nil)
                )
                CVRow(title: "aboutController.mainMessage.title".localized,
                      subtitle: "aboutController.mainMessage.subtitle".localized,
                      xibName: .standardCardCell,
                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                         topInset: Appearance.Cell.Inset.extraLarge,
                                         bottomInset: Appearance.Cell.Inset.medium,
                                         textAlignment: .natural,
                                         titleFont: { Appearance.Cell.Text.smallHeadTitleFont },
                                         separatorLeftInset: nil)
                )
            }
            actionsSection()
        }
    }
    
    private func actionsSection() -> CVSection {
        let menuEntries: [GroupedMenuEntry] = [GroupedMenuEntry(image: Asset.Images.contact.image,
                                                                title: "aboutController.contactUsByEmail".localized,
                                                                actionBlock: {
            URL(string: "contactUs.url".localized)?.openInSafari()
        }),
                                               GroupedMenuEntry(image: Asset.Images.faq.image,
                                                                title: "aboutController.faq".localized,
                                                                actionBlock: {
            URL(string: "aboutController.faqUrl".localized)?.openInSafari()
        }),
                                               GroupedMenuEntry(image: Asset.Images.opinion.image,
                                                                title: "aboutController.opinion".localized,
                                                                actionBlock: {
            URL(string: "aboutController.opinionUrl".localized)?.openInSafari()
        }),
                                               GroupedMenuEntry(image: Asset.Images.moreInfo.image,
                                                                title: "aboutController.webpage".localized,
                                                                actionBlock: {
            URL(string: "aboutController.webpageUrl".localized)?.openInSafari()
        })]
        return CVSection(rows: menuEntries.toMenuRows())
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
}

extension AboutController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}

extension AboutController: MFMailComposeViewControllerDelegate {
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}
