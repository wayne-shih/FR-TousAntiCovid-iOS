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

class BluetoothPeripheral {

    enum OperatingSystem: String {
        case android, iOS
    }

    let peripheral: CBPeripheralProtocol

    let operatingSystem: OperatingSystem

    var bluetoothProximityPayload: BluetoothProximityPayload?

    var expired = false

    let creationDate: Date

    var lastScannedDate: Date?

    var waitingForConnection = false

    private var connectionTimeoutTimer: Timer?

    init(peripheral: CBPeripheralProtocol, operatingSystem: OperatingSystem) {
        self.peripheral = peripheral
        self.operatingSystem = operatingSystem
        creationDate = Date()
    }

    deinit {
        invalidateConnectionTimeoutTimer()
    }

    func setConnectionTimeoutTimer(_ connectionTimeoutTimer: Timer) {
        self.connectionTimeoutTimer = connectionTimeoutTimer
    }
    
    func invalidateConnectionTimeoutTimer() {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = nil
    }
}
