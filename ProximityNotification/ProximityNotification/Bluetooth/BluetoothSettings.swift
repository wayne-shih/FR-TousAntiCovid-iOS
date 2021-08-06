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

/// A specification of the Bluetooth settings for proximity notification.
public struct BluetoothSettings {
    
    /// The unique identifier of the exposed Bluetooth service.
    public let serviceUniqueIdentifier: String
    
    /// The unique identifier of the characteristic used to exchange payloads through the exposed Bluetooth service.
    public let serviceCharacteristicUniqueIdentifier: String
    
    /// The dynamic settings that can be updated without stopping the service.
    public var dynamicSettings: BluetoothDynamicSettings
    
    /// The minimum time interval between two successive Bluetooth connections on the same peripheral. Default value is 1 minute.
    public let connectionTimeInterval: TimeInterval
    
    /// The expiration delay for the received Bluetooth proximity information in cache. Default value is 3 minutes.
    public let cacheExpirationDelay: TimeInterval
    
    /// The time interval to expire a peripheral if we can't take the load. Default value is 30 seconds.
    public let expiredBluetoothPeripheralTimeInterval: TimeInterval
    
    /// The number of simultaneus connections allowed. Default value is 1 connection.
    public let maximumConcurrentConnectionCount: Int
    
    /// Creates a specification of Bluetooth settings with the specified values.
    /// - Parameters:
    ///   - serviceUniqueIdentifier: The unique identifier of the exposed Bluetooth service.
    ///   - serviceCharacteristicUniqueIdentifier: The unique identifier of the characteristic used to exchange payloads through the exposed Bluetooth service.
    ///   - dynamicSettings: The dynamic settings that can be updated without stopping the service.
    ///   - connectionTimeInterval: The minimum time interval between two successive Bluetooth connections on the same peripheral. Default value is 1 minute.
    ///   - cacheExpirationDelay: The expiration delay for the received Bluetooth proximity information in cache. Default value is 3 minutes.
    ///   - expiredBluetoothPeripheralTimeInterval: The time interval to expire a peripheral if we can't take the load. Default value is 30 seconds.
    ///   - maximumConcurrentConnectionCount: The number of simultaneus connections allowed. Default value is 1 connection.
    public init(serviceUniqueIdentifier: String,
                serviceCharacteristicUniqueIdentifier: String,
                dynamicSettings: BluetoothDynamicSettings,
                connectionTimeInterval: TimeInterval = 1.0 * 60.0,
                cacheExpirationDelay: TimeInterval = 3.0 * 60.0,
                expiredBluetoothPeripheralTimeInterval: TimeInterval = 30.0,
                maximumConcurrentConnectionCount: Int = 1) {
        self.serviceUniqueIdentifier = serviceUniqueIdentifier
        self.serviceCharacteristicUniqueIdentifier = serviceCharacteristicUniqueIdentifier
        self.dynamicSettings = dynamicSettings
        self.connectionTimeInterval = connectionTimeInterval
        self.cacheExpirationDelay = cacheExpirationDelay
        self.expiredBluetoothPeripheralTimeInterval = expiredBluetoothPeripheralTimeInterval
        self.maximumConcurrentConnectionCount = maximumConcurrentConnectionCount
    }
}

/// A specification of the Bluetooth dynamic settings for proximity notification.
public struct BluetoothDynamicSettings {
    
    /// The compensation gain for the transmitting power level, in decibels. Conveyed by the transmitted Bluetooth proximity payload.
    public let txCompensationGain: Int8
    
    /// The compensation gain for the receiving power level, in decibels. Allows to compute the calibrated RSSI.
    public let rxCompensationGain: Int8
    
    /// Creates a specification of dynamic Bluetooth settings with the specified values.
    /// - Parameters:
    ///   - txCompensationGain: The compensation gain for the transmitting power level, in decibels. Conveyed by the transmitted Bluetooth proximity payload.
    ///   - rxCompensationGain: The compensation gain for the receiving power level, in decibels. Allows to compute the calibrated RSSI.
    public init(txCompensationGain: Int8,
                rxCompensationGain: Int8) {
        self.txCompensationGain = txCompensationGain
        self.rxCompensationGain = rxCompensationGain
    }
}
