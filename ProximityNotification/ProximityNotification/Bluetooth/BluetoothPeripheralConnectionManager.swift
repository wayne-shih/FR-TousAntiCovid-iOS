/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/02/17 - for the TousAntiCovid project
 */

import Foundation

class BluetoothPeripheralConnectionManager {

    var connectionBlock: ((UUID, @escaping () -> Void) -> Void)?
    
    private var peripheralsUUIDToConnect = [UUID]()

    private let bluetoothPeripheralDataStore: BluetoothPeripheralDataStore

    private let settings: BluetoothSettings
    
    private let logger: ProximityNotificationLogger?

    private let dispatchQueue = DispatchQueue(label: UUID().uuidString, attributes: .concurrent)

    private var connectionTimer: DispatchSourceTimer?

    private let connectionTimerDispatchQueue = DispatchQueue(label: UUID().uuidString)

    private let timeIntervalBetweenConnections = 1.0

    private var lastConnectionAttempt = Date.distantPast

    init(bluetoothPeripheralDataStore: BluetoothPeripheralDataStore,
         settings: BluetoothSettings,
         logger: ProximityNotificationLogger? = nil) {
        self.bluetoothPeripheralDataStore = bluetoothPeripheralDataStore
        self.settings = settings
        self.logger = logger
    }

    func bluetoothPeripheralsToConnect() -> [BluetoothPeripheral] {
        var bluetoothPeripheralsToConnect = [BluetoothPeripheral]()

        let bluetoothPeripherals = bluetoothPeripheralDataStore.bluetoothPeripherals.filter({ !$0.expired })
        let connectedBluetoothPeripherals = bluetoothPeripherals.filter({ $0.peripheral.state != .disconnected || $0.waitingForConnection })

        let numberOfConnectionsAvailable = settings.maximumConcurrentConnectionCount - connectedBluetoothPeripherals.count
        if numberOfConnectionsAvailable > 0 {
            let availableBluetoothPeripherals = bluetoothPeripherals
                .filter({ $0.peripheral.state == .disconnected && !$0.waitingForConnection })
                .sorted(by: { $0.creationDate < $1.creationDate })
            bluetoothPeripheralsToConnect = Array(availableBluetoothPeripherals.prefix(numberOfConnectionsAvailable))
        }

        return bluetoothPeripheralsToConnect
    }

    func addBluetoothPeripheral(forPeripheralIdentifier peripheralIdentifier: UUID) {
        dispatchQueue.async(flags: .barrier) {
            self.logger?.debug(message: "add \(peripheralIdentifier) to connect",
                               source: ProximityNotificationEvent.bluetoothPeripheralConnectionManagerAddPeripheral.rawValue)
            if !self.peripheralsUUIDToConnect.contains(peripheralIdentifier) {
                self.peripheralsUUIDToConnect.append(peripheralIdentifier)
            }
            self.scheduleConnectionTimer()
        }
    }

    func removeBluetoothPeripheral(forPeripheralIdentifier peripheralIdentifier: UUID) {
        dispatchQueue.async(flags: .barrier) {
            self.peripheralsUUIDToConnect.removeAll(where: { $0 == peripheralIdentifier })
        }
    }

    func removeAllBluetoothPeripherals() {
        dispatchQueue.async(flags: .barrier) {
            self.peripheralsUUIDToConnect.removeAll()
            self.stopConnectionTimer()
        }
    }

    private func scheduleConnectionTimer() {
        if connectionTimer == nil {
            connectionTimer = DispatchSource.makeTimerSource(queue: connectionTimerDispatchQueue)
            let delay = Double.maximum(0.0, timeIntervalBetweenConnections - Date().timeIntervalSince(lastConnectionAttempt))
            connectionTimer?.schedule(deadline: .now() + delay, repeating: timeIntervalBetweenConnections)
            connectionTimer?.setEventHandler { [weak self] in
                guard let `self` = self else { return }

                self.connectNextBluetoothPeripheral()
            }
            connectionTimer?.resume()
        }
    }

    private func stopConnectionTimer() {
        connectionTimer?.cancel()
        connectionTimer = nil
    }

    private func connectNextBluetoothPeripheral() {
        var peripheralUUIDToConnect: UUID?
        dispatchQueue.sync {
            peripheralUUIDToConnect = peripheralsUUIDToConnect.first
        }

        guard let peripheralUUID = peripheralUUIDToConnect else { return }

        logger?.debug(message: "connection attempt to \(peripheralUUID)",
                      source: ProximityNotificationEvent.bluetoothPeripheralConnectionManagerConnectionAttempt.rawValue)
        let group = DispatchGroup()
        group.enter()
        connectionBlock?(peripheralUUID) { [weak self] in
            guard let `self` = self else { return }

            self.logger?.debug(message: "connection attempt to \(peripheralUUID) done",
                               source: ProximityNotificationEvent.bluetoothPeripheralConnectionManagerConnectionAttemptDone.rawValue)
            self.dispatchQueue.async(flags: .barrier) {
                if !self.peripheralsUUIDToConnect.isEmpty {
                    self.peripheralsUUIDToConnect.removeFirst()
                }
                self.lastConnectionAttempt = Date()
            }
            group.leave()
        }
        group.wait()

        dispatchQueue.sync {
            if peripheralsUUIDToConnect.isEmpty {
                stopConnectionTimer()
            }
        }
    }
}
