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

    @IBOutlet private var topRightButton: UIButton!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var tagListView: TagListView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupContent(with: row)
        setupAccessibility()
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
    
    private func setupUI() {
        selectionStyle = .none
        accessoryType = .none
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
        topRightButton.tintColor = Appearance.tintColor
        
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
        guard let text = row.accessoryText else {
            tagListView.isHidden = true
            return
        }
        tagListView.isHidden = false
        let tag: TagView = tagListView.addTag(text)
        tag.tagBackgroundColor = Appearance.tintColor
        tag.textColor = Appearance.Button.Primary.titleColor
        tagListView.isAccessibilityElement = true
        tagListView.accessibilityTraits = .staticText
        tagListView.accessibilityLabel = row.accessoryText
        tagListView.tagViews.forEach { $0.isAccessibilityElement = false }
        layoutSubviews()
    }
    
    private func setupAccessibility() {
        accessibilityElements = [cvTitleLabel, topRightButton].compactMap { $0 }
        topRightButton.accessibilityLabel = "walletController.menu.share".localized
    }
    
    @IBAction private func topRightButtonPressed(_ sender: Any) {
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
