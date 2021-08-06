// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SanitaryCertificateCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 04/05/2020 - for the TousAntiCovid project.
//

import UIKit
import TagListView

final class SanitaryCertificateCell: CVTableViewCell {

    @IBOutlet private var favoriteButton: UIButton!
    @IBOutlet private var topRightButton: UIButton!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var tagListView: TagListView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
        setupContent(with: row)
        setupAccessibility(with: row)
    }
    
    override func capture() -> UIImage? {
        topRightButton.isHidden = true
        let cellImage: UIImage? = containerView.screenshot()
        topRightButton.isHidden = false
        guard let image = cellImage else { return nil }
        let imageView: UIImageView = UIImageView(image: image)
        imageView.frame.size = image.size
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = containerView.backgroundColor
        return imageView.screenshot()
    }
    
    private func setupUI(with row: CVRow) {
        selectionStyle = .none
        accessoryType = .none
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        containerView.layer.cornerRadius = 10.0
        containerView.layer.maskedCorners = row.theme.maskedCorners
        containerView.layer.masksToBounds = true
        topRightButton.tintColor = Appearance.tintColor
        favoriteButton.tintColor = Appearance.tintColor
        favoriteButton.isHidden = row.secondarySelectionAction == nil
        tagListView.textFont = Appearance.Tag.font2
        tagListView.alignment = .center
        tagListView.paddingX = 10.0
        tagListView.paddingY = 5.0
        tagListView.marginY = 6.0
        tagListView.isUserInteractionEnabled = false
        tagListView.backgroundColor = .clear
    }
    
    private func setupContent(with row: CVRow) {
        tagListView.removeAllTags()
        guard let texts = row.segmentsTitles else {
            tagListView.isHidden = true
            return
        }
        tagListView.isHidden = false
        texts.forEach {
            let tag: TagView = tagListView.addTag($0)
            tag.tagBackgroundColor = Appearance.tintColor
            tag.textColor = Appearance.Button.Primary.titleColor
        }
        tagListView.isAccessibilityElement = true
        tagListView.accessibilityTraits = .staticText
        tagListView.accessibilityLabel = row.accessoryText
        tagListView.tagViews.forEach { $0.isAccessibilityElement = false }
        favoriteButton.setImage(row.isOn == true ? Asset.Images.filledHeart.image : Asset.Images.emptyHeart.image, for: .normal)
        layoutSubviews()
    }
    
    private func setupAccessibility(with row: CVRow) {
        containerView?.accessibilityLabel = "\(row.title?.removingEmojis() ?? "") \(row.segmentsTitles?.joined() ?? "") \(row.subtitle?.removingEmojis() ?? "")"
        containerView?.accessibilityTraits = .staticText
        containerView?.isAccessibilityElement = true
        topRightButton.accessibilityLabel = "\("walletController.menu.share".localized), \("walletController.menu.delete".localized)"
        topRightButton?.accessibilityTraits = .button
        topRightButton?.isAccessibilityElement = true
        favoriteButton.accessibilityLabel = "accessibility.wallet.dcc.favorite.\(row.isOn == true ? "remove": "define")".localized
        favoriteButton?.accessibilityTraits = .button
        favoriteButton?.isAccessibilityElement = true

        cvTitleLabel?.isAccessibilityElement = false
        cvSubtitleLabel?.isAccessibilityElement = false
        tagListView?.isAccessibilityElement = false
        cvImageView?.isAccessibilityElement = false

        accessibilityElements = [containerView, favoriteButton, topRightButton].compactMap { $0 }
    }

    @IBAction private func favoriteButtonPressed(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentAssociatedRow?.secondarySelectionAction?()
    }

    @IBAction private func topRightButtonPressed(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentAssociatedRow?.selectionActionWithCell?(self)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard currentAssociatedRow?.selectionAction != nil else { return }
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            contentView.layer.removeAllAnimations()
            contentView.alpha = 0.6
        } else {
            UIView.animate(withDuration: 0.3) {
                self.contentView.alpha = 1.0
            }
        }
    }
    
}
