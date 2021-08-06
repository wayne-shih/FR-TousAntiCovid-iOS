/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/17 - for the TousAntiCovid project
 */

@testable import ProximityNotification
import XCTest

class BluetoothProximityNotificationTests: XCTestCase {
    
    private let settings = BluetoothSettings(serviceUniqueIdentifier: UUID().uuidString,
                                             serviceCharacteristicUniqueIdentifier: UUID().uuidString,
                                             dynamicSettings: BluetoothDynamicSettings(txCompensationGain: 10, rxCompensationGain: 20),
                                             connectionTimeInterval: 3)
    
    private func makeBluetoothProximityNotification(stateChangedHandler: @escaping StateChangedHandler = { _ in },
                                                    dispatchQueue: DispatchQueue,
                                                    centralManagerMock: BluetoothCentralManagerMock,
                                                    peripheralManagerMock: BluetoothPeripheralManagerMock) -> BluetoothProximityNotification {
        return BluetoothProximityNotification(settings: settings,
                                              stateChangedHandler: stateChangedHandler,
                                              centralManager: centralManagerMock,
                                              peripheralManager: peripheralManagerMock)
    }
    
    func testStartCallsStateChangedHandler() {
        // Given
        let expectation = XCTestExpectation(description: "stateChangedHandler is called")
        let stateChangedHandler: StateChangedHandler = { state in
            XCTAssertEqual(.on, state)
            expectation.fulfill()
        }
        
        let dispatchQueue = DispatchQueue(label: UUID().uuidString)
        let centralManagerMock = BluetoothCentralManagerMock(settings: settings, dispatchQueue: dispatchQueue)
        let peripheralManagerMock = BluetoothPeripheralManagerMock(settings: settings, dispatchQueue: dispatchQueue)
        let bluetoothProximityNotification = makeBluetoothProximityNotification(stateChangedHandler: stateChangedHandler,
                                                                                dispatchQueue: dispatchQueue,
                                                                                centralManagerMock: centralManagerMock,
                                                                                peripheralManagerMock: peripheralManagerMock)
        
        // When
        bluetoothProximityNotification.start(proximityPayloadProvider: { return ProximityPayload(data: Data(Array(0..<16))) },
                                             proximityInfoUpdateHandler: { _ in },
                                             identifierFromProximityPayload: { _ in return Data() })
        
        // Then
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(.on, bluetoothProximityNotification.state)
    }
    
    func testScanPeripheralWithAdvertisedPayloadCallsProximityInfoUpdateHandler() {
        // Given
        guard let proximityPayload = ProximityPayload(data: Data(Array(0..<16))) else {
            XCTFail("Could not initialize ProximityPayload")
            return
        }
        
        let dispatchQueue = DispatchQueue(label: UUID().uuidString)
        let centralManagerMock = BluetoothCentralManagerMock(settings: settings, dispatchQueue: dispatchQueue)
        let peripheralManagerMock = BluetoothPeripheralManagerMock(settings: settings, dispatchQueue: dispatchQueue)
        let bluetoothProximityNotification = makeBluetoothProximityNotification(dispatchQueue: dispatchQueue,
                                                                                centralManagerMock: centralManagerMock,
                                                                                peripheralManagerMock: peripheralManagerMock)
        
        let timestamp = Date()
        let rssi = -60
        let txPowerLevel = Int8(14)
        
        let expectation = XCTestExpectation(description: "proximityInfoUpdateHandler is called only once")
        expectation.assertForOverFulfill = true
        let proximityInfoUpdateHandler: ProximityInfoUpdateHandler = { proximity in
            XCTAssertEqual(proximityPayload, proximity.payload)
            XCTAssertEqual(timestamp, proximity.timestamp)
            let metadata = proximity.metadata as? BluetoothProximityMetadata
            XCTAssertNotNil(metadata)
            if let metadata = metadata {
                XCTAssertEqual(Int(txPowerLevel), metadata.txPowerLevel)
                XCTAssertEqual(rssi, metadata.rawRSSI)
                XCTAssertEqual(rssi - Int(txPowerLevel) - Int(self.settings.dynamicSettings.rxCompensationGain), metadata.calibratedRSSI)
            }
            expectation.fulfill()
        }
        
        // When
        bluetoothProximityNotification.start(proximityPayloadProvider: { return proximityPayload },
                                             proximityInfoUpdateHandler: proximityInfoUpdateHandler,
                                             identifierFromProximityPayload: { _ in return Data() })
        centralManagerMock.scheduleScan(bluetoothPeripheralRSSIInfo: BluetoothPeripheralRSSIInfo(peripheralIdentifier: UUID(),
                                                                                                 timestamp: timestamp,
                                                                                                 rssi: rssi,
                                                                                                 isRSSIFromPayload: false),
                                        payload: BluetoothProximityPayload(payload: proximityPayload, txPowerLevel: txPowerLevel),
                                        isPayloadAdvertised: true,
                                        after: 1.0)
        
        // Then
        wait(for: [expectation], timeout: 10.0)
        sleep(5) // Wait a few seconds to check that expectation is not fulfilled again
    }
    
