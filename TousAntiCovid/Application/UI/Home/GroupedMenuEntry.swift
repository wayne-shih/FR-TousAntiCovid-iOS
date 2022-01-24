// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  GroupedMenuEntry.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 06/11/2020 - for the TousAntiCovid project.
//

import UIKit

struct GroupedMenuEntry: Equatable {

    let image: UIImage?
    let title: String
    let subtitle: String?
    let actionBlock: () -> ()
    
    init(image: UIImage?, title: String, subtitle: String? = nil, actionBlock: @escaping () -> ()) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.actionBlock = actionBlock
    }

    static func == (lhs: GroupedMenuEntry, rhs: GroupedMenuEntry) -> Bool {
        lhs.title == rhs.title
    }
    
}

extension Array where Element == GroupedMenuEntry {
    func toMenuRows() -> [CVRow] {
        let rows: [CVRow] = self.map {
            var row: CVRow = .standardCardMenuRow(title: $0.title, image: $0.image, actionBlock: $0.actionBlock)
            if $0 == self.first {
                row.theme.maskedCorners = .top
                row.theme.separatorLeftInset = 2 * Appearance.Cell.leftMargin
                row.theme.separatorRightInset = Appearance.Cell.leftMargin
            } else if $0 == self.last {
                row.theme.maskedCorners = .bottom
            } else {
                row.theme.maskedCorners = .none
                row.theme.separatorLeftInset = 2 * Appearance.Cell.leftMargin
                row.theme.separatorRightInset = Appearance.Cell.leftMargin
            }
            return row
        }
        return rows
    }
}

private extension CVRow {
    static func standardCardMenuRow(title: String, subtitle: String? = nil, image: UIImage?, actionBlock: @escaping () -> ()) -> CVRow {
        let row: CVRow = CVRow(title: title,
                               subtitle: subtitle,
                               image: image,
                               xibName: .standardCardCell,
                               theme:  CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                   topInset: .zero,
                                                   bottomInset: .zero,
                                                   textAlignment: .natural,
                                                   titleFont: { Appearance.Cell.Text.standardFont },
                                                   titleColor: Appearance.Cell.Text.headerTitleColor,
                                                   imageTintColor: Appearance.Cell.Text.headerTitleColor,
                                                   imageSize: CGSize(width: 24.0, height: 24.0)),
                               selectionAction: { _ in
            actionBlock()
        })
        return row
    }
}
