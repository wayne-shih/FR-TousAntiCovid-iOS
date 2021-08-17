// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  InfoCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit
import TagListView

final class InfoCell: CardCell {
    
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var tagListView: TagListView!
    @IBOutlet private var button: UIButton!
    @IBOutlet private var sharingImageView: UIImageView!
    @IBOutlet private var sharingButton: UIButton!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
        setupContent(with: row)
        setupAccessibility(with: row)
    }
    
    private func setupUI(with row: CVRow) {
        dateLabel.font = Appearance.Cell.Text.captionTitleFont
        dateLabel.textColor = Appearance.Cell.Text.captionTitleColor
        tagListView.textFont = Appearance.Tag.font
        tagListView.alignment = .left
        tagListView.paddingX = 10.0
        tagListView.paddingY = 5.0
        tagListView.marginX = 6.0
        tagListView.marginY = 6.0
        tagListView.isUserInteractionEnabled = false
        tagListView.backgroundColor = .clear
        cvSubtitleLabel?.font = Appearance.Cell.Text.subtitleFont
        button?.tintColor = Appearance.Button.Tertiary.titleColor
        button?.titleLabel?.font = Appearance.Button.linkFont
        button?.titleLabel?.adjustsFontForContentSizeCategory = true
        sharingImageView.tintColor = Appearance.tintColor
        sharingImageView.image = Asset.Images.shareIcon.image

        if let subtitle = row.subtitle, subtitle.contains("\n\n")  {
            let range: NSRange = (subtitle as NSString).range(of: "\n\n")
            let boldRange: NSRange = NSRange(location: 0, length: range.location)
            let attributedText: NSMutableAttributedString = NSMutableAttributedString(string: subtitle, attributes: [.foregroundColor: row.theme.subtitleColor,
                                                                                                                     .font: row.theme.subtitleFont()])
            attributedText.addAttributes([.foregroundColor: row.theme.titleHighlightColor, .font: row.theme.titleHighlightFont()], range: boldRange)
            cvSubtitleLabel?.attributedText = attributedText
        }
    }

    override func capture() -> UIImage? {
        sharingImageView.isHidden = true
        let image: UIImage? = containerView.screenshot()
        sharingImageView.isHidden = false
        return image
    }
    
    private func setupContent(with row: CVRow) {
        dateLabel.text = row.accessoryText
        if #available(iOS 13.0, *) {
            let imageAttachment: NSTextAttachment = NSTextAttachment()
            imageAttachment.image = UIImage(systemName: "arrow.up.right.square.fill")?.withRenderingMode(.alwaysTemplate)
            let fullString: NSMutableAttributedString = NSMutableAttributedString(string: "\(row.buttonTitle ?? "") ")
            fullString.append(NSAttributedString(attachment: imageAttachment))
            button.setAttributedTitle(fullString, for: .normal)
        } else {
            button.setTitle(row.buttonTitle, for: .normal)
        }
        button.isHidden = row.buttonTitle?.isEmpty != false
        guard let info = row.associatedValue as? Info else {
            tagListView.isHidden = true
            return
        }
        tagListView.isHidden = info.tags.isEmpty
        tagListView.removeAllTags()
        info.tags.forEach {
            let tag: TagView = tagListView.addTag($0.label)
            tag.backgroundColor = $0.color
        }
        tagListView.isAccessibilityElement = !(tagListView?.isHidden ?? true)
        tagListView.accessibilityTraits = .staticText
        tagListView.accessibilityLabel = info.tags.map { $0.label }.joined(separator: ", ")
        tagListView.tagViews.forEach { $0.isAccessibilityElement = false }
        layoutSubviews()
    }
    
    private func setupAccessibility(with row: CVRow) {
        guard let info = row.associatedValue as? Info else { return }
        accessibilityElements = [dateLabel,
                                 cvTitleLabel,
                                 tagListView,
                                 cvSubtitleLabel,
                                 sharingButton,
                                 button].compactMap { $0 }
        button.accessibilityLabel = row.buttonTitle
        button.isAccessibilityElement = info.buttonLabel?.isEmpty == false
        dateLabel.isAccessibilityElement = true
        cvTitleLabel?.isAccessibilityElement = true
        cvSubtitleLabel?.isAccessibilityElement = true
        tagListView.isAccessibilityElement = true
        sharingButton.isAccessibilityElement = true
        sharingButton.accessibilityLabel = "accessibility.hint.info.share".localized
        let date: Date = Date(timeIntervalSince1970: Double(info.timestamp))
        dateLabel.accessibilityLabel = date.accessibilityRelativelyFormattedDate()
    }
    
    @IBAction private func buttonPressed(_ sender: Any) {
        currentAssociatedRow?.secondarySelectionAction?()
    }
    
    @IBAction private func didTouchSharingButton(_ sender: Any) {
        currentAssociatedRow?.selectionActionWithCell?(self)
    }
    
}
