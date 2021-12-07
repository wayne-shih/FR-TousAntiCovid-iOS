// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesRecordingConfirmationController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/11/2020 - for the TousAntiCovid project.
//

import UIKit
import Lottie

final class VenuesRecordingConfirmationController: CVTableViewController {

    private let didFinish: () -> ()

    init(didFinish: @escaping () -> ()) {
        self.didFinish = didFinish
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

    deinit {
        LocalizationsManager.shared.removeObserver(self)
    }

    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                let animation: Animation = Animation.named(UIColor.isDarkMode ? "ERP-Waving" : "ERP-Waving-Dark")!
                CVRow(animation: animation,
                      xibName: .animationCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge))
                CVRow(title: "erp.confirmationMessage.default.title".localized,
                      subtitle: "erp.confirmationMessage.default.message".localized,
                      xibName: .textCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                         bottomInset: Appearance.Cell.Inset.medium,
                                         textAlignment: .center,
                                         titleFont: { Appearance.Controller.titleFont }))
            }
        }
    }

    private func initUI() {
        bottomButtonContainerController?.title = "venuesRecording.confirmationController.title".localized
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        bottomButtonContainerController?.navigationItem.setHidesBackButton(true, animated: false)
        bottomButtonContainerController?.updateButton(title: "common.ok".localized) { [weak self] in
            self?.didFinish()
        }

    }

}

extension VenuesRecordingConfirmationController: LocalizationsChangesObserver {

    func localizationsChanged() {
        reloadUI()
    }

}
