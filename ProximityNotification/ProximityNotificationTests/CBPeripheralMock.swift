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
@testable import ProximityNotification

class CBPeripheralMock: CBPeripheralProtocol {

    weak var delegate: CBPeripheralDelegate?

    var identifier: UUID

    var name: String?

    var state: CBPeripheralState

    var services: [CBService]?

    var shortDescription: String {
        return "[\(identifier.uuidString.prefix(8))]-[\(name ?? "")]-[\(state.description)]"
    }

    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {}

    func readValue(for characteristic: CBCharacteristic) {}

    init(identifier: UUID = UUID(), state: CBPeripheralState) {
        self.identifier = identifier
        self.state = state
    }
}

extension CBPeripheralMock: Equatable {

    static func == (lhs: CBPeripheralMock, rhs: CBPeripheralMock) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
