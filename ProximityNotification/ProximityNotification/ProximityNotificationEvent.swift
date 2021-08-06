/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/09/22 - for the TousAntiCovid project
 */

import Foundation

/// The proximity notification events.
enum ProximityNotificationEvent: String {
    
    case bluetoothPeripheralManagerStart
    case bluetoothPeripheralManagerStop
    case bluetoothPeripheralManagerStartAdvertising
    case bluetoothPeripheralManagerDidUpdateState
    case bluetoothPeripheralManagerWillRestoreState
    case bluetoothPeripheralManagerAddService
    case bluetoothPeripheralManagerDidAddService
    case bluetoothPeripheralManagerDidStartAdvertising
    case bluetoothPeripheralManagerDidReceiveRead
    case bluetoothPeripheralManagerDidRespondToReadWithSuccess
    case bluetoothPeripheralManagerDidRespondToReadWithError
    case bluetoothPeripheralManagerDidReceiveWrite
    case bluetoothPeripheralManagerDidRespondToWriteWithSuccess
    case bluetoothPeripheralManagerDidRespondToWriteWithError
    
    case bluetoothCentralManagerStart
    case bluetoothCentralManagerStop
    case bluetoothCentralManagerScanForPeripherals
    case bluetoothCentralManagerPeripheralNoNeedToPerformConnection
    case bluetoothCentralManagerConnectingToPeripheral
    case bluetoothCentralManagerConnectionTimeoutToPeripheral
    case bluetoothCentralManagerStartDiscoveringPeripheralServices
    case bluetoothCentralManagerPeripheralServicesAlreadyDiscovered
    case bluetoothCentralManagerPeripheralServiceNotFound
    case bluetoothCentralManagerStartDiscoveringServiceCharacteristics
    case bluetoothCentralManagerPeripheralCharacteristicsAlreadyDiscovered
    case bluetoothCentralManagerPeripheralCharacteristicNotFound
    case bluetoothCentralManagerPeripheralWriteValue
    case bluetoothCentralManagerPeripheralReadValue
    case bluetoothCentralManagerCleanPeripheral
    case bluetoothCentralManagerCleanAllPeripherals
    case bluetoothCentralManagerDisconnectPeripheral
    case bluetoothCentralManagerCancellingConnectionToPeripheral
    case bluetoothCentralManagerDidUpdateState
    case bluetoothCentralManagerWillRestoreState
    case bluetoothCentralManagerDidDiscoverPeripheral
    case bluetoothCentralManagerDidConnectToPeripheral
    case bluetoothCentralManagerDidFailToConnectToPeripheral
    case bluetoothCentralManagerDidDisconnectFromPeripheral
    case bluetoothCentralManagerDidDiscoverPeripheralServices
    case bluetoothCentralManagerDidDiscoverPeripheralCharacteristics
    case bluetoothCentralManagerDidUpdatePeripheralValueForCharacteristic
    case bluetoothCentralManagerDidReadPeripheralCharacteristic
    case bluetoothCentralManagerDidWriteValueToPeripheralForCharacteristic
    case bluetoothCentralManagerDidModifyServices
    case bluetoothCentralManagerExpiredPeripheral
    case bluetoothCentralManagerConnectPeripheral
    case bluetoothCentralManagerReadRSSI

    case bluetoothPeripheralConnectionManagerAddPeripheral
    case bluetoothPeripheralConnectionManagerConnectionAttempt
    case bluetoothPeripheralConnectionManagerConnectionAttemptDone
}