    func testScanSamePeripheralSeveralTimesWithAdvertisedPayloadCallsProximityInfoUpdateHandler() {
        // Given
        guard let proximityPayload = ProximityPayload(data: Data(Array(0..<16))) else {
            XCTFail("Could not initialize ProximityPayload")
            return
        }
        
        let dispatchQueue = DispatchQueue(label: UUID().uuidString)
        let centralManagerMock = BluetoothCentralManagerMock(settings: settings, dispatchQueue: dispatchQueue)
        let peripheralManagerMock = BluetoothPeripheralManagerMock(settings: settings, dispatchQueue: dispatchQueue)
        let bluetoothProximityNotification = makeBluetoothProximityNotification(dispatchQueue: dispatchQueue,
                                                                                centralManagerMock: centralManagerMock,
                                                                                peripheralManagerMock: peripheralManagerMock)
        
        let payload = BluetoothProximityPayload(payload: proximityPayload, txPowerLevel: 8)
        let bluetoothPeripheralRSSIInfo = BluetoothPeripheralRSSIInfo(peripheralIdentifier: UUID(), timestamp: Date(), rssi: 0, isRSSIFromPayload: false)
        
        let expectation = XCTestExpectation(description: "proximityInfoUpdateHandler is called exactly three times")
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 3
        let proximityInfoUpdateHandler: ProximityInfoUpdateHandler = { _ in
            expectation.fulfill()
        }
        
        // When
        bluetoothProximityNotification.start(proximityPayloadProvider: { return proximityPayload },
                                             proximityInfoUpdateHandler: proximityInfoUpdateHandler,
                                             identifierFromProximityPayload: { _ in return Data() })
        centralManagerMock.scheduleScan(bluetoothPeripheralRSSIInfo: bluetoothPeripheralRSSIInfo,
                                        payload: payload,
                                        isPayloadAdvertised: true,
                                        after: 1.0)
        centralManagerMock.scheduleScan(bluetoothPeripheralRSSIInfo: bluetoothPeripheralRSSIInfo,
                                        payload: payload,
                                        isPayloadAdvertised: true,
                                        after: 2.0)
        // Schedule a scan after connectionTimeInterval is expired
        centralManagerMock.scheduleScan(bluetoothPeripheralRSSIInfo: bluetoothPeripheralRSSIInfo,
                                        payload: payload,
                                        isPayloadAdvertised: true,
                                        after: 2.0 + settings.connectionTimeInterval + 1.0)
        
        // Then
        wait(for: [expectation], timeout: 10.0)
        sleep(5) // Wait a few seconds to check that expectation is not fulfilled again
    }
    
