// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AlwaysOnAlwaysOnDccWidget.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 22/10/2021 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct AlwaysOnDccWidget: Widget {

    private let kind: String = "fr.gouv.stopcovid.ios.Widget.dccAlwaysOn"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DccProvider()) { entry in
            AlwaysOnDccWidgetView(entry: entry)
        }
        .configurationDisplayName("TousAntiCovid")
        .description(NSLocalizedString("widget.favoriteCertificate.alwaysOn.description", comment: ""))
        .supportedFamilies([.systemLarge])
    }

}
