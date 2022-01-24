// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  QRCodeCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 04/05/2020 - for the TousAntiCovid project.
//

import UIKit

final class QRCodeCell: CardCell {

    @IBOutlet private var topRightButton: UIButton!

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupAccessibility()
    }
    
    override func capture() -> UIImage? {
        topRightButton.isHidden = true
        let image: UIImage? = containerView.cvScreenshot()
        topRightButton.isHidden = false
        return image
    }
    
    private func setupUI() {
        topRightButton.tintColor = Appearance.tintColor
    }
    
    override func setupAccessibility() {
        super.setupAccessibility()
        containerView?.accessibilityLabel = ["common.qrcode".localized,
                                             "accessibility.fullscreen.activate".localized,
                                             containerView?.accessibilityLabel].compactMap { $0 }.joined(separator: "\n").removingEmojis()

        topRightButton.accessibilityLabel = "accessibility.menu.moreoptions".localized
        topRightButton.isAccessibilityElement = !topRightButton.isHidden

        accessibilityElements = [containerView, topRightButton].compactMap { $0 }
    }
    
    @IBAction private func topRightButtonPressed(_ sender: Any) {
        currentAssociatedRow?.selectionActionWithCell?(self)
    }    
}