    func testScanPeripheralWithoutAdvertisedPayloadCallsProximityInfoUpdateHandler() {
        // Given
        guard let proximityPayload = ProximityPayload(data: Data(Array(0..<16))) else {
            XCTFail("Could not initialize ProximityPayload")
            return
        }
        
        let dispatchQueue = DispatchQueue(label: UUID().uuidString)
        let centralManagerMock = BluetoothCentralManagerMock(settings: settings, dispatchQueue: dispatchQueue)
        let peripheralManagerMock = BluetoothPeripheralManagerMock(settings: settings, dispatchQueue: dispatchQueue)
        let bluetoothProximityNotification = makeBluetoothProximityNotification(dispatchQueue: dispatchQueue,
                                                                                centralManagerMock: centralManagerMock,
                                                                                peripheralManagerMock: peripheralManagerMock)
        
        let timestamp = Date()
        let rssi = -60
        let txPowerLevel = Int8(14)
        
        let expectation = XCTestExpectation(description: "proximityInfoUpdateHandler is called only once")
        expectation.assertForOverFulfill = true
        let proximityInfoUpdateHandler: ProximityInfoUpdateHandler = { proximity in
            XCTAssertEqual(proximityPayload, proximity.payload)
            XCTAssertEqual(timestamp, proximity.timestamp)
            let metadata = proximity.metadata as? BluetoothProximityMetadata
            XCTAssertNotNil(metadata)
            if let metadata = metadata {
                XCTAssertEqual(Int(txPowerLevel), metadata.txPowerLevel)
                XCTAssertEqual(rssi, metadata.rawRSSI)
                XCTAssertEqual(rssi - Int(txPowerLevel) - Int(self.settings.dynamicSettings.rxCompensationGain), metadata.calibratedRSSI)
            }
            expectation.fulfill()
        }
        
        // When
        bluetoothProximityNotification.start(proximityPayloadProvider: { return proximityPayload },
                                             proximityInfoUpdateHandler: proximityInfoUpdateHandler,
                                             identifierFromProximityPayload: { _ in return Data() })
        centralManagerMock.scheduleScan(bluetoothPeripheralRSSIInfo: BluetoothPeripheralRSSIInfo(peripheralIdentifier: UUID(),
                                                                                                 timestamp: timestamp,
                                                                                                 rssi: rssi,
                                                                                                 isRSSIFromPayload: false),
                                        payload: BluetoothProximityPayload(payload: proximityPayload, txPowerLevel: txPowerLevel),
                                        isPayloadAdvertised: false,
                                        after: 1.0)
        
        // Then
        wait(for: [expectation], timeout: 10.0)
        sleep(5) // Wait a few seconds to check that expectation is not fulfilled again
    }

    func testScanSamePeripheralSeveralTimesWithoutAdvertisedPayloadCallsProximityInfoUpdateHandler() {
        // Given
        guard let proximityPayload = ProximityPayload(data: Data(Array(0..<16))) else {
            XCTFail("Could not initialize ProximityPayload")
            return
        }

        let dispatchQueue = DispatchQueue(label: UUID().uuidString)
        let centralManagerMock = BluetoothCentralManagerMock(settings: settings, dispatchQueue: dispatchQueue)
        let peripheralManagerMock = BluetoothPeripheralManagerMock(settings: settings, dispatchQueue: dispatchQueue)
        let bluetoothProximityNotification = makeBluetoothProximityNotification(dispatchQueue: dispatchQueue,
                                                                                centralManagerMock: centralManagerMock,
                                                                                peripheralManagerMock: peripheralManagerMock)

        let payload = BluetoothProximityPayload(payload: proximityPayload, txPowerLevel: 8)
        let bluetoothPeripheralRSSIInfo = BluetoothPeripheralRSSIInfo(peripheralIdentifier: UUID(), timestamp: Date(), rssi: 0, isRSSIFromPayload: false)

        let expectation = XCTestExpectation(description: "proximityInfoUpdateHandler is called exactly four times")
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 4
        let proximityInfoUpdateHandler: ProximityInfoUpdateHandler = { _ in
            expectation.fulfill()
        }

        // When
        bluetoothProximityNotification.start(proximityPayloadProvider: { return proximityPayload },
                                             proximityInfoUpdateHandler: proximityInfoUpdateHandler,
                                             identifierFromProximityPayload: { _ in return Data() })
        centralManagerMock.scheduleScan(bluetoothPeripheralRSSIInfo: bluetoothPeripheralRSSIInfo,
                                        payload: payload,
                                        isPayloadAdvertised: false,
                                        after: 1.0)
        centralManagerMock.scheduleScan(bluetoothPeripheralRSSIInfo: bluetoothPeripheralRSSIInfo,
                                        payload: payload,
                                        isPayloadAdvertised: false,
                                        after: 3.0)
        // Schedule a scan after connectionTimeInterval is expired
        // This should call ProximityInfoUpdateHandler twice
        centralManagerMock.scheduleScan(bluetoothPeripheralRSSIInfo: bluetoothPeripheralRSSIInfo,
                                        payload: payload,
                                        isPayloadAdvertised: false,
                                        after: 3.0 + settings.connectionTimeInterval + 1.0)

        // Then
        wait(for: [expectation], timeout: 10.0)
        sleep(5) // Wait a few seconds to check that expectation is not fulfilled again
    }

