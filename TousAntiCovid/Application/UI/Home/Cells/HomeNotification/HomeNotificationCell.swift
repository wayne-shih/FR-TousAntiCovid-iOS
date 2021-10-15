// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  HomeNotificationCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/10/2021 - for the TousAntiCovid project.
//

import UIKit

final class HomeNotificationCell: CardCell {
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var closeImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupButton()
        setupShadow()
    }
    
    @IBAction private func closeButtonPressed(_ sender: Any) {
        currentAssociatedRow?.secondarySelectionAction?()
    }
}

private extension HomeNotificationCell {
    func setupButton() {
        closeImageView.tintColor = Appearance.tintColor
    }
    
    func setupShadow() {
        contentView.layer.shadowColor = Appearance.defaultShadowColor.cgColor
        if #available(iOS 13.0, *) {
            contentView.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.5 : 0.3
        } else {
            contentView.layer.shadowOpacity = 0.3
        }
        contentView.layer.shadowOffset = .zero
        contentView.layer.shadowRadius = 4
    }
}
