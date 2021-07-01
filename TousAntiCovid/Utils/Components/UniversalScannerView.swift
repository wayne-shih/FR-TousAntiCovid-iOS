// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UniversalScannerView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/03/2021 - for the TousAntiCovid project.
//

import Foundation
import AVFoundation

final class UniversalScannerView: QRScannerView {

    override var objectTypes: [AVMetadataObject.ObjectType] { [.dataMatrix, .qr] }

}
