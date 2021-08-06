/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/19 - for the TousAntiCovid project
 */

import Foundation

class BluetoothPeripheralConnectionSelector {

    var identifierFromProximityPayload: IdentifierFromProximityPayload?

    private let logger: ProximityNotificationLogger?

    private var connectionDateForPayloadIdentifier: Cache<ProximityPayloadIdentifier, Date>

    init(settings: BluetoothSettings, logger: ProximityNotificationLogger? = nil) {
        self.logger = logger
        connectionDateForPayloadIdentifier = Cache(expirationDelay: settings.connectionTimeInterval)
    }

    func shouldConnectPeripheral(with bluetoothProximityPayload: BluetoothProximityPayload?) -> Bool {
        if let bluetoothProximityPayload = bluetoothProximityPayload {
            guard let identifier = identifierFromProximityPayload?(bluetoothProximityPayload.payload) else { return false }

            let shouldConnectPeripheral = connectionDateForPayloadIdentifier[identifier] == nil
            if shouldConnectPeripheral {
                updateConnectionDate(for: identifier)
            }

            return shouldConnectPeripheral
        }

        return true
    }

    func setBluetoothProximityPayload(_ bluetoothProximityPayload: BluetoothProximityPayload) {
        guard let identifier = identifierFromProximityPayload?(bluetoothProximityPayload.payload) else { return }

        updateConnectionDate(for: identifier)
    }

    func removeExpiredValues() {
        connectionDateForPayloadIdentifier.removeExpiredValues()
    }

    func removeAllValues() {
        connectionDateForPayloadIdentifier.removeAllValues()
    }

    private func updateConnectionDate(for identifier: ProximityPayloadIdentifier) {
        connectionDateForPayloadIdentifier[identifier] = Date()
    }
}
