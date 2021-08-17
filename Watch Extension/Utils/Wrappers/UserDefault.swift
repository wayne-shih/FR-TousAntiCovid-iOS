// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UserDefault.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 05/08/2021.
//

import Foundation

@propertyWrapper
struct UserDefault<T> {

    private var defaults: UserDefaults
    private let key: Key
    private let defaultValue: T

    var projectedValue: String { key.rawValue }

    var wrappedValue: T {
        get { defaults.object(forKey: key.rawValue) as? T ?? defaultValue }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                defaults.removeObject(forKey: key.rawValue)
            } else {
                defaults.set(newValue, forKey: key.rawValue)
            }
            defaults.synchronize()
        }
    }

    init(wrappedValue: T, key: Key, userDefault: UserDefaults = .standard) {
        self.defaultValue = wrappedValue
        self.key = key
        self.defaults = userDefault
    }

}

extension UserDefault where T: ExpressibleByNilLiteral {
    init(key: Key) {
        self.init(wrappedValue: nil, key: key)
    }
}

extension UserDefault {
    
    enum Key: String {
        case qr
        case didAlreadyRequestInitialData
    }

}
