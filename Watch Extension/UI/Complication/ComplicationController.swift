// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ComplicationController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 30/07/2021 - for the TousAntiCovid project.
//

import ClockKit
import SwiftUI

final class ComplicationController: NSObject, CLKComplicationDataSource {

    // MARK: - Complication Configuration
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors: [CLKComplicationDescriptor] = [
            CLKComplicationDescriptor(identifier: "complication", displayName: NSLocalizedString("complication.favorite.displayName" , comment: ""), supportedFamilies: [.circularSmall, .graphicCorner, .graphicCircular, .utilitarianSmall])
        ]
        handler(descriptors)
    }

    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {}

    // MARK: - Timeline Configuration
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }

    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        if let template = getComplicationTemplate(for: complication) {
            let entry: CLKComplicationTimelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
        } else {
            handler(nil)
        }
    }

    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }

    // MARK: - Sample Templates
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(getComplicationTemplate(for: complication))
    }

}

extension ComplicationController {

    private func getComplicationTemplate(for complication: CLKComplication) -> CLKComplicationTemplate? {
        switch complication.family {
        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Corner")!))
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Circular")!))
        case .circularSmall:
            return CLKComplicationTemplateCircularSmallSimpleImage(imageProvider: CLKImageProvider(onePieceImage: UIImage(named: "Complication/Circular")!))
        case .utilitarianSmall:
            return CLKComplicationTemplateUtilitarianSmallSquare(imageProvider: CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!))
        default:
            return nil
        }
    }

}
