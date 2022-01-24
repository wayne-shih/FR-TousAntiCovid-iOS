// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureCollectionViewCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 22/12/2021 - for the TousAntiCovid project.
//

import UIKit

final class KeyFigureCollectionViewCell: CardCollectionViewCell {
    @IBOutlet private var placeLabel: UILabel?
    @IBOutlet private var subtitleContainerView: UIView?
    @IBOutlet private var titleContainerView: UIView?
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupTheme(row.theme)
        guard let keyFigure = row.associatedValue as? KeyFigure else { return }
        titleContainerView?.backgroundColor = keyFigure.lightColor.withAlphaComponent(0.8)
        subtitleContainerView?.backgroundColor = keyFigure.lightColor
        let departmentKeyFigure = keyFigure.currentDepartmentSpecificKeyFigure
        placeLabel?.text = departmentKeyFigure?.label
        placeLabel?.isHidden = departmentKeyFigure == nil
    }
    
    override func setupAccessibility() {
        super.setupAccessibility()
        if let row = currentAssociatedRow, let keyFigure = row.associatedValue as? KeyFigure {
            accessibilityLabel = [keyFigure.currentDepartmentSpecificKeyFigure?.label, row.subtitle, row.title].compactMap { $0 }.joined(separator: ":").removingEmojis()
        }
    }
}

// MARK: - Private functions
extension KeyFigureCollectionViewCell {
    func setupTheme(_ theme: CVRow.Theme) {
        placeLabel?.font = Appearance.Cell.Text.subtitleBoldFont
        placeLabel?.textColor = theme.titleColor
        placeLabel?.textAlignment = theme.textAlignment
    }
}

extension CVRow {
    var widthOfTitle: CGFloat? {
        guard let title = title else { return nil }
        return round((title as NSString).size(withAttributes: [NSAttributedString.Key.font: theme.titleFont()]).width) + 8.0
    }
    
    var widthOfSubtitle: CGFloat? {
        guard let subtitle = subtitle else { return nil }
        return round((subtitle as NSString).size(withAttributes: [NSAttributedString.Key.font: theme.subtitleFont()]).width) + 8.0
    }
    
    var width: CGFloat? {
        if let widthOfTitle = widthOfTitle {
            if let widthOfSubtitle = widthOfSubtitle {
                return max(widthOfTitle, widthOfSubtitle)
            } else {
                return widthOfTitle
            }
        } else {
            return widthOfSubtitle
        }
    }
}
