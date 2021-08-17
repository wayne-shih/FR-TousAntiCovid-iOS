// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DccWidgetContent.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/07/2021 - for the TousAntiCovid project.
//

import Foundation
import WidgetKit
import UIKit

struct DccWidgetContent: TimelineEntry {
    var date: Date = Date()
    var certificateQRCodeData: Data?
    var noCertificatText: String
    var bottomText: String
}
