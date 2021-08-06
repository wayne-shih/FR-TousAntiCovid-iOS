/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/11/16 - for the TousAntiCovid project
 */

import Foundation

class BluetoothPeripheralDataStore {

    var bluetoothPeripherals: [BluetoothPeripheral] {
        bluetoothPeripheralForPeripheralIdentifier.map { $0.1 }
    }
    
    private let settings: BluetoothSettings

    private var bluetoothPeripheralForPeripheralIdentifier = [UUID: BluetoothPeripheral]()

    init(settings: BluetoothSettings) {
        self.settings = settings
    }

    func bluetoothPeripheral(for peripheral: CBPeripheralProtocol) -> BluetoothPeripheral? {
        return bluetoothPeripheralForPeripheralIdentifier[peripheral.identifier]
    }

    func bluetoothPeripheral(forPeripheralIdentifier peripheralIdentifier: UUID) -> BluetoothPeripheral? {
        return bluetoothPeripheralForPeripheralIdentifier[peripheralIdentifier]
    }

    @discardableResult
    func addBluetoothPeripheral(from peripheral: CBPeripheralProtocol, bluetoothProximityPayload: BluetoothProximityPayload?) -> BluetoothPeripheral {
        let operatingSystem: BluetoothPeripheral.OperatingSystem = bluetoothProximityPayload != nil ? .android : .iOS
        let bluetoothPeripheral = addBluetoothPeripheral(from: peripheral, operatingSystem: operatingSystem)
        bluetoothPeripheral.bluetoothProximityPayload = bluetoothProximityPayload

        return bluetoothPeripheral
    }

    @discardableResult
    func addBluetoothPeripheral(from peripheral: CBPeripheralProtocol, operatingSystem: BluetoothPeripheral.OperatingSystem) -> BluetoothPeripheral {
        return addBluetoothPeripheral(BluetoothPeripheral(peripheral: peripheral, operatingSystem: operatingSystem))
    }

    func removeBluetoothPeripheral(for peripheral: CBPeripheralProtocol) {
        guard let bluetoothPeripheral = bluetoothPeripheral(for: peripheral) else { return }

        removeBluetoothPeripheral(bluetoothPeripheral)
    }

    func expiredBluetoothPeripherals() -> [BluetoothPeripheral] {
        bluetoothPeripherals.filter {
            $0.peripheral.state == .disconnected
                && !$0.expired && Date().timeIntervalSince($0.lastScannedDate ?? $0.creationDate) > settings.expiredBluetoothPeripheralTimeInterval
        }
    }
    
    @discardableResult
    private func addBluetoothPeripheral(_ bluetoothPeripheral: BluetoothPeripheral) -> BluetoothPeripheral {
        var existingBluetoothPeripheral = bluetoothPeripheralForPeripheralIdentifier[bluetoothPeripheral.peripheral.identifier]

        if existingBluetoothPeripheral == nil {
            existingBluetoothPeripheral = bluetoothPeripheral
            bluetoothPeripheralForPeripheralIdentifier[bluetoothPeripheral.peripheral.identifier] = existingBluetoothPeripheral
        }

        return existingBluetoothPeripheral!
    }

    private func removeBluetoothPeripheral(_ bluetoothPeripheral: BluetoothPeripheral) {
        bluetoothPeripheral.peripheral.delegate = nil
        bluetoothPeripheral.invalidateConnectionTimeoutTimer()
        bluetoothPeripheralForPeripheralIdentifier.removeValue(forKey: bluetoothPeripheral.peripheral.identifier)
    }
}
