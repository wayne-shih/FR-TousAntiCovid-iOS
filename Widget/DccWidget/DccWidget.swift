// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DccWidget.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/07/2021 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct DccWidget: Widget {

    private let kind: String = "fr.gouv.stopcovid.ios.Widget.dcc"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DccProvider()) { entry in
            DccWidgetView(entry: entry)
        }
        .configurationDisplayName("TousAntiCovid")
        .description(NSLocalizedString("widget.favoriteCertificate.description", comment: ""))
        .supportedFamilies([.systemLarge])
    }

}

struct DccProvider: TimelineProvider {
    public typealias Entry = DccWidgetContent

    @WidgetDCCUserDefault(key: .bottomText)
    private var bottomText: String = ""
    
    @WidgetDCCUserDefault(key: .noCertificateText)
    var noCertificateText: String = ""
    
    @WidgetDCCUserDefault(key: .certificateQrCodeData)
    private var certificateQrCodeData: Data? = nil
    
    func getSnapshot(in context: Context, completion: @escaping (DccWidgetContent) -> ()) {
        let entry: DccWidgetContent = DccWidgetContent(date: Date(), certificateQRCodeData: certificateQrCodeData, noCertificatText: noCertificateText, bottomText: bottomText)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DccWidgetContent>) -> Void) {
        let entry: DccWidgetContent? = DccWidgetContent(date: Date(), certificateQRCodeData: certificateQrCodeData, noCertificatText: noCertificateText, bottomText: bottomText)
        var tomorrow: Date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        tomorrow.addTimeInterval(24.0 * 3600.0)
        let timeline = Timeline(entries: [entry].compactMap { $0 }, policy: .after(tomorrow))
        completion(timeline)
    }
    
    func placeholder(in context: Context) -> DccWidgetContent {
        DccWidgetContent(date: Date(), certificateQRCodeData: certificateQrCodeData, noCertificatText: noCertificateText, bottomText: bottomText)
    }
}
