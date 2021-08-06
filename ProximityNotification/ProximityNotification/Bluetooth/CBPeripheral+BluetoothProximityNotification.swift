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

extension CBPeripheral: CBPeripheralProtocol {
    
    var shortDescription: String {
        return "[\(identifier.uuidString.prefix(8))]-[\(name ?? "")]-[\(state.description)]"
    }
}
