/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/11/10 - for the TousAntiCovid project
 */

import Foundation

class BluetoothRSSICalibrator {

    var settings: BluetoothSettings

    init(settings: BluetoothSettings) {
        self.settings = settings
    }

    func calibrateRSSI(for bluetoothPeripheralRSSIInfo: BluetoothPeripheralRSSIInfo, from bluetoothProximityPayload: BluetoothProximityPayload) -> Int? {
        guard let rawRSSI = bluetoothPeripheralRSSIInfo.rssi else { return nil }

        var calibratedRSSI: Int
        if !bluetoothPeripheralRSSIInfo.isRSSIFromPayload {
            calibratedRSSI = rawRSSI - Int(bluetoothProximityPayload.txPowerLevel) - Int(settings.dynamicSettings.rxCompensationGain)
        } else {
            calibratedRSSI = rawRSSI - Int(settings.dynamicSettings.txCompensationGain)
        }

        return calibratedRSSI
    }
}
