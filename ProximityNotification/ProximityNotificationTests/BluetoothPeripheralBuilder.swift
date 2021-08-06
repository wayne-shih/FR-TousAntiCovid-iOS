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
@testable import ProximityNotification
import XCTest

class BluetoothPeripheralBuilder {

    func proximityPayload(from name: String) -> ProximityPayload? {
        guard let nameData = name.data(using: .utf8) else { return nil }

        let data = nameData.prefix(ProximityPayload.byteCount) + Data(count: max(ProximityPayload.byteCount - nameData.count, 0))

        return ProximityPayload(data: data)
    }

    @discardableResult
    func addPeripheral(withName name: String,
                       operatingSystem: BluetoothPeripheral.OperatingSystem,
                       state: CBPeripheralState,
                       in bluetoothPeripheralDataStore: BluetoothPeripheralDataStore) -> BluetoothPeripheral {
        let peripheral = CBPeripheralMock(state: state)
        let bluetoothPeripheral = bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral, operatingSystem: operatingSystem)

        if operatingSystem == .android {
            setPayload(from: name, for: bluetoothPeripheral)
        }

        if state == .connected && operatingSystem == .iOS {
            setPayload(from: name, for: bluetoothPeripheral)
        }

        return bluetoothPeripheral
    }

    func setPayload(from name: String, for bluetoothPeripheral: BluetoothPeripheral?) {
        let proximityPayload = self.proximityPayload(from: name)
        XCTAssertNotNil(proximityPayload)
        bluetoothPeripheral?.bluetoothProximityPayload = BluetoothProximityPayload(payload: proximityPayload!, txPowerLevel: 12)
    }
}
