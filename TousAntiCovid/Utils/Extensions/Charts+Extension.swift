// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ChartsExtension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/01/2021 - for the TousAntiCovid project.
//

import Foundation
import Charts

// MARK: - ChartViewBase -
extension ChartViewBase {

    static func create(chartDatas: [KeyFigureChartData], allowInteractions: Bool) -> ChartViewBase? {
        guard let chartData = chartDatas.first else { return nil }
        switch chartData.chartKind {
        case .line:
            return LineChartView.createLineChart(chartDatas: chartDatas, allowInteractions: allowInteractions)
        case .bars:
            return BarChartView.createBarChart(chartDatas: chartDatas, allowInteractions: allowInteractions)
        }
    }

}

// MARK: - Line chart -
private extension LineChartView {

    static func createLineChart(chartDatas: [KeyFigureChartData], allowInteractions: Bool) -> LineChartView {
        let dataSets: [LineChartDataSet] = chartDatas.map {
            let entries: [ChartDataEntry] = $0.series.map { ChartDataEntry(x: $0.date, y: $0.value, data: $0.date) }
            let dataSet: LineChartDataSet = LineChartDataSet(entries: entries)
            dataSet.setupStyle(color: $0.legend.color, entriesCount: entries.count)
            return dataSet
        }
        let lineChartView: LineChartView = LineChartView()
        lineChartView.data = LineChartData(dataSets: dataSets)
        lineChartView.setupStyle(allowInteractions: allowInteractions)
        lineChartView.leftAxis.setupStyle()
        lineChartView.leftAxis.valueFormatter = ChartsValueFormatter()

        let minTodayValue: Double = chartDatas.min { $0.minValue < $1.minValue }?.minValue ?? 0.0
        let maxTodayValue: Double = chartDatas.max { $0.maxValue < $1.maxValue }?.maxValue ?? 0.0

        lineChartView.leftAxis.axisMinimum = max(0.0, minTodayValue - (maxTodayValue - minTodayValue) * 0.1)

        lineChartView.xAxis.setupStyle()
        lineChartView.xAxis.valueFormatter = ChartsDateFormatter()

        chartDatas.forEach {
            guard $0.limitLineValue != nil && $0.limitLineValue != 0.0 else { return }
            lineChartView.leftAxis.addLimitLine(ChartLimitLine.create(chartData: $0, position: .topLeft))
        }

        let yAxisRenderer: YAxisCustomRenderer = YAxisCustomRenderer(
            viewPortHandler: lineChartView.viewPortHandler,
            yAxis: lineChartView.leftAxis,
            transformer: lineChartView.getTransformer(forAxis: .left)
        )
        lineChartView.leftYAxisRenderer = yAxisRenderer
        if allowInteractions { lineChartView.marker = MarkerView(chartView: lineChartView) }

        return lineChartView
    }

    func setupStyle(allowInteractions: Bool = false) {
        legend.enabled = false
        chartDescription?.enabled = false
        isUserInteractionEnabled = allowInteractions
        extraBottomOffset = 16.0
        rightAxis.enabled = false
        pinchZoomEnabled = false
        dragEnabled = allowInteractions
        doubleTapToZoomEnabled = false
        highlightPerTapEnabled = allowInteractions
        scaleYEnabled = false
    }

}

private extension LineChartDataSet {

    var defaultCircleWidth: CGFloat { 4.0 }
    var minCircleWidth: CGFloat { 1.75 }
    var circleResizingThreshold: Int { 25 }
    var circleWidthFactorFromLineWidth: CGFloat { 2.0 }

    func setupStyle(color: UIColor, entriesCount: Int) {
        drawValuesEnabled = false
        circleRadius = ((defaultCircleWidth * CGFloat(circleResizingThreshold)) / CGFloat(entriesCount)).clamped(to: minCircleWidth...defaultCircleWidth)
        lineWidth = circleRadius / circleWidthFactorFromLineWidth
        setColor(color)
        setCircleColor(color)
        drawCircleHoleEnabled = false
        drawHorizontalHighlightIndicatorEnabled = false
        drawVerticalHighlightIndicatorEnabled = false
    }

}

// MARK: - Bar chart -
private extension BarChartView {

