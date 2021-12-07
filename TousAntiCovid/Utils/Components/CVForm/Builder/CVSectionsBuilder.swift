// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVSectionsBuilder.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 03/11/2021 - for the TousAntiCovid project.
//

import Foundation

@resultBuilder
struct CVSectionsBuilder {
    static func buildBlock(_ sections: CVSectionConvertible...) -> [CVSection] { sections.flatMap { $0.asSections() } }
    static func buildIf(_ value: CVSectionConvertible?) -> CVSectionConvertible { value ?? [] }
    static func buildEither(first: CVSectionConvertible) -> CVSectionConvertible { first }
    static func buildEither(second: CVSectionConvertible) -> CVSectionConvertible { second }
}

protocol CVSectionConvertible {
    func asSections() -> [CVSection]
}

extension CVSection: CVSectionConvertible {
    struct Empty: CVSectionConvertible {
        func asSections() -> [CVSection] { [] }
    }

    func asSections() -> [CVSection] { [self] }
}



extension Array: CVSectionConvertible where Element == CVSection {
    func asSections() -> [CVSection] { self }
}
