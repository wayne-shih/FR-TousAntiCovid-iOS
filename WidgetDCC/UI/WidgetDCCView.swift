// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WidgetDCCView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/07/2021 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct WidgetDCCView: View {
    var entry: WidgetDCCContent
    
    var body: some View {
        if let data = entry.certificateQRCodeData {
            if let image = UIImage(data: data) {
                DCCWidgetView(content: entry, image: image)
            } else {
                EmptyDCCView(content: entry)
            }
        } else {
            EmptyDCCView(content: entry)
        }
    }
}

struct WidgetDCCView_Previews: PreviewProvider {
    static var previews: some View {
        let textContent: String = "Ajoutez ici votre certificat favori en appuyant sur l'icône ❤️ sur le certificat (au format européen) souhaité."
        let textBottom: String = "Appuyez pour passer en plein écran"
        WidgetDCCView(entry: WidgetDCCContent(date: Date(), certificateQRCodeData: UIImage(named: "qrCodeVaccin")?.jpegData(compressionQuality: 1.0), noCertificatText: textContent, bottomText: textBottom))
    }
}
