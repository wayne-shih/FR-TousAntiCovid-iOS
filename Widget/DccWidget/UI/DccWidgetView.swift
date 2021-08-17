// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DccWidgetView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/07/2021 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct DccWidgetView: View {
    var entry: DccWidgetContent
    
    var body: some View {
        if let data = entry.certificateQRCodeData {
            if let image = UIImage(data: data) {
                QRCodeView(content: entry, image: image)
            } else {
                EmptyDccView(content: entry)
            }
        } else {
            EmptyDccView(content: entry)
        }
    }
}

struct DccWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        let textContent: String = "Ajoutez ici votre certificat favori en appuyant sur l'icône ❤️ sur le certificat (au format européen) souhaité."
        let textBottom: String = "Appuyez pour passer en plein écran"
        DccWidgetView(entry: DccWidgetContent(date: Date(), certificateQRCodeData: UIImage(named: "qrCodeVaccin")?.jpegData(compressionQuality: 1.0), noCertificatText: textContent, bottomText: textBottom))
    }
}