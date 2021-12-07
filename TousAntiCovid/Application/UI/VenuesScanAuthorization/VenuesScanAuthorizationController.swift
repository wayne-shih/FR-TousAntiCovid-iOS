// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesScanAuthorizationController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 13/01/2021 - for the TousAntiCovid project.
//

import UIKit

final class VenuesScanAuthorizationController: CVTableViewController {

    private let didAnswer: (_ granted: Bool) -> ()

    init(didAnswer: @escaping (_ granted: Bool) -> ()) {
        self.didAnswer = didAnswer
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
        LocalizationsManager.shared.addObserver(self)
    }

    deinit {
        LocalizationsManager.shared.removeObserver(self)
    }
    
    private func initUI() {
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
    }
    
    private func updateTitle() {
        title = "confirmVenueQrCodeController.title".localized
    }

    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                CVRow(image: Asset.Images.venuesRecording.image,
                      xibName: .onboardingImageCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                         imageRatio: Appearance.Cell.Image.defaultRatio))
                CVRow(title: "confirmVenueQrCodeController.explanation.title".localized,
                      xibName: .textCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                         bottomInset: Appearance.Cell.Inset.small,
                                         textAlignment: .center,
                                         titleFont: { Appearance.Cell.Text.standardFont }))
                CVRow(title: "confirmVenueQrCodeController.explanation.subtitle".localized,
                      xibName: .textCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.small,
                                         bottomInset: Appearance.Cell.Inset.medium,
                                         textAlignment: .center))
                CVRow(title: "confirmVenueQrCodeController.confirm".localized,
                      xibName: .buttonCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                         bottomInset: Appearance.Cell.Inset.small),
                      selectionAction: { [weak self] in
                    self?.didAnswer(true)
                })
                CVRow(title: "common.cancel".localized,
                      xibName: .buttonCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.small,
                                         bottomInset: .zero,
                                         buttonStyle: .destructive),
                      selectionAction: { [weak self] in
                    self?.didAnswer(false)
                })
            }
        }
    }

}

extension VenuesScanAuthorizationController: LocalizationsChangesObserver {

    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }

}
