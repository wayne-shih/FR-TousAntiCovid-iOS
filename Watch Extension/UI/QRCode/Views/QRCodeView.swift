// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  QRCodeView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 05/08/2021 - for the TousAntiCovid project.
//

import SwiftUI

struct QRCodeView: View {

    let qrCodeData: Data

    var body: some View {
        ZStack(alignment: .center) {
            if let image = UIImage(data: qrCodeData) {
                Color(.white)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color(.clear))
                    .padding(20.0)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
    }
}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView(qrCodeData: Data())
    }
}
