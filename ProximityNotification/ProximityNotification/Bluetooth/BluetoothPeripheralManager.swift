/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/06 - for the TousAntiCovid project
 */

import CoreBluetooth
import Foundation

class BluetoothPeripheralManager: NSObject, BluetoothPeripheralManagerProtocol {

    weak var delegate: BluetoothPeripheralManagerDelegate?

    var settings: BluetoothSettings
    
    private let dispatchQueue: DispatchQueue
    
    private var proximityPayloadProvider: ProximityPayloadProvider?
    
    private let logger: ProximityNotificationLogger
    
    private var peripheralManager: CBPeripheralManager?
    
    private let serviceUUID: CBUUID

    private let characteristicUUID: CBUUID

    init(settings: BluetoothSettings,
         dispatchQueue: DispatchQueue,
         logger: ProximityNotificationLogger) {
        self.settings = settings
        self.dispatchQueue = dispatchQueue
        self.logger = logger
        serviceUUID = CBUUID(string: settings.serviceUniqueIdentifier)
        characteristicUUID = CBUUID(string: settings.serviceCharacteristicUniqueIdentifier)
    }
    
    func start(proximityPayloadProvider: @escaping ProximityPayloadProvider) {
        logger.info(message: "start peripheral manager",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerStart.rawValue)

        self.proximityPayloadProvider = proximityPayloadProvider
        
        if let peripheralManager = peripheralManager {
            if peripheralManager.state == .poweredOn {
                dispatchQueue.sync {
                    stopPeripheralManager()
                    addService()
                }
            }
        } else {
            let options = [CBPeripheralManagerOptionRestoreIdentifierKey: "proximitynotification-bluetoothperipheralmanager"]
            peripheralManager = CBPeripheralManager(delegate: self, queue: dispatchQueue, options: options)
        }
    }
    
    func stop() {
        logger.info(message: "stop peripheral manager",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerStop.rawValue)

        dispatchQueue.sync {
            stopPeripheralManager()
        }
    }
    
    private func stopPeripheralManager() {
        guard let peripheralManager = peripheralManager else { return }

        if peripheralManager.isAdvertising {
            peripheralManager.stopAdvertising()
        }

        // Remove services when BT is off is an API misuse
        if peripheralManager.state == .poweredOn {
            peripheralManager.removeAllServices()
        }
    }

    private func addService() {
        logger.info(message: "peripheral manager add service",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerAddService.rawValue)

        let service = CBMutableService(type: serviceUUID,
                                       primary: true)
        let characteristic = CBMutableCharacteristic(type: characteristicUUID,
                                                     properties: [.read, .write],
                                                     value: nil,
                                                     permissions: [.readable, .writeable])
        service.characteristics = [characteristic]
        peripheralManager?.add(service)
    }
    
    private func startAdvertising() {
        logger.info(message: "start advertising",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerStartAdvertising.rawValue)
        
        let advertisementData = [CBAdvertisementDataServiceUUIDsKey: [serviceUUID]]
        peripheralManager?.startAdvertising(advertisementData)
    }
}

extension BluetoothPeripheralManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        logger.info(message: "peripheral manager did update state \(peripheral.state.rawValue)",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerDidUpdateState.rawValue)

        switch peripheralManager?.state {
        case .poweredOn:
            stopPeripheralManager()
            addService()
        default:
            break
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        logger.info(message: "peripheral manager will restore state \(dict)",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerWillRestoreState.rawValue)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        logger.info(message: "peripheral manager did add service with error \(String(describing: error))",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerDidAddService.rawValue)
        
        guard error == nil else { return }
        
        startAdvertising()
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        logger.info(message: "peripheral manager did start advertising with error \(String(describing: error))",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerDidStartAdvertising.rawValue)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        logger.info(message: "peripheral manager did receive read",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerDidReceiveRead.rawValue)
        
        if let proximityPayload = proximityPayloadProvider?() {
            let bluetoothProximityPayload = BluetoothProximityPayload(payload: proximityPayload,
                                                                      txPowerLevel: settings.dynamicSettings.txCompensationGain)
            request.value = bluetoothProximityPayload.data
            logger.info(message: "peripheral manager did respond read with success",
                        source: ProximityNotificationEvent.bluetoothPeripheralManagerDidRespondToReadWithSuccess.rawValue)
            peripheral.respond(to: request, withResult: .success)
        } else {
            logger.error(message: "peripheral manager did respond read with error",
                         source: ProximityNotificationEvent.bluetoothPeripheralManagerDidRespondToReadWithError.rawValue)
            peripheral.respond(to: request, withResult: .unlikelyError)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        logger.info(message: "peripheral manager did receive write",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerDidReceiveWrite.rawValue)

        for request in requests {
            if let receivedValue = request.value,
               let bluetoothProximityPayload = BluetoothProximityPayload(data: receivedValue),
               let rssi = bluetoothProximityPayload.rssi {
                let bluetoothPeripheral = BluetoothPeripheralRSSIInfo(peripheralIdentifier: request.central.identifier,
                                                                      timestamp: Date(),
                                                                      rssi: Int(rssi),
                                                                      isRSSIFromPayload: true)
                delegate?.bluetoothPeripheralManager(self,
                                                     didReceive: bluetoothProximityPayload,
                                                     from: bluetoothPeripheral)
            } else {
                logger.error(message: "peripheral manager did respond write with error",
                             source: ProximityNotificationEvent.bluetoothPeripheralManagerDidRespondToWriteWithError.rawValue)
                peripheral.respond(to: request, withResult: .invalidPdu)
                return
            }
        }
        
        if let firstRequest = requests.first {
            logger.info(message: "peripheral manager did respond write with success",
                        source: ProximityNotificationEvent.bluetoothPeripheralManagerDidRespondToWriteWithSuccess.rawValue)
            peripheral.respond(to: firstRequest, withResult: .success)
        }
    }
}
