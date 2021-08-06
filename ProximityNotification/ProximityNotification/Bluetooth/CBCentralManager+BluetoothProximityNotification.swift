/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/12/08 - for the TousAntiCovid project
 */

import CoreBluetooth
import Foundation

extension CBCentralManager {

    func connect(_ peripheral: CBPeripheralProtocol, options: [String: Any]? = nil) {
        if let concretePeripheral = peripheral as? CBPeripheral {
            connect(concretePeripheral, options: options)
        }
    }

    func cancelPeripheralConnection(_ peripheral: CBPeripheralProtocol) {
        if let concretePeripheral = peripheral as? CBPeripheral {
            cancelPeripheralConnection(concretePeripheral)
        }
    }
}
