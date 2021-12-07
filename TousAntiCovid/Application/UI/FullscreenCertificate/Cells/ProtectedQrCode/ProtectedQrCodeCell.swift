// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ProtectedQrCodeCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2021 - for the TousAntiCovid project.
//

import UIKit

final class ProtectedQrCodeCell: CVTableViewCell {
    override var isAccessibilityElement: Bool {
        get { false }
        set { }
    }
    
    override var accessibilityElementsHidden: Bool {
        get { true }
        set { }
    }

    @IBOutlet private var fakeTextField: UITextField?
    private let protectedImageView: UIImageView = UIImageView()

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
    }

    private func setupUI(with row: CVRow) {
        protectedImageView.contentMode = .scaleAspectFit
        protectedImageView.backgroundColor = .white
        protectedImageView.image = row.associatedValue as? UIImage
        fakeTextField?.subviews.first { !($0 is UILabel) }?.addConstrainedSubview(protectedImageView)
    }
}
