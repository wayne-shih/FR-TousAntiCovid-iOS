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

class BluetoothCentralManager: NSObject, BluetoothCentralManagerProtocol {
    
    weak var delegate: BluetoothCentralManagerDelegate?
    
    var settings: BluetoothSettings
    
    private let dispatchQueue: DispatchQueue
    
    private var proximityPayloadProvider: ProximityPayloadProvider?
    
    private let logger: ProximityNotificationLogger
    
    private var centralManager: CBCentralManager?

    private let bluetoothPeripheralDataStore: BluetoothPeripheralDataStore

    private let bluetoothPeripheralConnectionManager: BluetoothPeripheralConnectionManager

    private let serviceUUID: CBUUID
    
    private let characteristicUUID: CBUUID

    private let gattApplicationErrorCode = 80

    private var isStarted = false

    private var restoredPeripherals: [CBPeripheral]?

    init(settings: BluetoothSettings,
         dispatchQueue: DispatchQueue,
         logger: ProximityNotificationLogger) {
        self.settings = settings
        self.dispatchQueue = dispatchQueue
        self.logger = logger
        bluetoothPeripheralDataStore = BluetoothPeripheralDataStore(settings: settings)
        bluetoothPeripheralConnectionManager = BluetoothPeripheralConnectionManager(bluetoothPeripheralDataStore: bluetoothPeripheralDataStore,
                                                                                    settings: settings,
                                                                                    logger: logger)
        serviceUUID = CBUUID(string: settings.serviceUniqueIdentifier)
        characteristicUUID = CBUUID(string: settings.serviceCharacteristicUniqueIdentifier)

        super.init()

        bluetoothPeripheralConnectionManager.connectionBlock = { [weak self] peripheralIdentifier, completionHandler in
            self?.connectBluetoothPeripheral(forPeripheralIdentifier: peripheralIdentifier, completionHandler: completionHandler)
        }
    }
    
    var state: ProximityNotificationState {
        return centralManager?.state.toProximityNotificationState() ?? .off
    }
    
    func start(proximityPayloadProvider: @escaping ProximityPayloadProvider) {
        logger.info(message: "start central manager",
                    source: ProximityNotificationEvent.bluetoothCentralManagerStart.rawValue)
        self.proximityPayloadProvider = proximityPayloadProvider

        if let centralManager = centralManager {
            if centralManager.state == .poweredOn {
                scanForPeripherals()
            }
        } else {
            let options = [CBCentralManagerOptionRestoreIdentifierKey: "proximitynotification-bluetoothcentralmanager"]
            centralManager = CBCentralManager(delegate: self, queue: dispatchQueue, options: options)
        }

        isStarted = true
    }
    
    func stop() {
        logger.info(message: "stop central manager",
                    source: ProximityNotificationEvent.bluetoothCentralManagerStop.rawValue)

        isStarted = false

        stopCentralManager()

        dispatchQueue.async { [weak self] in
            self?.reset()
        }
    }
    
    private func stopCentralManager() {
        guard let centralManager = centralManager else { return }
        
        if centralManager.isScanning {
            centralManager.stopScan()
        }
    }
    
