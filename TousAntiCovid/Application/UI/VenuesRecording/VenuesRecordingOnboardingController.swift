// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesRecordingOnboardingController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/11/2020 - for the TousAntiCovid project.
//

import UIKit

final class VenuesRecordingOnboardingController: CVTableViewController {

    private let didContinue: () -> ()
    private let deinitBlock: () -> ()

    init(didContinue: @escaping () -> (), deinitBlock: @escaping () -> ()) {
        self.didContinue = didContinue
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bottomButtonContainerController?.unlockButtons()
    }

    deinit {
        LocalizationsManager.shared.removeObserver(self)
        deinitBlock()
    }

    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                CVRow(image: Asset.Images.venuesRecording.image,
                      xibName: .onboardingImageCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                         imageRatio: Appearance.Cell.Image.defaultRatio))
                CVRow(title: "venuesRecording.onboardingController.mainMessage.title".localized,
                      subtitle: "venuesRecording.onboardingController.mainMessage.message".localized,
                      xibName: .textCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                         bottomInset: Appearance.Cell.Inset.medium,
                                         textAlignment: .center,
                                         titleFont: { Appearance.Cell.Text.smallHeadTitleFont }))
            }
        }
    }

    private func initUI() {
        bottomButtonContainerController?.title = "venuesRecording.onboardingController.title".localized
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        bottomButtonContainerController?.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        bottomButtonContainerController?.navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized

        bottomButtonContainerController?.updateButton(title: "venuesRecording.onboardingController.button.participate".localized) { [weak self] in
            self?.didContinue()
        }

    }

    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

}

extension VenuesRecordingOnboardingController: LocalizationsChangesObserver {

    func localizationsChanged() {
        reloadUI()
    }

}
