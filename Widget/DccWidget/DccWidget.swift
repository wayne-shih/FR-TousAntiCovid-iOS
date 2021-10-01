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
        .supportedFamilies([.systemLarge, .systemMedium])
    }

}

struct DccProvider: TimelineProvider {
    public typealias Entry = DccWidgetContent
    
    func getSnapshot(in context: Context, completion: @escaping (DccWidgetContent) -> ()) { completion(createEntry(Date())) }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DccWidgetContent>) -> Void) {
        let date: Date
        if let timestamp = WidgetDCCManager.shared.certificateActivityExpiryTimestamp, timestamp > Date().timeIntervalSince1970 {
            WidgetDCCManager.shared.currentlyDisplayedActivityCertificateTimestamp = timestamp
            date = Date(timeIntervalSince1970: timestamp)
        } else {
            WidgetDCCManager.shared.currentlyDisplayedActivityCertificateTimestamp = nil
            date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!.addingTimeInterval(24.0 * 3600.0)
        }
        let remainingTime: Double = date.timeIntervalSince1970 - Date().timeIntervalSince1970
        let adjustedEndDate: Date = date.addingTimeInterval(remainingTime > 3600.0 ? -20.0 * 60.0 : 0.0)
        let entry: DccWidgetContent = createEntry(adjustedEndDate)
        let timeline: Timeline = Timeline(entries: [entry], policy: .after(adjustedEndDate))
        completion(timeline)
    }

    func placeholder(in context: Context) -> DccWidgetContent { createEntry(Date()) }

    private func createEntry(_ date: Date) -> DccWidgetContent {
        DccWidgetContent(date: date,
                         certificateQRCodeData: WidgetDCCManager.shared.certificateQrCodeData,
                         certificateActivityQrCodeData: WidgetDCCManager.shared.certificateActivityQrCodeData,
                         certificateActivityExpiryTimestamp: WidgetDCCManager.shared.certificateActivityExpiryTimestamp,
                         noCertificatText: WidgetDCCManager.shared.noCertificateText,
                         bottomText: WidgetDCCManager.shared.bottomText,
                         bottomTextActivityPass: WidgetDCCManager.shared.bottomTextActivityPass)
    }

}
