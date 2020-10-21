// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WidgetContent.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import Foundation
import WidgetKit

struct WidgetContent: TimelineEntry, Codable {
    var date: Date = Date()
    var isProximityActivated: Bool
    var isAtRisk: Bool
    var isSick: Bool
    var lastStatusReceivedDate: Date?
}
