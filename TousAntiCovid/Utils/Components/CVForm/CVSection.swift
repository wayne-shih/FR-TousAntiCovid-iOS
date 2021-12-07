// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVSection.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 05/10/2021 - for the TousAntiCovid project.
//

struct CVSection {
    
    private(set) var rows: [CVRow]
    private(set) var header: CVFooterHeaderSection? = nil
    private(set) var footer: CVFooterHeaderSection? = nil
    private(set) var willDisplay: ((_ headerView: CVHeaderFooterSectionView) -> ())?

    init(title: String? = nil, subtitle: String? = nil, footerTitle: String? = nil, rows: [CVRow], willDisplay: ((_ headerView: CVHeaderFooterSectionView) -> ())? = nil, willDisplayFooter: ((_ footerView: CVHeaderFooterSectionView) -> ())? = nil) {
        self.rows = rows
        if title != nil || subtitle != nil {
            header = CVFooterHeaderSection(title: title, subtitle: subtitle)
        }
        if footerTitle != nil {
            footer = CVFooterHeaderSection.footer(title: footerTitle)
        }
        header?.willDisplay = willDisplay
        footer?.willDisplay = willDisplayFooter
    }

    init(header: CVFooterHeaderSection? = nil, rows: [CVRow]) {
        self.header = header
        self.rows = rows
    }

    init(title: String? = nil, subtitle: String? = nil, footerTitle: String? = nil, willDisplay: ((_ headerView: CVHeaderFooterSectionView) -> ())? = nil, willDisplayFooter: ((_ footerView: CVHeaderFooterSectionView) -> ())? = nil, @CVRowsBuilder rowsBuilder: () -> [CVRow]) {
        self.rows = rowsBuilder()
        if title != nil || subtitle != nil {
            header = CVFooterHeaderSection(title: title, subtitle: subtitle)
        }
        if footerTitle != nil {
            footer = CVFooterHeaderSection(title: footerTitle, subtitle: nil)
        }
        header?.willDisplay = willDisplay
        footer?.willDisplay = willDisplayFooter
    }
    
    init(title: String? = nil, subtitle: String? = nil, footerTitle: String? = nil, @CVRowsBuilder _ content: () -> [CVRow]) {
        self.init(title: title, subtitle: subtitle, footerTitle: footerTitle, rows: content())
    }

    init(@CVRowsBuilder _ content: () -> [CVRow], header headerBuilder: (() -> CVFooterHeaderSection)) {
        self.init(header: headerBuilder(), rows: content())
    }

}
