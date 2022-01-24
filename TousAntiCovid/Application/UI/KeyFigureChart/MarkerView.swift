// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MarkerView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 01/09/2021 - for the TousAntiCovid project.
//

import UIKit
import Charts

final class MarkerView: MarkerImage {
    private let arrowSize: CGSize = CGSize(width: 15, height: 11)
    private let insets: UIEdgeInsets
    private let minimumSize: CGSize
    
    private var label: String?
    private var labelSize: CGSize = CGSize()
    private let paragraphStyle: NSMutableParagraphStyle?
    private var drawAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key: Any]()
    private var fillColor: UIColor = Appearance.tintColor

    init(chartView: ChartViewBase) {
        self.insets = UIEdgeInsets(top: 7.0, left: 7.0, bottom: 18.0, right: 7.0)
        self.minimumSize = CGSize(width: 60.0, height: 35.0)
        paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        paragraphStyle?.alignment = .center
        super.init()
        self.chartView = chartView
    }
    
     override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
        var offset: CGPoint = self.offset
        let size: CGSize = self.size
        let padding: CGFloat = 8.0

        var origin: CGPoint = point
        origin.x -= size.width / 2
        origin.y -= size.height

        if origin.x + offset.x < 0 {
            offset.x = -origin.x + padding
        } else if let chart = chartView, origin.x + size.width + offset.x > chart.bounds.size.width {
            offset.x = chart.bounds.size.width - origin.x - size.width - padding
        }

        if origin.y + offset.y < 0 {
            offset.y = size.height
        } else if let chart = chartView, origin.y + size.height + offset.y > chart.bounds.size.height {
            offset.y = chart.bounds.size.height - origin.y - size.height - padding
        }
        return offset
    }
    
    override func draw(context: CGContext, point: CGPoint) {
        guard let label = label else { return }
        let offset: CGPoint = self.offsetForDrawing(atPoint: point)
        
        var rect: CGRect = CGRect(origin: CGPoint(x: point.x + offset.x, y: point.y + offset.y), size: size)
        rect.origin.x -= size.width / 2.0
        rect.origin.y -= size.height
        
        context.saveGState()
        context.setFillColor(fillColor.cgColor)
        context.beginPath()
        if offset.y > 0 {
            context.addPath(UIBezierPath(roundedRect: CGRect(x: rect.origin.x,
                                                             y: rect.origin.y + arrowSize.height,
                                                             width: rect.size.width,
                                                             height: rect.size.height - arrowSize.height),
                                         cornerRadius: 5).cgPath)

            context.move(to: CGPoint(x: rect.origin.x + (rect.size.width - arrowSize.width) / 2.0,
                                     y: rect.origin.y + arrowSize.height))
            context.addLine(to: CGPoint(x: point.x,
                                        y: point.y))
            context.addLine(to: CGPoint(x: rect.origin.x + (rect.size.width + arrowSize.width) / 2.0,
                                        y: rect.origin.y + arrowSize.height))
        } else {
            context.addPath(UIBezierPath(roundedRect: CGRect(x: rect.origin.x,
                                                             y: rect.origin.y,
                                                             width: rect.size.width,
                                                             height: rect.size.height - arrowSize.height),
                                         cornerRadius: 5).cgPath)

            context.move(to: CGPoint(x: rect.origin.x + (rect.size.width + arrowSize.width) / 2.0,
                                     y: rect.origin.y + rect.size.height - arrowSize.height))
            context.addLine(to: CGPoint(x: point.x,
                                        y: point.y))
            context.addLine(to: CGPoint(x: rect.origin.x + (rect.size.width - arrowSize.width) / 2.0,
                                        y: rect.origin.y + rect.size.height - arrowSize.height))
        }
        context.fillPath()

        rect.origin.y += self.insets.top
        if offset.y > 0 { rect.origin.y += arrowSize.height }
        rect.size.height -= self.insets.top + self.insets.bottom
        UIGraphicsPushContext(context)
        label.draw(in: rect, withAttributes: drawAttributes)
        UIGraphicsPopContext()
        context.restoreGState()
    }
    
    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        var string: String = ChartsValueFormatter().stringForValue(entry.y, axis: nil)
        if let color = chartView?.data?.getDataSetForEntry(entry)?.colors.first {
            fillColor = color
        }
        if let timestamp = entry.data as? Double {
            string += "\n\(ChartsDateFormatter().stringForValue(timestamp, axis: nil))"
        }
        setLabel(string)
    }
    
    private func setLabel(_ newLabel: String) {
        drawAttributes.removeAll()
        drawAttributes[.font] = UIFont.semibold(size: 11.0)
        drawAttributes[.paragraphStyle] = paragraphStyle
        drawAttributes[.foregroundColor] = Appearance.Button.Primary.titleColor
        
        label = newLabel
        labelSize = label?.size(withAttributes: drawAttributes) ?? CGSize.zero
        
        self.size = CGSize(width: max(minimumSize.width, labelSize.width + self.insets.left + self.insets.right),
                           height: max(minimumSize.height, labelSize.height + self.insets.top + self.insets.bottom))
    }
}
