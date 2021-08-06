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

class BluetoothPeripheralConnectionSelectorTests: XCTestCase {

    private let settings = BluetoothSettings(serviceUniqueIdentifier: UUID().uuidString,
                                             serviceCharacteristicUniqueIdentifier: UUID().uuidString,
                                             dynamicSettings: BluetoothDynamicSettings(txCompensationGain: 10, rxCompensationGain: 20),
                                             connectionTimeInterval: 2,
                                             maximumConcurrentConnectionCount: 4)

    private let bluetoothPeripheralBuilder = BluetoothPeripheralBuilder()

    let identifierFromProximityPayload: IdentifierFromProximityPayload = { payload in
        return payload.data
    }

    func testConnectionSelectorWithiOSPeripheralsWithoutPayload() {
        // Given
        let bluetoothPeripheralConnectionSelector = makeBluetoothPeripheralConnectionSelector()
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let peripheral1 = bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral1",
                                                                   operatingSystem: .iOS,
                                                                   state: .disconnected,
                                                                   in: bluetoothPeripheralDataStore)
        let peripheral2 = bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral2",
                                                                   operatingSystem: .iOS,
                                                                   state: .disconnected,
                                                                   in: bluetoothPeripheralDataStore)

        // When
        let shouldConnectPeripheral1 = bluetoothPeripheralConnectionSelector.shouldConnectPeripheral(with: peripheral1.bluetoothProximityPayload)
        let shouldConnectPeripheral2 = bluetoothPeripheralConnectionSelector.shouldConnectPeripheral(with: peripheral2.bluetoothProximityPayload)

        // Then
        XCTAssertTrue(shouldConnectPeripheral1)
        XCTAssertTrue(shouldConnectPeripheral2)
    }

    func testConnectionSelectorWithiOSPeripheralWithPayload() {
        // Given
        let bluetoothPeripheralConnectionSelector = makeBluetoothPeripheralConnectionSelector()
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let peripheralName = "TestPeripheral"
        var peripheral = bluetoothPeripheralBuilder.addPeripheral(withName: peripheralName,
                                                                  operatingSystem: .iOS,
                                                                  state: .disconnected,
                                                                  in: bluetoothPeripheralDataStore)

        // When
        let shouldConnectPeripheral1 = bluetoothPeripheralConnectionSelector.shouldConnectPeripheral(with: peripheral.bluetoothProximityPayload)
        peripheral = bluetoothPeripheralBuilder.addPeripheral(withName: peripheralName,
                                                              operatingSystem: .iOS,
                                                              state: .connected,
                                                              in: bluetoothPeripheralDataStore)
        XCTAssertNotNil(peripheral.bluetoothProximityPayload)
        bluetoothPeripheralConnectionSelector.setBluetoothProximityPayload(peripheral.bluetoothProximityPayload!)
        let shouldConnectPeripheral2 = bluetoothPeripheralConnectionSelector.shouldConnectPeripheral(with: peripheral.bluetoothProximityPayload)

        // Then
        XCTAssertTrue(shouldConnectPeripheral1)
        XCTAssertFalse(shouldConnectPeripheral2)
    }

    func testConnectionSelectorWithiOSPeripheralWithPayloadAfterConnectionTimeInterval() {
        // Given
        let bluetoothPeripheralConnectionSelector = makeBluetoothPeripheralConnectionSelector()
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let peripheralName = "TestPeripheral"
        var peripheral = bluetoothPeripheralBuilder.addPeripheral(withName: peripheralName,
                                                                  operatingSystem: .iOS,
                                                                  state: .disconnected,
                                                                  in: bluetoothPeripheralDataStore)

        // When
        let shouldConnectPeripheral1 = bluetoothPeripheralConnectionSelector.shouldConnectPeripheral(with: peripheral.bluetoothProximityPayload)
        peripheral = bluetoothPeripheralBuilder.addPeripheral(withName: peripheralName,
                                                              operatingSystem: .iOS,
                                                              state: .connected,
                                                              in: bluetoothPeripheralDataStore)
        sleep(UInt32(settings.connectionTimeInterval) + 1)
        let shouldConnectPeripheral2 = bluetoothPeripheralConnectionSelector.shouldConnectPeripheral(with: peripheral.bluetoothProximityPayload)

        // Then
        XCTAssertTrue(shouldConnectPeripheral1)
        XCTAssertTrue(shouldConnectPeripheral2)
    }

    func testConnectionSelectorWithAndroidPeripheralsWithDifferentPayload() {
        // Given
        let bluetoothPeripheralConnectionSelector = makeBluetoothPeripheralConnectionSelector()
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let peripheral1 = bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral1",
                                                                   operatingSystem: .android,
                                                                   state: .disconnected,
                                                                   in: bluetoothPeripheralDataStore)
        let peripheral2 = bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral2",
                                                                   operatingSystem: .android,
                                                                   state: .disconnected,
                                                                   in: bluetoothPeripheralDataStore)

        // When
        let shouldConnectPeripheral1 = bluetoothPeripheralConnectionSelector.shouldConnectPeripheral(with: peripheral1.bluetoothProximityPayload)
        let shouldConnectPeripheral2 = bluetoothPeripheralConnectionSelector.shouldConnectPeripheral(with: peripheral2.bluetoothProximityPayload)

        // Then
        XCTAssertTrue(shouldConnectPeripheral1)
        XCTAssertTrue(shouldConnectPeripheral2)
    }

    func testConnectionSelectorWithAndroidPeripheralsWithSamePayload() {
        // Given
        let bluetoothPeripheralConnectionSelector = makeBluetoothPeripheralConnectionSelector()
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let peripheralName = "TestPeripheral"
        let peripheral1 = bluetoothPeripheralBuilder.addPeripheral(withName: peripheralName,
                                                                   operatingSystem: .android,
                                                                   state: .disconnected,
                                                                   in: bluetoothPeripheralDataStore)
        let peripheral2 = bluetoothPeripheralBuilder.addPeripheral(withName: peripheralName,
                                                                   operatingSystem: .android,
                                                                   state: .disconnected,
                                                                   in: bluetoothPeripheralDataStore)

        // When
        let shouldConnectPeripheral1 = bluetoothPeripheralConnectionSelector.shouldConnectPeripheral(with: peripheral1.bluetoothProximityPayload)
        let shouldConnectPeripheral2 = bluetoothPeripheralConnectionSelector.shouldConnectPeripheral(with: peripheral2.bluetoothProximityPayload)

        // Then
        XCTAssertTrue(shouldConnectPeripheral1)
        XCTAssertFalse(shouldConnectPeripheral2)
    }

    func testConnectionSelectorWithAndroidPeripheralsWithSamePayloadAfterConnectionInterval() {
        // Given
        let bluetoothPeripheralConnectionSelector = makeBluetoothPeripheralConnectionSelector()
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let peripheralName = "TestPeripheral"
        let peripheral1 = bluetoothPeripheralBuilder.addPeripheral(withName: peripheralName,
                                                                   operatingSystem: .android,
                                                                   state: .disconnected,
                                                                   in: bluetoothPeripheralDataStore)
        let peripheral2 = bluetoothPeripheralBuilder.addPeripheral(withName: peripheralName,
                                                                   operatingSystem: .android,
                                                                   state: .disconnected,
                                                                   in: bluetoothPeripheralDataStore)

        // When
        let shouldConnectPeripheral1 = bluetoothPeripheralConnectionSelector.shouldConnectPeripheral(with: peripheral1.bluetoothProximityPayload)
        sleep(UInt32(settings.connectionTimeInterval) + 1)
        let shouldConnectPeripheral2 = bluetoothPeripheralConnectionSelector.shouldConnectPeripheral(with: peripheral2.bluetoothProximityPayload)

        // Then
        XCTAssertTrue(shouldConnectPeripheral1)
        XCTAssertTrue(shouldConnectPeripheral2)
    }

    private func makeBluetoothPeripheralConnectionSelector() -> BluetoothPeripheralConnectionSelector {
        let bluetoothPeripheralConnectionSelector = BluetoothPeripheralConnectionSelector(settings: settings)
        bluetoothPeripheralConnectionSelector.identifierFromProximityPayload = identifierFromProximityPayload

        return bluetoothPeripheralConnectionSelector
    }
}
