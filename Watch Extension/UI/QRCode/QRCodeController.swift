// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  QRCodeController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 05/08/2021 - for the TousAntiCovid project.
//

import WatchKit
import SwiftUI

final class QRCodeController: WKHostingController<QRCodeView> {

    var qrCodeData: Data?

    override var body: QRCodeView {
        QRCodeView(qrCodeData: qrCodeData ?? Data())
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        qrCodeData = context as? Data
    }

}
