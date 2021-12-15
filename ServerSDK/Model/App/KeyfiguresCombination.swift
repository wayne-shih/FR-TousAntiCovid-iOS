// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyfiguresCombination.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 07/12/2021 - for the TousAntiCovid project.
//

import Foundation

public struct KeyfiguresCombination: Codable {
    public let titleKey: String
    
    public var keyFigure1Key: String { "keyfigure." + keyFigure1RawKey }
    public var keyFigure2Key: String { "keyfigure." + keyFigure2RawKey }
    
    private let keyFigure1RawKey: String
    private let keyFigure2RawKey: String
    
    enum CodingKeys: String, CodingKey {
        case titleKey = "t"
        case keyFigure1RawKey = "k1"
        case keyFigure2RawKey = "k2"
    }
}
