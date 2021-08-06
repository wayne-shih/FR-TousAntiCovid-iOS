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

/// A structure containing the settings for proximity notification.
public struct ProximityNotificationSettings {
    
    /// The Bluetooth settings.
    public let bluetoothSettings: BluetoothSettings
    
    /// Creates settings for proximity notification.
    /// - Parameter bluetoothSettings: The Bluetooth settings.
    public init(bluetoothSettings: BluetoothSettings) {
        self.bluetoothSettings = bluetoothSettings
    }
}

/// A structure containing the dynamic settings for proximity notification.
public struct ProximityNotificationDynamicSettings {

    /// The Bluetooth dynamic settings.
    public let bluetoothDynamicSettings: BluetoothDynamicSettings

    /// Creates dynamic settings for proximity notification.
    /// - Parameter bluetoothDynamicSettings: The Bluetooth dynamic settings.
    public init(bluetoothDynamicSettings: BluetoothDynamicSettings) {
        self.bluetoothDynamicSettings = bluetoothDynamicSettings
    }
}
