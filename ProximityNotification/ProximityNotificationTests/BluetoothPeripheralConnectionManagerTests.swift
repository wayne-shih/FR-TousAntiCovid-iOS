/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/02/17 - for the TousAntiCovid project
 */

@testable import ProximityNotification
import XCTest

class BluetoothPeripheralConnectionManagerTests: XCTestCase {

    private let settings = BluetoothSettings(serviceUniqueIdentifier: UUID().uuidString,
                                             serviceCharacteristicUniqueIdentifier: UUID().uuidString,
                                             dynamicSettings: BluetoothDynamicSettings(txCompensationGain: 10, rxCompensationGain: 20),
                                             connectionTimeInterval: 3,
                                             maximumConcurrentConnectionCount: 4)

    private let bluetoothPeripheralBuilder = BluetoothPeripheralBuilder()

    func testConnectionManagerWithoutExceedingMaximumConcurrentConnections() {
        // Given
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let bluetoothPeripheralConnectionManager = BluetoothPeripheralConnectionManager(bluetoothPeripheralDataStore: bluetoothPeripheralDataStore,
                                                                                        settings: settings)
        bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral1",
                                                 operatingSystem: .iOS,
                                                 state: .connected,
                                                 in: bluetoothPeripheralDataStore)
        let bluetoothPeripheral2 = bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral2",
                                                                            operatingSystem: .android,
                                                                            state: .disconnected,
                                                                            in: bluetoothPeripheralDataStore)
        let bluetoothPeripheral3 = bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral3",
                                                                            operatingSystem: .iOS,
                                                                            state: .disconnected,
                                                                            in: bluetoothPeripheralDataStore)
        let bluetoothPeripheral4 = bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral4",
                                                                            operatingSystem: .android,
                                                                            state: .disconnected,
                                                                            in: bluetoothPeripheralDataStore)

        // When
        let bluetoothPeripherals = bluetoothPeripheralConnectionManager.bluetoothPeripheralsToConnect()

        // Then
        XCTAssertEqual(3, bluetoothPeripherals.count)
        XCTAssertEqual(bluetoothPeripheral2.peripheral as? CBPeripheralMock, bluetoothPeripherals[0].peripheral as? CBPeripheralMock)
        XCTAssertEqual(bluetoothPeripheral3.peripheral as? CBPeripheralMock, bluetoothPeripherals[1].peripheral as? CBPeripheralMock)
        XCTAssertEqual(bluetoothPeripheral4.peripheral as? CBPeripheralMock, bluetoothPeripherals[2].peripheral as? CBPeripheralMock)
    }

    func testConnectionManagerTransientStatesWithoutExceedingMaximumConcurrentConnections() {
        // Given
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let bluetoothPeripheralConnectionManager = BluetoothPeripheralConnectionManager(bluetoothPeripheralDataStore: bluetoothPeripheralDataStore,
                                                                                        settings: settings)
        bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral1",
                                                 operatingSystem: .iOS,
                                                 state: .connected,
                                                 in: bluetoothPeripheralDataStore)
        let bluetoothPeripheral2 = bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral2",
                                                                            operatingSystem: .iOS,
                                                                            state: .disconnected,
                                                                            in: bluetoothPeripheralDataStore)
        bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral3",
                                                 operatingSystem: .iOS,
                                                 state: .connecting,
                                                 in: bluetoothPeripheralDataStore)
        bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral4",
                                                 operatingSystem: .iOS,
                                                 state: .disconnecting,
                                                 in: bluetoothPeripheralDataStore)

        // When
        let bluetoothPeripherals = bluetoothPeripheralConnectionManager.bluetoothPeripheralsToConnect()

        // Then
        XCTAssertEqual(1, bluetoothPeripherals.count)
        XCTAssertEqual(bluetoothPeripheral2.peripheral as? CBPeripheralMock, bluetoothPeripherals[0].peripheral as? CBPeripheralMock)
    }

    func testConnectionManagerExceedingMaximumConcurrentConnections() {
        // Given
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let bluetoothPeripheralConnectionManager = BluetoothPeripheralConnectionManager(bluetoothPeripheralDataStore: bluetoothPeripheralDataStore,
                                                                                        settings: settings)
        bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral1",
                                                 operatingSystem: .iOS,
                                                 state: .connected,
                                                 in: bluetoothPeripheralDataStore)
        bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral2",
                                                 operatingSystem: .android,
                                                 state: .connected,
                                                 in: bluetoothPeripheralDataStore)
        bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral3",
                                                 operatingSystem: .iOS,
                                                 state: .connecting,
                                                 in: bluetoothPeripheralDataStore)
        bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral4",
                                                 operatingSystem: .android,
                                                 state: .disconnecting,
                                                 in: bluetoothPeripheralDataStore)
        bluetoothPeripheralBuilder.addPeripheral(withName: "TestPeripheral5",
                                                 operatingSystem: .iOS,
                                                 state: .disconnected,
                                                 in: bluetoothPeripheralDataStore)

        // When
        let bluetoothPeripherals = bluetoothPeripheralConnectionManager.bluetoothPeripheralsToConnect()

        // Then
        XCTAssertEqual(0, bluetoothPeripherals.count)
    }

    func testSeveralConnectionAttempts() {
        // Given
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let bluetoothPeripheralConnectionManager = BluetoothPeripheralConnectionManager(bluetoothPeripheralDataStore: bluetoothPeripheralDataStore,
                                                                                        settings: settings)
        let expectation = XCTestExpectation(description: "connection block is called")
        expectation.expectedFulfillmentCount = 3
        expectation.assertForOverFulfill = true
        bluetoothPeripheralConnectionManager.connectionBlock = { _, completionHandler in
            completionHandler()
            expectation.fulfill()
        }
        let firstPeripheralIdentifier = UUID()
        let secondPeripheralIdentifier = UUID()
        let thirdPeripheralIdentifier = UUID()

        // When
        bluetoothPeripheralConnectionManager.addBluetoothPeripheral(forPeripheralIdentifier: firstPeripheralIdentifier)
        bluetoothPeripheralConnectionManager.addBluetoothPeripheral(forPeripheralIdentifier: secondPeripheralIdentifier)
        bluetoothPeripheralConnectionManager.addBluetoothPeripheral(forPeripheralIdentifier: thirdPeripheralIdentifier)

        // Then
        wait(for: [expectation], timeout: 5.0)
        sleep(1)
    }

    func testConnectionAttemptsForTheSameBluetoothPeripheral() {
        // Given
        let bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        let bluetoothPeripheralConnectionManager = BluetoothPeripheralConnectionManager(bluetoothPeripheralDataStore: bluetoothPeripheralDataStore,
                                                                                        settings: settings)
        let expectation = XCTestExpectation(description: "connection block is called")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true
        bluetoothPeripheralConnectionManager.connectionBlock = { _, completionHandler in
            completionHandler()
            expectation.fulfill()
        }
        let peripheralIdentifier = UUID()

        // When
        bluetoothPeripheralConnectionManager.addBluetoothPeripheral(forPeripheralIdentifier: peripheralIdentifier)
        bluetoothPeripheralConnectionManager.addBluetoothPeripheral(forPeripheralIdentifier: peripheralIdentifier)

        // Then
        wait(for: [expectation], timeout: 5.0)
        sleep(1)
    }
}
