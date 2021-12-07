// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  TousAntiCovidWidgets.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

@main
struct TousAntiCovidWidgets: WidgetBundle {

    @WidgetBundleBuilder
    var body: some Widget {
        StatusWidget()
        DccWidget()
        AlwaysOnDccWidget()
    }

}
