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

protocol BluetoothCentralManagerDelegate: AnyObject {
    
    func bluetoothCentralManager(_ centralManager: BluetoothCentralManagerProtocol,
                                 stateDidChange state: ProximityNotificationState)
    
    func bluetoothCentralManager(_ centralManager: BluetoothCentralManagerProtocol,
                                 didScan bluetoothPeripheralRSSIInfo: BluetoothPeripheralRSSIInfo,
                                 bluetoothProximityPayload: BluetoothProximityPayload?) -> Bool
    
    func bluetoothCentralManager(_ centralManager: BluetoothCentralManagerProtocol,
                                 didRead bluetoothProximityPayload: BluetoothProximityPayload,
                                 forPeripheralIdentifier peripheralIdentifier: UUID)
    
    func bluetoothCentralManager(_ centralManager: BluetoothCentralManagerProtocol,
                                 didNotFindServiceForPeripheralIdentifier peripheralIdentifier: UUID)
}
