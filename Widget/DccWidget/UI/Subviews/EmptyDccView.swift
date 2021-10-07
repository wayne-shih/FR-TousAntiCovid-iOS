// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  EmptyDccView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/07/2021 - for the TousAntiCovid project.
//

import SwiftUI

struct EmptyDccView: View {
    var content: DccWidgetContent
    
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        let padding: Double = family == .systemLarge ? 30 : 10
        let topPadding: Double = family == .systemLarge ? 20 : 0
        let logoSize: CGSize = family == .systemLarge ? CGSize(width: 140, height: 36) : CGSize(width: 70, height: 18)
        VStack(alignment: .center) {
            HeaderView(separatorColor: Color("separator"))
            Spacer(minLength: 0)
            containerView {
                Image("logoPS")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped()
                    .frame(width: logoSize.width, height: logoSize.height, alignment: .center)
                    .unredacted()
                Text(content.noCertificatText)
                    .multilineTextAlignment(family == .systemLarge ? .center : .leading)
                    .font(SwiftUI.Font(FontFamily.Marianne.bold.font(size: family == .systemLarge ? 15 : 13)))
                    .padding(EdgeInsets(top: topPadding, leading: padding, bottom: 0, trailing: padding))
                    .unredacted()
            }
            Spacer(minLength: 0)
        }
    }
    
    @ViewBuilder
    func containerView<T: View>(@ViewBuilder content: () -> T) -> some View {
        if family == .systemLarge {
            VStack(alignment: .center, content: content)
        } else {
            HStack(alignment: .center, content: content)
                .padding(EdgeInsets(top: 0.0, leading: 10.0, bottom: 0.0, trailing: 10.0))
        }
    }
}
