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

struct QRCodeView: View {
    var content: DccWidgetContent
    var image: UIImage
    
    var body: some View {
        VStack {
            HeaderView(separatorColor: Color("lightSeparator"))
            Spacer(minLength: 18)
            VStack(alignment: .center) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Spacer(minLength: 10)
                Text(content.bottomText)
                    .font(SwiftUI.Font(FontFamily.SFProText.regular.font(size: 12)))
                Spacer(minLength: 14)
            }
        }
        .background(Color.white)
        .foregroundColor(.black)
    }
}