    private func scanForPeripherals() {
        logger.info(message: "scan for peripherals",
                    source: ProximityNotificationEvent.bluetoothCentralManagerScanForPeripherals.rawValue)
        
        let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true)]
        centralManager?.scanForPeripherals(withServices: [serviceUUID], options: options)
    }
    
    private func connectIfNeeded(_ bluetoothPeripheral: BluetoothPeripheral) {
        switch bluetoothPeripheral.peripheral.state {
        case .disconnected:
            connect(bluetoothPeripheral)
        default:
            logger.info(message: "a connection to the peripheral \(bluetoothPeripheral.peripheral.shortDescription) is not needed",
                        source: ProximityNotificationEvent.bluetoothCentralManagerPeripheralNoNeedToPerformConnection.rawValue)
        }
    }

    private func connect(_ bluetoothPeripheral: BluetoothPeripheral) {
        guard isStarted, centralManager?.state == .poweredOn else { return }

        bluetoothPeripheral.waitingForConnection = true
        bluetoothPeripheralConnectionManager.addBluetoothPeripheral(forPeripheralIdentifier: bluetoothPeripheral.peripheral.identifier)
    }

    private func connectBluetoothPeripheral(forPeripheralIdentifier peripheralIdentifier: UUID, completionHandler: @escaping () -> Void) {
        dispatchQueue.async { [weak self] in
            guard let `self` = self,
                  self.isStarted,
                  self.centralManager?.state == .poweredOn,
                  let bluetoothPeripheral = self.bluetoothPeripheralDataStore.bluetoothPeripheral(forPeripheralIdentifier: peripheralIdentifier) else {
                completionHandler()
                return
            }

            self.logger.info(message: "central manager connecting to peripheral \(bluetoothPeripheral.peripheral.shortDescription)",
                             source: ProximityNotificationEvent.bluetoothCentralManagerConnectingToPeripheral.rawValue)
            self.centralManager?.connect(bluetoothPeripheral.peripheral, options: nil)
            bluetoothPeripheral.waitingForConnection = false
            // Attempts to connect to a peripheral don’t time out, so manage it manually
            self.scheduleConnectionTimeoutTimer(for: bluetoothPeripheral.peripheral)

            completionHandler()
        }
    }
    
    private func scheduleConnectionTimeoutTimer(for peripheral: CBPeripheralProtocol) {
        guard let bluetoothPeripheral = bluetoothPeripheralDataStore.bluetoothPeripheral(for: peripheral) else { return }

        // Invalidate the previous one before
        bluetoothPeripheral.invalidateConnectionTimeoutTimer()

        // Must be lower than 10 seconds
        let timer = Timer(timeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.dispatchQueue.async {
                if peripheral.state != .connected {
                    self?.logger.info(message: "central manager connection timeout to peripheral \(peripheral.shortDescription)",
                                      source: ProximityNotificationEvent.bluetoothCentralManagerConnectionTimeoutToPeripheral.rawValue)
                    self?.disconnectPeripheral(peripheral)
                }
            }
        }
        
        RunLoop.main.add(timer, forMode: .common)
        bluetoothPeripheral.setConnectionTimeoutTimer(timer)
    }
    
    private func discoverServices(of peripheral: CBPeripheral) {
        if peripheral.services == nil {
            peripheral.discoverServices([serviceUUID])
            logger.info(message: "peripheral \(peripheral.shortDescription) discovering services",
                        source: ProximityNotificationEvent.bluetoothCentralManagerStartDiscoveringPeripheralServices.rawValue)
        } else {
            logger.info(message: "peripheral \(peripheral.shortDescription) has already discovered services",
                        source: ProximityNotificationEvent.bluetoothCentralManagerPeripheralServicesAlreadyDiscovered.rawValue)
            discoverCharacteristics(of: peripheral)
        }
    }
    
    private func discoverCharacteristics(of peripheral: CBPeripheral) {
        guard let bluetoothPeripheral = bluetoothPeripheralDataStore.bluetoothPeripheral(for: peripheral) else {
            disconnectPeripheral(peripheral)
            return
        }

        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else {
            logger.error(message: "service not found for peripheral \(peripheral.shortDescription)",
                         source: ProximityNotificationEvent.bluetoothCentralManagerPeripheralServiceNotFound.rawValue)
            delegate?.bluetoothCentralManager(self, didNotFindServiceForPeripheralIdentifier: peripheral.identifier)
            bluetoothPeripheral.expired = true
            disconnectPeripheral(peripheral)
            return
        }
        
        if service.characteristics == nil {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
            logger.info(message: "peripheral \(peripheral.shortDescription) discovering characteristics",
                        source: ProximityNotificationEvent.bluetoothCentralManagerStartDiscoveringServiceCharacteristics.rawValue)
        } else {
            logger.info(message: "peripheral \(peripheral.shortDescription) has already discovered characteristics",
                        source: ProximityNotificationEvent.bluetoothCentralManagerPeripheralCharacteristicsAlreadyDiscovered.rawValue)
            exchangeValue(for: bluetoothPeripheral, on: service)
        }
    }

    private func rssi(_ RSSI: NSNumber) -> Int? {
        // According to documentation in CBCentralManager.h,
        // value of 127 is reserved and indicates the RSSI was not available.
        return RSSI.intValue != Int8.max ? RSSI.intValue : nil
    }
    
    private func exchangeValue(for bluetoothPeripheral: BluetoothPeripheral, on service: CBService) {
        guard service.uuid == serviceUUID,
              let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID }) else {
            logger.error(message: "characteristic not found for peripheral \(bluetoothPeripheral.peripheral.shortDescription)",
                         source: ProximityNotificationEvent.bluetoothCentralManagerPeripheralCharacteristicNotFound.rawValue)
            bluetoothPeripheral.expired = true
            disconnectPeripheral(bluetoothPeripheral.peripheral)
            return
        }

        if bluetoothPeripheral.operatingSystem == .android {
            if let proximityPayload = proximityPayloadProvider?() {
                logger.info(message: "peripheral \(bluetoothPeripheral.peripheral.shortDescription) write value",
                            source: ProximityNotificationEvent.bluetoothCentralManagerPeripheralWriteValue.rawValue)
                let bluetoothProximityPayload = BluetoothProximityPayload(payload: proximityPayload,
                                                                          txPowerLevel: settings.dynamicSettings.txCompensationGain)
                bluetoothPeripheral.peripheral.writeValue(bluetoothProximityPayload.data, for: characteristic, type: .withResponse)
            }
        } else {
            logger.info(message: "peripheral \(bluetoothPeripheral.peripheral.shortDescription) read value",
                        source: ProximityNotificationEvent.bluetoothCentralManagerPeripheralReadValue.rawValue)
            bluetoothPeripheral.peripheral.readValue(for: characteristic)
        }
    }

    private func removeExpiredBluetoothPeripherals() {
        bluetoothPeripheralDataStore.expiredBluetoothPeripherals().forEach {
            logger.info(message: "expired peripheral \($0.peripheral.shortDescription)",
                        source: ProximityNotificationEvent.bluetoothCentralManagerExpiredPeripheral.rawValue)
            $0.expired = true
            disconnectPeripheral($0.peripheral)
        }
    }

    private func connectPeripherals() {
        guard isStarted, centralManager?.state == .poweredOn else { return }
        
        removeExpiredBluetoothPeripherals()

        let bluetoothPeripheralsToConnect = bluetoothPeripheralConnectionManager.bluetoothPeripheralsToConnect()

        bluetoothPeripheralsToConnect.forEach {
            logger.info(message: "Connect a new available peripheral \($0.peripheral.shortDescription)",
                        source: ProximityNotificationEvent.bluetoothCentralManagerConnectPeripheral.rawValue)
            connectIfNeeded($0)
        }
    }

    private func reset() {
        cleanPeripherals()
        bluetoothPeripheralConnectionManager.removeAllBluetoothPeripherals()
    }
    
    private func cleanPeripheral(_ peripheral: CBPeripheralProtocol) {
        logger.debug(message: "clean peripheral \(peripheral.shortDescription)",
                     source: ProximityNotificationEvent.bluetoothCentralManagerCleanPeripheral.rawValue)

        bluetoothPeripheralDataStore.removeBluetoothPeripheral(for: peripheral)
        bluetoothPeripheralConnectionManager.removeBluetoothPeripheral(forPeripheralIdentifier: peripheral.identifier)
    }
    
    private func cleanPeripherals() {
        logger.debug(message: "clean peripherals (\(bluetoothPeripheralDataStore.bluetoothPeripherals.count))",
                     source: ProximityNotificationEvent.bluetoothCentralManagerCleanAllPeripherals.rawValue)

        bluetoothPeripheralDataStore.bluetoothPeripherals.forEach({ disconnectPeripheral($0.peripheral) })
    }
    
    private func disconnectPeripheral(_ peripheral: CBPeripheralProtocol) {
        logger.debug(message: "disconnect peripheral \(peripheral.shortDescription)",
                     source: ProximityNotificationEvent.bluetoothCentralManagerDisconnectPeripheral.rawValue)
        
        if peripheral.state == .connecting || peripheral.state == .connected {
            logger.info(message: "central manager cancelling connection to peripheral \(peripheral.shortDescription)",
                        source: ProximityNotificationEvent.bluetoothCentralManagerCancellingConnectionToPeripheral.rawValue)
            peripheral.delegate = nil
            centralManager?.cancelPeripheralConnection(peripheral)
        } else {
            cleanPeripheral(peripheral)
        }
    }
    
    private func disconnectPeripherals() {
        bluetoothPeripheralDataStore.bluetoothPeripherals.forEach({ disconnectPeripheral($0.peripheral) })
    }

    private func handleDisconnection(for bluetoothPeripheral: BluetoothPeripheral, with error: Error?) {
        cleanPeripheral(bluetoothPeripheral.peripheral)

        dispatchQueue.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.connectPeripherals()
        }
    }
}

