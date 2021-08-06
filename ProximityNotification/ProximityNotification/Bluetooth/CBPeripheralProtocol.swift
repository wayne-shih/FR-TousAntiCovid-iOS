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

protocol CBPeripheralProtocol: AnyObject {

    var delegate: CBPeripheralDelegate? { get set }

    var identifier: UUID { get }

    var name: String? { get }

    var state: CBPeripheralState { get }

    var services: [CBService]? { get }

    var shortDescription: String { get }

    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)

    func readValue(for characteristic: CBCharacteristic)
}
