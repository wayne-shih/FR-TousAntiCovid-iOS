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

class BluetoothPeripheralDataStoreTests: XCTestCase {

    private let settings = BluetoothSettings(serviceUniqueIdentifier: UUID().uuidString,
                                             serviceCharacteristicUniqueIdentifier: UUID().uuidString,
                                             dynamicSettings: BluetoothDynamicSettings(txCompensationGain: 10, rxCompensationGain: 20),
                                             connectionTimeInterval: 3,
                                             expiredBluetoothPeripheralTimeInterval: 2.0)

    private let bluetoothPeripheralBuilder = BluetoothPeripheralBuilder()

    func testAddPeripherals() {
        // Given
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let peripheral1 = CBPeripheralMock(state: .disconnected)
        let peripheral2 = CBPeripheralMock(state: .disconnected)

        // When
        bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral1, operatingSystem: .iOS)
        bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral2, operatingSystem: .iOS)

        // Then
        XCTAssertEqual(2, bluetoothPeripheralDataStore.bluetoothPeripherals.count)
    }

    func testAddSamePeripheralTwice() {
        // Given
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let identifier = UUID()
        let peripheral1 = CBPeripheralMock(identifier: identifier, state: .disconnected)
        let peripheral2 = CBPeripheralMock(identifier: identifier, state: .disconnected)

        // When
        bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral1, operatingSystem: .iOS)
        bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral2, operatingSystem: .iOS)

        // Then
        XCTAssertEqual(1, bluetoothPeripheralDataStore.bluetoothPeripherals.count)
    }

    func testRemovePeripheral() {
        // Given
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let peripheral1 = CBPeripheralMock(state: .disconnected)
        let peripheral2 = CBPeripheralMock(state: .disconnected)
        bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral1, operatingSystem: .iOS)
        bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral2, operatingSystem: .iOS)

        // When
        bluetoothPeripheralDataStore.removeBluetoothPeripheral(for: peripheral1)

        // Then
        XCTAssertEqual(1, bluetoothPeripheralDataStore.bluetoothPeripherals.count)
        XCTAssertEqual(peripheral2, bluetoothPeripheralDataStore.bluetoothPeripherals[0].peripheral as? CBPeripheralMock)
    }

    func testPeripheralsExpirationWithOnePeripheral() {
        // Given
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let peripheral1 = CBPeripheralMock(state: .disconnected)
        bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral1, operatingSystem: .iOS)

        sleep(3)

        let peripheral2 = CBPeripheralMock(state: .disconnected)
        bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral2, operatingSystem: .iOS)

        // When
        let expiredPeripherals = bluetoothPeripheralDataStore.expiredBluetoothPeripherals()

        // Then
        XCTAssertEqual(1, expiredPeripherals.count)
        let expiredPeripheral1 = expiredPeripherals[0].peripheral as? CBPeripheralMock
        XCTAssertNotNil(expiredPeripheral1)
        XCTAssertEqual(expiredPeripheral1, peripheral1)
    }

    func testPeripheralsExpirationWithSeveralPeripherals() {
        // Given
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let peripheral1 = CBPeripheralMock(state: .disconnected)
        bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral1, operatingSystem: .iOS)
        let peripheral2 = CBPeripheralMock(state: .disconnected)
        bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral2, operatingSystem: .iOS)
        let peripheral3 = CBPeripheralMock(state: .disconnected)
        bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral3, operatingSystem: .android)

        sleep(3)

        // When
        let expiredPeripherals = bluetoothPeripheralDataStore.expiredBluetoothPeripherals()

        // Then
        XCTAssertEqual(3, expiredPeripherals.count)
        XCTAssertTrue(expiredPeripherals.contains(where: { $0.peripheral as? CBPeripheralMock == peripheral1 }))
        XCTAssertTrue(expiredPeripherals.contains(where: { $0.peripheral as? CBPeripheralMock == peripheral2 }))
        XCTAssertTrue(expiredPeripherals.contains(where: { $0.peripheral as? CBPeripheralMock == peripheral3 }))
    }

    func testPeripheralsExpirationWithoutPeripheral() {
        // Given
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let peripheral1 = CBPeripheralMock(state: .disconnected)
        bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral1, operatingSystem: .iOS)
        let peripheral2 = CBPeripheralMock(state: .disconnected)
        bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral2, operatingSystem: .android)

        // When
        let expiredPeripherals = bluetoothPeripheralDataStore.expiredBluetoothPeripherals()

        // Then
        XCTAssertEqual(0, expiredPeripherals.count)
    }
}
