// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  HeaderView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/07/2021 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct HeaderView: View {

    var separatorColor : Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image("icon_tousAntiCovid")
                    .resizable()
                    .frame(width: 32, height: 32)
                Text("TousAntiCovid")
                    .font(SwiftUI.Font(FontFamily.Marianne.bold.font(size: 17)))
            }
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            Rectangle()
                .fill(separatorColor)
                .frame(height: 0.5)
        }.unredacted()
        
    }
}
