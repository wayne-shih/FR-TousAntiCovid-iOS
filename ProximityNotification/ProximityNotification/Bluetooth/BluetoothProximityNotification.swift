/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/06 - for the TousAntiCovid project
 */

import Foundation

final class BluetoothProximityNotification: ProximityNotification {

    let stateChangedHandler: StateChangedHandler

    var state: ProximityNotificationState {
        return centralManager.state
    }

    var dynamicSettings: BluetoothDynamicSettings {
        get { settings.dynamicSettings }
        set {
            settings.dynamicSettings = newValue
            centralManager.settings = settings
            peripheralManager.settings = settings
            rssiCalibrator.settings = settings
        }
    }
    
    private var settings: BluetoothSettings

    private let centralManager: BluetoothCentralManagerProtocol
    
    private let peripheralManager: BluetoothPeripheralManagerProtocol

    private let bluetoothConnectionSelector: BluetoothPeripheralConnectionSelector

    private var proximityInfoUpdateHandler: ProximityInfoUpdateHandler?

    private var bluetoothPeripheralRSSIInfoForPeripheralIdentifier: Cache<UUID, BluetoothPeripheralRSSIInfo>
    
    private var bluetoothProximityPayloadForPeripheralIdentifier: Cache<UUID, BluetoothProximityPayload>

    private var cacheExpirationTimer: Timer?

    private var rssiCalibrator: BluetoothRSSICalibrator

    init(settings: BluetoothSettings,
         stateChangedHandler: @escaping StateChangedHandler,
         centralManager: BluetoothCentralManagerProtocol,
         peripheralManager: BluetoothPeripheralManagerProtocol) {
        self.settings = settings
        self.stateChangedHandler = stateChangedHandler
        self.centralManager = centralManager
        self.peripheralManager = peripheralManager
        bluetoothPeripheralRSSIInfoForPeripheralIdentifier = Cache<UUID, BluetoothPeripheralRSSIInfo>(expirationDelay: settings.cacheExpirationDelay)
        bluetoothProximityPayloadForPeripheralIdentifier = Cache<UUID, BluetoothProximityPayload>(expirationDelay: settings.cacheExpirationDelay)
        bluetoothConnectionSelector = BluetoothPeripheralConnectionSelector(settings: settings)
        rssiCalibrator = BluetoothRSSICalibrator(settings: settings)
        self.centralManager.delegate = self
        self.peripheralManager.delegate = self
    }
    
    func start(proximityPayloadProvider: @escaping ProximityPayloadProvider,
               proximityInfoUpdateHandler: @escaping ProximityInfoUpdateHandler,
               identifierFromProximityPayload: @escaping IdentifierFromProximityPayload) {
        self.proximityInfoUpdateHandler = proximityInfoUpdateHandler
        bluetoothConnectionSelector.identifierFromProximityPayload = identifierFromProximityPayload
        centralManager.start(proximityPayloadProvider: proximityPayloadProvider)
        peripheralManager.start(proximityPayloadProvider: proximityPayloadProvider)
        startCacheExpirationTimer()
    }
    
    func stop() {
        centralManager.stop()
        peripheralManager.stop()
        stopCacheExpirationTimer()
        bluetoothPeripheralRSSIInfoForPeripheralIdentifier.removeAllValues()
        bluetoothProximityPayloadForPeripheralIdentifier.removeAllValues()
        bluetoothConnectionSelector.removeAllValues()
    }
    
    private func proximityInfo(for bluetoothPeripheralRSSIInfo: BluetoothPeripheralRSSIInfo,
                               from bluetoothProximityPayload: BluetoothProximityPayload) -> ProximityInfo? {
        guard let rawRSSI = bluetoothPeripheralRSSIInfo.rssi,
              let calibratedRSSI = rssiCalibrator.calibrateRSSI(for: bluetoothPeripheralRSSIInfo,
                                                                from: bluetoothProximityPayload) else { return nil }

        let metadata = BluetoothProximityMetadata(rawRSSI: rawRSSI,
                                                  calibratedRSSI: calibratedRSSI,
                                                  txPowerLevel: Int(bluetoothProximityPayload.txPowerLevel))
        return ProximityInfo(payload: bluetoothProximityPayload.payload,
                             timestamp: bluetoothPeripheralRSSIInfo.timestamp,
                             metadata: metadata)
    }
    