    func testIncomingWriteRequestFromPeripheralWithoutAdvertiserCallsProximityInfoUpdateHandler() {
        // Given
        guard let proximityPayload = ProximityPayload(data: Data(Array(0..<16))) else {
            XCTFail("Could not initialize ProximityPayload")
            return
        }

        let dispatchQueue = DispatchQueue(label: UUID().uuidString)
        let centralManagerMock = BluetoothCentralManagerMock(settings: settings, dispatchQueue: dispatchQueue)
        let peripheralManagerMock = BluetoothPeripheralManagerMock(settings: settings, dispatchQueue: dispatchQueue)
        let bluetoothProximityNotification = makeBluetoothProximityNotification(dispatchQueue: dispatchQueue,
                                                                                centralManagerMock: centralManagerMock,
                                                                                peripheralManagerMock: peripheralManagerMock)
        let timestamp = Date()
        let rssi = -60
        let txPowerLevel = Int8(14)
        let payload = BluetoothProximityPayload(payload: proximityPayload, txPowerLevel: txPowerLevel)
        let bluetoothPeripheralRSSIInfo = BluetoothPeripheralRSSIInfo(peripheralIdentifier: UUID(), timestamp: timestamp, rssi: rssi, isRSSIFromPayload: true)

        let expectation = XCTestExpectation(description: "proximityInfoUpdateHandler is called exactly once")
        expectation.assertForOverFulfill = true
        let proximityInfoUpdateHandler: ProximityInfoUpdateHandler = { proximity in
            XCTAssertEqual(proximityPayload, proximity.payload)
            XCTAssertEqual(timestamp, proximity.timestamp)
            let metadata = proximity.metadata as? BluetoothProximityMetadata
            XCTAssertNotNil(metadata)
            if let metadata = metadata {
                XCTAssertEqual(Int(txPowerLevel), metadata.txPowerLevel)
                XCTAssertEqual(rssi, metadata.rawRSSI)
                XCTAssertEqual(rssi - Int(self.settings.dynamicSettings.txCompensationGain), metadata.calibratedRSSI)
            }
            expectation.fulfill()
        }

        // When
        bluetoothProximityNotification.start(proximityPayloadProvider: { return proximityPayload },
                                             proximityInfoUpdateHandler: proximityInfoUpdateHandler,
                                             identifierFromProximityPayload: { _ in return Data() })
        peripheralManagerMock.scheduleIncomingWriteRequest(from: bluetoothPeripheralRSSIInfo,
                                                           payload: payload,
                                                           after: 1.0)

        // Then
        wait(for: [expectation], timeout: 10.0)
    }
}
