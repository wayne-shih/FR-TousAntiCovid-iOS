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

    var image: UIImage
    var bottomText: String

    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack {
            HeaderView(separatorColor: Color("lightSeparator"))
            containerView {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Spacer(minLength: 10)
                Text(bottomText)
                    .font(SwiftUI.Font(FontFamily.SFProText.regular.font(size: 12)))
                    .lineLimit(3)
                    .multilineTextAlignment(family == .systemLarge ? .center : .leading)
                Spacer()
            }
        }
        .background(Color.white)
        .foregroundColor(.black)
    }

    @ViewBuilder
    func containerView<T: View>(@ViewBuilder content: () -> T) -> some View {
        if family == .systemLarge {
            Spacer(minLength: 20)
            VStack(alignment: .center, content: content)
            Spacer(minLength: 20)
        } else {
            Spacer()
            HStack(alignment: .center, content: content)
                .padding(EdgeInsets(top: 0.0, leading: 10.0, bottom: 0.0, trailing: 10.0))
            Spacer()
        }
    }
}
