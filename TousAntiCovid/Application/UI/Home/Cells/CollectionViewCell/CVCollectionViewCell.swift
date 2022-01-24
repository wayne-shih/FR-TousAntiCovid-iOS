// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVCollectionViewCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 22/12/2021 - for the TousAntiCovid project.
//

import UIKit

class CVCollectionViewCell: UICollectionViewCell {
    @IBOutlet private var cvTitleLabel: UILabel?
    @IBOutlet private var cvSubtitleLabel: UILabel?
    @IBOutlet private var leadingConstraint: NSLayoutConstraint?
    @IBOutlet private var trailingConstraint: NSLayoutConstraint?
    @IBOutlet private var topConstraint: NSLayoutConstraint?
    @IBOutlet private var bottomConstraint: NSLayoutConstraint?
    
    var currentAssociatedRow: CVRow?
    
    override var isHighlighted: Bool {
        didSet {
            guard currentAssociatedRow?.selectionAction != nil else { return }
            if isHighlighted {
                contentView.layer.removeAllAnimations()
                contentView.alpha = 0.6
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.contentView.alpha = 1.0
                }
            }
        }
    }
    
    func setup(with row: CVRow) {
        currentAssociatedRow = row
        cvTitleLabel?.text = row.title
        cvSubtitleLabel?.text = row.subtitle
        setupTheme(with: row)
        setupAccessibility()
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        var targetSize: CGSize = targetSize
        targetSize.height = CGFloat.greatestFiniteMagnitude
        return super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
    }
    
    func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityLabel = currentAssociatedRow?.title?.removingEmojis()
        accessibilityTraits = currentAssociatedRow?.selectionAction != nil ? .button : .staticText
        
        cvTitleLabel?.isAccessibilityElement = true
        cvTitleLabel?.accessibilityLabel = cvTitleLabel?.text?.removingEmojis()
        cvTitleLabel?.accessibilityTraits = .staticText

        cvSubtitleLabel?.isAccessibilityElement = true
        cvSubtitleLabel?.accessibilityLabel = cvSubtitleLabel?.text?.removingEmojis()
        cvSubtitleLabel?.accessibilityTraits = .staticText
    }
}

private extension CVCollectionViewCell {
    func setupTheme(with row: CVRow) {
        backgroundColor = row.theme.backgroundColor ?? .clear
        
        cvTitleLabel?.isHidden = row.title == nil
        cvTitleLabel?.textAlignment = row.theme.textAlignment
        cvTitleLabel?.adjustsFontForContentSizeCategory = true
        
        if let titleHighlightText = row.titleHighlightText, let title = row.title {
            let range: NSRange = (title as NSString).range(of: titleHighlightText)
            let attributedText: NSMutableAttributedString = NSMutableAttributedString(string: title, attributes: [.foregroundColor: row.theme.titleColor,
                                                                                                                  .font: row.theme.titleFont()])
            attributedText.addAttributes([.foregroundColor: row.theme.titleHighlightColor, .font: row.theme.titleHighlightFont()], range: range)
            cvTitleLabel?.attributedText = attributedText
        } else {
            cvTitleLabel?.font = row.theme.titleFont()
            cvTitleLabel?.textColor = row.theme.titleColor
            cvTitleLabel?.text = row.title
        }
        
        cvSubtitleLabel?.isHidden = row.subtitle == nil
        cvSubtitleLabel?.font = row.theme.subtitleFont()
        cvSubtitleLabel?.textColor = row.theme.subtitleColor
        cvSubtitleLabel?.textAlignment = row.theme.textAlignment
        cvSubtitleLabel?.adjustsFontForContentSizeCategory = true
        
        row.theme.titleLinesCount.map { cvTitleLabel?.numberOfLines = $0 }
        row.theme.subtitleLinesCount.map { cvSubtitleLabel?.numberOfLines = $0 }
        
        leadingConstraint?.constant = row.theme.leftInset ?? 1
        trailingConstraint?.constant = row.theme.rightInset ?? 1
        if let topInset = row.theme.topInset {
            topConstraint?.constant = topInset
        }
        if let bottomInset = row.theme.bottomInset {
            bottomConstraint?.constant = bottomInset
        }
    }
}
