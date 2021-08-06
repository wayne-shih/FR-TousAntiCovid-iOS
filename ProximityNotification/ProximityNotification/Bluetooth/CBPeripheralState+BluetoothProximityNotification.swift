/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/11/23 - for the TousAntiCovid project
 */

import CoreBluetooth
import Foundation

extension CBPeripheralState: CustomStringConvertible {

    public var description: String {
        switch self {
        case .connecting : return "CING"
        case .connected: return "CED"
        case .disconnecting: return "DING"
        case .disconnected: return "DED"
        @unknown default:
            return "UNKNOWN"
        }
    }
}
