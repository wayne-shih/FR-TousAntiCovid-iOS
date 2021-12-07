// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AlwaysOnAlwaysOnDccWidgetView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 22/10/2021 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct AlwaysOnDccWidgetView: View {
    var entry: DccWidgetContent
        
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            let isActivityPassStillValid: Bool = Date().timeIntervalSince1970 < entry.certificateActivityExpiryTimestamp ?? 0.0
            if let data = entry.certificateActivityQrCodeData, let image = UIImage(data: data), isActivityPassStillValid {
                QRCodeView(image: image, bottomText: entry.bottomTextActivityPass)
            } else if let data = entry.certificateQRCodeData, let image = UIImage(data: data) {
                QRCodeView(image: image, bottomText: entry.bottomText)
            } else {
                EmptyDccView(content: entry)
            }
        }
    }
}

struct AlwaysOnDccWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        let textContent: String = "Ajoutez ici votre certificat favori en appuyant sur l'icône ❤️ sur le certificat (au format européen) souhaité."
        let textBottom: String = "Appuyez pour passer en plein écran"
        AlwaysOnDccWidgetView(entry: DccWidgetContent(date: Date(),
                                              certificateQRCodeData: UIImage(named: "qrCodeVaccin")?.jpegData(compressionQuality: 1.0),
                                              noCertificatText: textContent,
                                              bottomText: textBottom,
                                              bottomTextActivityPass: "")
        )
    }
}
