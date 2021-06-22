// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SVUserDefaultsPropertyWrapper.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 03/06/2021 - for the TousAntiCovid project.
//

import Foundation

@propertyWrapper
struct SVUserDefault<T> {

    private var defaults: UserDefaults
    private let key: String
    private let defaultValue: T

    var projectedValue: String { key }

    var wrappedValue: T {
        get { defaults.object(forKey: key) as? T ?? defaultValue }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                defaults.removeObject(forKey: key)
            } else {
                defaults.set(newValue, forKey: key)
            }
            defaults.synchronize()
        }
    }

    init(wrappedValue: T, key: String, userDefault: UserDefaults = .server) {
        self.defaultValue = wrappedValue
        self.key = key
        self.defaults = userDefault
    }

}

extension SVUserDefault where T: ExpressibleByNilLiteral {
    init(key: String) {
        self.init(wrappedValue: nil, key: key)
    }
}
