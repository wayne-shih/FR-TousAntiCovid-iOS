// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  HomeNotification+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 11/10/2021 - for the TousAntiCovid project.
//

import ServerSDK

extension HomeNotification {    
    var title: String? { titleKey.localizedOrEmpty.isEmpty ? nil : titleKey.localized }
    var subtitle: String? { subtitleKey.localizedOrEmpty.isEmpty ? nil : subtitleKey.localized }
    var url: URL? {
        guard let urlStr = urlStringKey.localizedOrNil else { return nil }
        return URL(string: urlStr)
    }
    
    var hasContent: Bool { title != nil && subtitle != nil && url != nil }
}
