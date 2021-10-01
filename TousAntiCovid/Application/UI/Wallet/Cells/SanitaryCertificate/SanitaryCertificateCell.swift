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

final class SanitaryCertificateCell: CardCell {

    @IBOutlet private var favoriteButton: UIButton!
    @IBOutlet private var topRightButton: UIButton!
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
        guard let certificate = row.associatedValue as? WalletCertificate, !certificate.pillTitles.isEmpty else {
            tagListView.isHidden = true
            return
        }
        tagListView.isHidden = false
        certificate.pillTitles.forEach {
            let tag: TagView = tagListView.addTag($0.text)
            tag.tagBackgroundColor = $0.backgroundColor
            tag.textColor = Appearance.Button.Primary.titleColor
        }
        tagListView.isAccessibilityElement = !(tagListView?.isHidden ?? true)
        tagListView.accessibilityTraits = .staticText
        tagListView.accessibilityLabel = row.accessoryText
        tagListView.tagViews.forEach { $0.isAccessibilityElement = false }
        favoriteButton.setImage(row.isOn == true ? Asset.Images.filledHeart.image : Asset.Images.emptyHeart.image, for: .normal)
        layoutSubviews()
    }

    override func setupAccessibility() {}

    private func setupAccessibility(with row: CVRow) {
        let imageType: String?
        switch (row.associatedValue as? WalletCertificate)?.type.format {
        case .wallet2DDoc:
            imageType = "common.2ddoc".localized
        case .walletDCC, .walletDCCACT:
            imageType = "common.qrcode".localized
        case .none:
            imageType = nil
        }

        accessibilityLabel = [imageType, "accessibility.fullscreen.activate".localized, cvTitleLabel?.text, row.segmentsTitles?.joined() ?? "", cvSubtitleLabel?.text, cvAccessoryLabel?.text].compactMap { $0 }.joined(separator: ".\n").removingEmojis()
        accessibilityTraits = .button
        isAccessibilityElement = true
        accessibilityElements = []

        cvTitleLabel?.isAccessibilityElement = false
        cvSubtitleLabel?.isAccessibilityElement = false
        tagListView?.isAccessibilityElement = false
        cvImageView?.isAccessibilityElement = false
    }

    @IBAction private func favoriteButtonPressed(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentAssociatedRow?.secondarySelectionAction?()
    }

    @IBAction private func topRightButtonPressed(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentAssociatedRow?.selectionActionWithCell?(self)
    }
    
}
