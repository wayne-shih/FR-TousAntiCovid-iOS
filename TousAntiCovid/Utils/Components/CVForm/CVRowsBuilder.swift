// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVRowsBuilder.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 17/08/2021 - for the TousAntiCovid project.
//

import Foundation

@resultBuilder
struct CVRowsBuilder {
    static func buildBlock(_ rows: CVRowConvertible...) -> [CVRow] { rows.flatMap { $0.asRows() } }
    static func buildIf(_ value: CVRowConvertible?) -> CVRowConvertible { value ?? [] }
    static func buildEither(first: CVRowConvertible) -> CVRowConvertible { first }
    static func buildEither(second: CVRowConvertible) -> CVRowConvertible { second }
}

protocol CVRowConvertible {
    func asRows() -> [CVRow]
}

extension CVRow: CVRowConvertible {
    func asRows() -> [CVRow] { [self] }
}

extension Array: CVRowConvertible where Element == CVRow {
    func asRows() -> [CVRow] { self }
}
