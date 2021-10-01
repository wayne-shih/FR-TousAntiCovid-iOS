// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  TransformDocumentResponseContent.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 11/09/2021 - for the TousAntiCovid project.
//

import Foundation

public struct TransformDocumentResponseContent: Decodable {
    public let complete: Bool
    public let lightCertificates: [TransformDocumentLightCertificate]
}
