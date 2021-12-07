// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesInformationController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/05/2021 - for the TousAntiCovid project.
//

import Foundation
import UIKit

class VenuesInformationController: CVTableViewController {

    private let deinitBlock: (() -> ())?
    private let didTouchContinue: (() -> ())?
    
    private var controller: UIViewController { bottomButtonContainerController ?? self }

    init(didTouchContinue: (() -> ())?, deinitBlock: (() -> ())?) {
        self.deinitBlock = deinitBlock
        self.didTouchContinue = didTouchContinue
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        reloadUI()
        updateBottomBarButton()
    }

    deinit {
        deinitBlock?()
    }

    private func initUI() {
        controller.title = "venuesRecording.onboardingController.title".localized
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        controller.navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }

    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    override func createSections() -> [CVSection] {
        makeSections { CVSection { infoRows() } }
    }

    private func infoRows() -> [CVRow] {
        let headerImageRow: CVRow = CVRow(image: Asset.Images.venuesRecording.image,
                                          xibName: .imageCell,
                                          theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                                             imageRatio: 375.0 / 116.0))
        let explanationsRow: CVRow = CVRow(title: "venuesRecording.onboardingController.mainMessage.title".localized,
                                           subtitle: "venuesRecording.onboardingController.mainMessage.message".localized,
                                           xibName: .standardCardCell,
                                           theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                              topInset: .zero,
                                                              bottomInset: .zero,
                                                              textAlignment: .natural,
                                                              titleFont: { Appearance.Cell.Text.headTitleFont }))

        let whenToUseRow: CVRow = CVRow(title: "venuesRecording.whenToUse.title".localized,
                                        subtitle: "venuesRecording.whenToUse.subtitle".localized,
                                        xibName: .standardCardCell,
                                        theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                           topInset: Appearance.Cell.Inset.normal,
                                                           bottomInset: .zero,
                                                           textAlignment: .natural,
                                                           titleFont: { Appearance.Cell.Text.headTitleFont }))
        let alertRow: CVRow = CVRow(title: "venuesRecording.alert.title".localized,
                                        subtitle: "venuesRecording.alert.subtitle".localized,
                                        xibName: .standardCardCell,
                                        theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                           topInset: Appearance.Cell.Inset.normal,
                                                           bottomInset: .zero,
                                                           textAlignment: .natural,
                                                           titleFont: { Appearance.Cell.Text.headTitleFont }))
        let phoneRow: CVRow = CVRow(title: "walletController.phone.title".localized,
                                    subtitle: "walletController.phone.subtitle".localized,
                                    image: Asset.Images.walletPhone.image,
                                    xibName: .phoneCell,
                                    theme: CVRow.Theme(backgroundColor: Asset.Colors.secondaryButtonBackground.color,
                                                       topInset: Appearance.Cell.Inset.normal,
                                                       bottomInset: .zero,
                                                       textAlignment: .natural,
                                                       titleFont: { Appearance.Cell.Text.smallHeadTitleFont },
                                                       subtitleFont: { Appearance.Cell.Text.accessoryFont }),
                                    selectionAction: { [weak self] in
                                        guard let self = self else { return }
                                        "walletController.phone.number".localized.callPhoneNumber(from: self)
                                    })
        return [headerImageRow,
                explanationsRow,
                whenToUseRow,
                alertRow,
                phoneRow]
    }
    
    private func updateBottomBarButton() {
        bottomButtonContainerController?.updateButton(title: "venuesRecording.onboardingController.button.participate".localized) { [weak self] in
            self?.dismiss(animated: true) { [weak self] in
                self?.didTouchContinue?()
            }
        }
    }

}
