// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WidgetDCC.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/07/2021 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

@main
struct WidgetDCC: Widget {
    private let kind: String = "WidgetDCC"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetDCCView(entry: entry)
        }
        .configurationDisplayName("TousAntiCovid")
        .description("Votre certificat favori")
        .supportedFamilies([.systemLarge])
    }
}

struct Provider: TimelineProvider {
    public typealias Entry = WidgetDCCContent

    @WidgetDCCUserDefault(key: .bottomText)
    private var bottomText: String = ""
    
    @WidgetDCCUserDefault(key: .noCertificateText)
    var noCertificateText: String = ""
    
    @WidgetDCCUserDefault(key: .certificateQrCodeData)
    private var certificateQrCodeData: Data? = nil
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetDCCContent) -> ()) {
        let entry: WidgetDCCContent = WidgetDCCContent(date: Date(), certificateQRCodeData: certificateQrCodeData, noCertificatText: noCertificateText, bottomText: bottomText)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetDCCContent>) -> Void) {
        let entry: WidgetDCCContent? = WidgetDCCContent(date: Date(), certificateQRCodeData: certificateQrCodeData, noCertificatText: noCertificateText, bottomText: bottomText)
        var tomorrow: Date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        tomorrow.addTimeInterval(24.0 * 3600.0)
        let timeline = Timeline(entries: [entry].compactMap { $0 }, policy: .after(tomorrow))
        completion(timeline)
    }
    
    func placeholder(in context: Context) -> WidgetDCCContent {
        WidgetDCCContent(date: Date(), certificateQRCodeData: certificateQrCodeData, noCertificatText: noCertificateText, bottomText: bottomText)
    }
}