    private func startCacheExpirationTimer() {
        stopCacheExpirationTimer()
        let timer = Timer(timeInterval: settings.cacheExpirationDelay * 2, repeats: true) { [weak self] _ in
            guard let `self` = self else { return }
            
            self.bluetoothPeripheralRSSIInfoForPeripheralIdentifier.removeExpiredValues()
            self.bluetoothProximityPayloadForPeripheralIdentifier.removeExpiredValues()
            self.bluetoothConnectionSelector.removeExpiredValues()
        }
        
        cacheExpirationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    
    private func stopCacheExpirationTimer() {
        cacheExpirationTimer?.invalidate()
        cacheExpirationTimer = nil
    }
}

extension BluetoothProximityNotification: BluetoothCentralManagerDelegate {
    
    func bluetoothCentralManager(_ centralManager: BluetoothCentralManagerProtocol,
                                 stateDidChange state: ProximityNotificationState) {
        DispatchQueue.main.async {
            self.stateChangedHandler(state)
        }
    }
    
    func bluetoothCentralManager(_ centralManager: BluetoothCentralManagerProtocol,
                                 didScan bluetoothPeripheralRSSIInfo: BluetoothPeripheralRSSIInfo,
                                 bluetoothProximityPayload: BluetoothProximityPayload?) -> Bool {
        let peripheralIdentifier = bluetoothPeripheralRSSIInfo.peripheralIdentifier
        bluetoothPeripheralRSSIInfoForPeripheralIdentifier[peripheralIdentifier] = bluetoothPeripheralRSSIInfo
        let bluetoothProximityPayload = bluetoothProximityPayload ?? bluetoothProximityPayloadForPeripheralIdentifier[peripheralIdentifier]
        
        if let bluetoothProximityPayload = bluetoothProximityPayload,
           let proximityInfo = self.proximityInfo(for: bluetoothPeripheralRSSIInfo, from: bluetoothProximityPayload) {
            proximityInfoUpdateHandler?(proximityInfo)
        }
        
        return bluetoothConnectionSelector.shouldConnectPeripheral(with: bluetoothProximityPayload)
    }

    func bluetoothCentralManager(_ centralManager: BluetoothCentralManagerProtocol,
                                 didRead bluetoothProximityPayload: BluetoothProximityPayload,
                                 forPeripheralIdentifier peripheralIdentifier: UUID) {
        bluetoothProximityPayloadForPeripheralIdentifier[peripheralIdentifier] = bluetoothProximityPayload

        bluetoothConnectionSelector.setBluetoothProximityPayload(bluetoothProximityPayload)

        if let bluetoothPeripheralRSSIInfo = bluetoothPeripheralRSSIInfoForPeripheralIdentifier[peripheralIdentifier],
           let proximityInfo = self.proximityInfo(for: bluetoothPeripheralRSSIInfo, from: bluetoothProximityPayload) {
            proximityInfoUpdateHandler?(proximityInfo)
        }
    }
    
    func bluetoothCentralManager(_ centralManager: BluetoothCentralManagerProtocol,
                                 didNotFindServiceForPeripheralIdentifier peripheralIdentifier: UUID) {
        bluetoothPeripheralRSSIInfoForPeripheralIdentifier.removeValue(forKey: peripheralIdentifier)
        bluetoothProximityPayloadForPeripheralIdentifier.removeValue(forKey: peripheralIdentifier)
    }
}

extension BluetoothProximityNotification: BluetoothPeripheralManagerDelegate {

    func bluetoothPeripheralManager(_ peripheralManager: BluetoothPeripheralManagerProtocol,
                                    didReceive bluetoothProximityPayload: BluetoothProximityPayload,
                                    from bluetoothPeripheralRSSIInfo: BluetoothPeripheralRSSIInfo) {
        if let proximityInfo = self.proximityInfo(for: bluetoothPeripheralRSSIInfo, from: bluetoothProximityPayload) {
            proximityInfoUpdateHandler?(proximityInfo)
        }
    }
}
