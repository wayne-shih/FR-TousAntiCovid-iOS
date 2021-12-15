// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  OnboardingGesturesController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class OnboardingGesturesController: OnboardingController {

    override var bottomButtonTitle: String { "onboarding.gesturesController.noted".localized }
    
    override func updateTitle() {
        title = isOpenedFromOnboarding ? "onboarding.gesturesController.title".localized : nil
        super.updateTitle()
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                CVRow.titleRow(title: "onboarding.gesturesController.title".localized) { [weak self] cell in
                    self?.navigationChildController?.updateLabel(titleLabel: cell.cvTitleLabel, containerView: cell)
                }
                CVRow(title: "onboarding.gesturesController.mainMessage.title".localized,
                      xibName: .textCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                         bottomInset: Appearance.Cell.Inset.medium,
                                         textAlignment: .natural,
                                         titleFont: { Appearance.Cell.Text.smallHeadTitleFont }))
                gestures().map { gesture in
                    CVRow(title: gesture.title,
                          image: gesture.image,
                          xibName: .onboardingGestureCell,
                          theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                             bottomInset: Appearance.Cell.Inset.normal,
                                             textAlignment: .natural))
                }
            }
        }
    }
    
    private func gestures() -> [Gesture] {
        return [Gesture(title: "onboarding.gesturesController.gesture7".localized, image: Asset.Images.mask.image),
                Gesture(title: "onboarding.gesturesController.gesture9".localized, image: Asset.Images.airRecycling.image),
                Gesture(title: "onboarding.gesturesController.gesture1".localized, image: Asset.Images.hands.image),
                Gesture(title: "onboarding.gesturesController.gesture4".localized, image: Asset.Images.airCheck.image),
                Gesture(title: "onboarding.gesturesController.gesture6".localized, image: Asset.Images.distance.image),
                Gesture(title: "onboarding.gesturesController.gesture2".localized, image: Asset.Images.cough.image),
                Gesture(title: "onboarding.gesturesController.gesture3".localized, image: Asset.Images.tissues.image)]
    }

}
