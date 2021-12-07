// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVFooterHeaderSection.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 05/10/2021 - for the TousAntiCovid project.
//

import UIKit

struct CVFooterHeaderSection {

    static var groupedHeader: CVFooterHeaderSection {
        var header: CVFooterHeaderSection = CVFooterHeaderSection()
        header.theme.topInset = Appearance.Header.topMargin
        header.theme.bottomInset = .zero
        return header
    }
    
    static func footer(title: String?) -> CVFooterHeaderSection {
        var footer: CVFooterHeaderSection = CVFooterHeaderSection(title: title)
        footer.theme.topInset = Appearance.Footer.topMargin
        footer.theme.bottomInset = .zero
        footer.theme.rightInset = Appearance.Cell.Inset.medium
        footer.theme.leftInset = Appearance.Cell.Inset.medium
        footer.theme.titleFont = { Appearance.Cell.Text.footerFont }
        footer.theme.titleColor = .darkGray
        return footer
    }

    struct Theme {
        var backgroundColor: UIColor = Appearance.Controller.cardTableViewBackgroundColor
        var topInset: CGFloat = Appearance.Header.topMargin
        var bottomInset: CGFloat = Appearance.Header.bottomMargin
        var leftInset: CGFloat = Appearance.Header.leftMargin
        var rightInset: CGFloat = Appearance.Header.rightMargin
        var textAlignment: NSTextAlignment = .natural
        var titleFont: (() -> UIFont) = { Appearance.Cell.Text.headTitleFont }
        var titleColor: UIColor = Appearance.Cell.Text.titleColor
        var subtitleFont: (() -> UIFont) = { Appearance.Cell.Text.subtitleFont }
        var subtitleColor: UIColor = Appearance.Cell.Text.subtitleColor
    }

    var title: String?
    var subtitle: String?
    var xibName: XibName.Section = .standardSectionHeader
    var theme: Theme = Theme()
    var willDisplay: ((_ view: CVHeaderFooterSectionView) -> ())?

}
