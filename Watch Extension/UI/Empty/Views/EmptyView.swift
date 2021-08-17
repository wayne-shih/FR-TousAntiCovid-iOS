// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  EmptyView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 05/08/2021 - for the TousAntiCovid project.
//

import SwiftUI

struct EmptyView: View {

    var body: some View {
        VStack(alignment: .center, spacing: 12.0) {
            Spacer()
            Image(uiImage: UIImage(named: "passSanitaire")!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 30, alignment: .center)
            Text(NSLocalizedString("emptyController.message", comment: ""))
                .font(.footnote)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct EmptyView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}