extension BluetoothCentralManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.info(message: "central manager did update state \(central.state.rawValue)",
                    source: ProximityNotificationEvent.bluetoothCentralManagerDidUpdateState.rawValue)
        
        stopCentralManager()
        
        switch central.state {
        case .poweredOn:
            restoredPeripherals?.forEach({ disconnectPeripheral($0) })
            restoredPeripherals?.removeAll()
            scanForPeripherals()
        case .poweredOff, .resetting:
            reset()
        default:
            break
        }
        
        delegate?.bluetoothCentralManager(self, stateDidChange: central.state.toProximityNotificationState())
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        logger.info(message: "central manager will restore state \(dict)",
                    source: ProximityNotificationEvent.bluetoothCentralManagerWillRestoreState.rawValue)
        
        restoredPeripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral]
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        logger.info(message: "central manager did discover peripheral \(peripheral.shortDescription)",
                    source: ProximityNotificationEvent.bluetoothCentralManagerDidDiscoverPeripheral.rawValue)
        
        var bluetoothProximityPayload: BluetoothProximityPayload?
        if let advertisementDataServiceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data],
           let serviceData = advertisementDataServiceData[serviceUUID] {
            bluetoothProximityPayload = BluetoothProximityPayload(data: serviceData)
        }

        let bluetoothPeripheralRSSIInfo = BluetoothPeripheralRSSIInfo(peripheralIdentifier: peripheral.identifier,
                                                                      timestamp: Date(),
                                                                      rssi: rssi(RSSI),
                                                                      isRSSIFromPayload: false)
        let shouldAttemptConnection = delegate?.bluetoothCentralManager(self,
                                                                        didScan: bluetoothPeripheralRSSIInfo,
                                                                        bluetoothProximityPayload: bluetoothProximityPayload) ?? false

        if shouldAttemptConnection {
            let bluetoothPeripheral = bluetoothPeripheralDataStore.addBluetoothPeripheral(from: peripheral,
                                                                                          bluetoothProximityPayload: bluetoothProximityPayload)
            bluetoothPeripheral.lastScannedDate = Date()
            connectPeripherals()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info(message: "central manager did connect to peripheral \(peripheral.shortDescription)",
                    source: ProximityNotificationEvent.bluetoothCentralManagerDidConnectToPeripheral.rawValue)

        guard let bluetoothPeripheral = bluetoothPeripheralDataStore.bluetoothPeripheral(for: peripheral) else {
            disconnectPeripheral(peripheral)
            return
        }
        
        // Invalidate the current timeout timer
        bluetoothPeripheral.invalidateConnectionTimeoutTimer()

        peripheral.delegate = self

        discoverServices(of: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.error(message: "central manager did fail to connect to peripheral \(peripheral.shortDescription) with error \(String(describing: error))",
                     source: ProximityNotificationEvent.bluetoothCentralManagerDidFailToConnectToPeripheral.rawValue)

        guard let bluetoothPeripheral = bluetoothPeripheralDataStore.bluetoothPeripheral(for: peripheral) else { return }

        handleDisconnection(for: bluetoothPeripheral, with: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info(message: "central manager did disconnect from peripheral \(peripheral.shortDescription) with error \(String(describing: error))",
                    source: ProximityNotificationEvent.bluetoothCentralManagerDidDisconnectFromPeripheral.rawValue)

        guard let bluetoothPeripheral = bluetoothPeripheralDataStore.bluetoothPeripheral(for: peripheral) else { return }

        handleDisconnection(for: bluetoothPeripheral, with: error)
    }
}

extension BluetoothCentralManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logger.info(message: "peripheral \(peripheral.shortDescription) did discover services",
                    source: ProximityNotificationEvent.bluetoothCentralManagerDidDiscoverPeripheralServices.rawValue)
        
        discoverCharacteristics(of: peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        logger.info(message: "peripheral \(peripheral.shortDescription) did discover characteristics",
                    source: ProximityNotificationEvent.bluetoothCentralManagerDidDiscoverPeripheralCharacteristics.rawValue)

        guard let bluetoothPeripheral = bluetoothPeripheralDataStore.bluetoothPeripheral(for: peripheral) else {
            disconnectPeripheral(peripheral)
            return
        }

        exchangeValue(for: bluetoothPeripheral, on: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.info(message: "peripheral \(peripheral.shortDescription) did update value for characteristic",
                    source: ProximityNotificationEvent.bluetoothCentralManagerDidUpdatePeripheralValueForCharacteristic.rawValue)

        if let readValue = characteristic.value,
           let bluetoothProximityPayload = BluetoothProximityPayload(data: readValue) {
            logger.info(message: "peripheral \(peripheral.shortDescription) did read characteristic",
                        source: ProximityNotificationEvent.bluetoothCentralManagerDidReadPeripheralCharacteristic.rawValue)
            delegate?.bluetoothCentralManager(self,
                                              didRead: bluetoothProximityPayload,
                                              forPeripheralIdentifier: peripheral.identifier)
            bluetoothPeripheralDataStore.bluetoothPeripheral(for: peripheral)?.bluetoothProximityPayload = bluetoothProximityPayload
        }

        disconnectPeripheral(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.info(message: "peripheral \(peripheral.shortDescription) did write value for characteristic with error \(String(describing: error))",
                    source: ProximityNotificationEvent.bluetoothCentralManagerDidWriteValueToPeripheralForCharacteristic.rawValue)

        // According to the BT specification error code 80 is an application error.
        // It's used to not disconnect the remote Android immediately to let it read the RSSI with the current connection.
        if let error = error as NSError?, error.domain == CBATTErrorDomain, error.code == gattApplicationErrorCode {
            dispatchQueue.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.disconnectPeripheral(peripheral)
            }
        } else {
            disconnectPeripheral(peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        logger.info(message: "peripheral \(peripheral.shortDescription) did modify services \(invalidatedServices)",
                    source: ProximityNotificationEvent.bluetoothCentralManagerDidModifyServices.rawValue)

        if invalidatedServices.contains(where: { $0.uuid == serviceUUID }) {
            delegate?.bluetoothCentralManager(self, didNotFindServiceForPeripheralIdentifier: peripheral.identifier)
            bluetoothPeripheralDataStore.bluetoothPeripheral(for: peripheral)?.expired = true
            disconnectPeripheral(peripheral)
        }
    }
}
