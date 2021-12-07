// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  OnboardingVenuesController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/11/2020 - for the TousAntiCovid project.
//

import UIKit

final class OnboardingVenuesController: OnboardingController {

    override var bottomButtonTitle: String { "onboarding.venuesController.bottomButton".localized }
    
    override func updateTitle() {
        title = "onboarding.venuesController.title".localized
        super.updateTitle()
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                CVRow.titleRow(title: title) { [weak self] cell in
                    self?.navigationChildController?.updateLabel(titleLabel: cell.cvTitleLabel, containerView: cell)
                }
                CVRow(image: Asset.Images.venuesRecording.image,
                      xibName: .onboardingImageCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                         imageRatio: Appearance.Cell.Image.onboardingControllerRatio))
                CVRow(title: "onboarding.venuesController.mainMessage.title".localized,
                      subtitle: "onboarding.venuesController.mainMessage.subtitle".localized,
                      xibName: .textCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.large,
                                         titleFont: { Appearance.Cell.Text.smallHeadTitleFont }))
            }
        }
    }

}