    static func createBarChart(chartDatas: [KeyFigureChartData], allowInteractions: Bool) -> BarChartView {
        let dataSets: [BarChartDataSet] = chartDatas.map {
            let entries: [BarChartDataEntry] = $0.series.map { BarChartDataEntry(x: $0.date, y: $0.value, data: $0.date) }
            let dataSet: BarChartDataSet = BarChartDataSet(entries: entries)
            dataSet.setupStyle(color: $0.legend.color, entriesCount: entries.count)
            return dataSet
        }
        let barChartView: BarChartView = BarChartView()
        let data: BarChartData = BarChartData(dataSets: dataSets)
        data.setupStyle(entriesCount: dataSets.first?.entries.count ?? 0)
        barChartView.data = data
        barChartView.setupStyle(allowInteractions: allowInteractions)
        barChartView.leftAxis.setupStyle()
        barChartView.leftAxis.valueFormatter = ChartsValueFormatter()

        barChartView.leftAxis.axisMinimum = 0.0
        barChartView.xAxis.setupStyle()
        barChartView.xAxis.valueFormatter = ChartsDateFormatter()

        chartDatas.forEach {
            guard $0.limitLineValue != nil && $0.limitLineValue != 0.0 else { return }
            barChartView.leftAxis.addLimitLine(ChartLimitLine.create(chartData: $0, position: .topLeft))
        }

        let yAxisRenderer: YAxisCustomRenderer = YAxisCustomRenderer(
            viewPortHandler: barChartView.viewPortHandler,
            yAxis: barChartView.leftAxis,
            transformer: barChartView.getTransformer(forAxis: .left)
        )
        barChartView.leftYAxisRenderer = yAxisRenderer
        barChartView.fitBars = true
        if allowInteractions { barChartView.marker = MarkerView(chartView: barChartView) }

        return barChartView
    }

    func setupStyle(allowInteractions: Bool = false) {
        legend.enabled = false
        chartDescription?.enabled = false
        isUserInteractionEnabled = allowInteractions
        extraTopOffset = 10.0
        extraBottomOffset = 16.0
        rightAxis.enabled = false
        minOffset = 0.0
        pinchZoomEnabled = false
        dragEnabled = allowInteractions
        doubleTapToZoomEnabled = false
        highlightPerTapEnabled = allowInteractions
        scaleYEnabled = false
    }

}

private extension BarChartDataSet {

    func setupStyle(color: UIColor, entriesCount: Int) {
        drawValuesEnabled = false
        colors = [color]
    }

}

private extension BarChartData {

    func setupStyle(entriesCount: Int) {
        let xValuesDiff: Double = xMax - xMin
        let spacing: Double = 0.05
        barWidth = xValuesDiff / Double(entriesCount) - (spacing * xValuesDiff / Double(entriesCount + 1))
    }

}


// MARK: - Axis -
private extension YAxis {

    func setupStyle() {
        drawAxisLineEnabled = false
        drawLabelsEnabled = true
        drawGridLinesEnabled = true
        gridColor = .lightGray
        setLabelCount(3, force: true)
        labelFont = Appearance.Cell.Text.subtitleFont
        labelTextColor = .gray
        drawTopYLabelEntryEnabled = true
        drawZeroLineEnabled = true
    }

}

private extension XAxis {

    func setupStyle() {
        labelPosition = .bottom
        drawAxisLineEnabled = true
        drawLabelsEnabled = true
        drawGridLinesEnabled = false
        avoidFirstLastClippingEnabled = true
        setLabelCount(2, force: true)
        labelFont = Appearance.Cell.Text.subtitleFont
        labelTextColor = .gray
    }

}

private extension ChartLimitLine {

    static func create(chartData: KeyFigureChartData, position: ChartLimitLine.LabelPosition) -> ChartLimitLine {
        let limiteLine: ChartLimitLine = ChartLimitLine(limit: chartData.limitLineValue ?? 0.0, label: chartData.limitLineLabel?.formattingValueWithThousandsSeparatorIfPossible() ?? "")
        limiteLine.labelPosition = position
        limiteLine.lineColor = chartData.legend.color
        limiteLine.valueTextColor = chartData.legend.color
        limiteLine.valueFont = Appearance.Cell.Text.accessoryFont
        limiteLine.lineWidth = 2.0
        limiteLine.lineDashLengths = [4.0, 5.0]
        limiteLine.xOffset = 0.0
        limiteLine.yOffset = 0.0
        return limiteLine
    }

}
