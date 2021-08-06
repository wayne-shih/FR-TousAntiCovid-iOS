// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  EmptyDCCView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/07/2021 - for the TousAntiCovid project.
//

import SwiftUI

struct EmptyDCCView: View {
    var content: WidgetDCCContent
    
    var body: some View {
        VStack(alignment: .center) {
            HeaderView(separatorColor: Color("separator"))
            Spacer()
            Image("logoPS")
                .frame(width: 140, height: 36, alignment: .center)
            Text(content.noCertificatText)
                .multilineTextAlignment(.center)
                .font(SwiftUI.Font(FontFamily.Marianne.bold.font(size: 15)))
                .padding(EdgeInsets(top: 20, leading: 30, bottom: 0, trailing: 30))
            Spacer()
        }
    }
}
