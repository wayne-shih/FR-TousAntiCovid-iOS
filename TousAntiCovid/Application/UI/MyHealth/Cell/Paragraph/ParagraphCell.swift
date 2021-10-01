// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ParagraphCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class ParagraphCell: CardCell {

    @IBOutlet private var button: UIButton!

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
        setupContent(with: row)
    }

    private func setupUI(with row: CVRow) {
        cvSubtitleLabel?.font = Appearance.Cell.Text.subtitleFont
        button?.contentHorizontalAlignment = row.theme.textAlignment == .center ? .center : .left
        button?.tintColor = Appearance.Button.Tertiary.titleColor
        button?.titleLabel?.font = Appearance.Button.linkFont
        button?.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    private func setupContent(with row: CVRow) {
        if #available(iOS 13.0, *) {
            let imageAttachment: NSTextAttachment = NSTextAttachment()
            imageAttachment.image = UIImage(systemName: "arrow.up.right.square.fill")?.withRenderingMode(.alwaysTemplate)
            let fullString: NSMutableAttributedString = NSMutableAttributedString(string: "\(row.buttonTitle ?? "") ")
            fullString.append(NSAttributedString(attachment: imageAttachment))
            UIView.performWithoutAnimation {
                button.setAttributedTitle(fullString, for: .normal)
                button.isHidden = row.buttonTitle?.isEmpty != false
                button.layoutIfNeeded()
            }
        } else {
            UIView.performWithoutAnimation {
                button.setTitle(row.buttonTitle, for: .normal)
                button.isHidden = row.buttonTitle?.isEmpty != false
                button.layoutIfNeeded()
            }
        }
    }

    @IBAction private func buttonPressed(_ sender: Any) {
        currentAssociatedRow?.selectionAction?()
    }

}
