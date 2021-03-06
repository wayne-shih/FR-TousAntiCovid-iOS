// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StatusWidget.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct StatusWidget: Widget {

    private let kind: String = "fr.gouv.stopcovid.ios.Widget.status"

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatusProvider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("TousAntiCovid")
        .description(NSLocalizedString("widget.status.description", comment: ""))
        .supportedFamilies([.systemSmall, .systemMedium])
    }

}

struct StatusProvider: TimelineProvider {
    public typealias Entry = WidgetContent
    
    @WidgetUserDefault(key: .isProximityActivated)
    private var isProximityActivated: Bool = false
    
    @WidgetUserDefault(key: .isSick)
    private var isSick: Bool = false
    
    @WidgetUserDefault(key: .lastStatusReceivedDate)
    private var lastStatusReceivedDate: Date? = nil

    @WidgetUserDefault(key: .currentRiskLevel)
    private var currentRiskLevel: Double?

    func getSnapshot(in context: Context, completion: @escaping (WidgetContent) -> Void) {
        let entry: WidgetContent = WidgetContent(isProximityActivated: isProximityActivated, isSick: isSick, lastStatusReceivedDate: lastStatusReceivedDate, currentRiskLevel: currentRiskLevel)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetContent>) -> Void) {
        let entry: WidgetContent? = WidgetContent(isProximityActivated: isProximityActivated, isSick: isSick, lastStatusReceivedDate: lastStatusReceivedDate, currentRiskLevel: currentRiskLevel)
        
        var tomorrow: Date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        tomorrow.addTimeInterval(24.0 * 3600.0)
        
        let timeline = Timeline(entries: [entry].compactMap { $0 }, policy: .after(tomorrow))
        
        completion(timeline)
    }
    
    func placeholder(in context: Context) -> WidgetContent {
        WidgetContent(isProximityActivated: true, isSick: false, lastStatusReceivedDate: Date(), currentRiskLevel: currentRiskLevel)
    }
}
