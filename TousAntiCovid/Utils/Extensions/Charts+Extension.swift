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
    
    static func create(chartData1: KeyFigureChartData, chartData2: KeyFigureChartData, sameOrdinate: Bool,  allowInteractions: Bool) -> ChartViewBase {
        if chartData1.chartKind == .bars && chartData2.chartKind == .bars {
            return BarLineChartViewBase.createBarsChart(chartData1: chartData1, chartData2: chartData2, sameOrdinate: sameOrdinate, allowInteractions: allowInteractions)
        } else {
            return BarLineChartViewBase.createCombinedChart(chartData1: chartData1, chartData2: chartData2, sameOrdinate: sameOrdinate, allowInteractions: allowInteractions)
        }
    }

}

// MARK: - Combined chart -
private extension BarLineChartViewBase {
    
    static func createBarsChart(chartData1: KeyFigureChartData, chartData2: KeyFigureChartData, sameOrdinate: Bool, allowInteractions: Bool) -> BarChartView {
        let entries1: [ChartDataEntry] = chartData1.series.map { BarChartDataEntry(x: $0.date, y: $0.value, data: $0.date) }
        let dataSet1: BarChartDataSet = BarChartDataSet(entries: entries1)
        dataSet1.setupStyle(color: chartData1.legend.color, entriesCount: entries1.count)
        
        let entries2: [ChartDataEntry] = chartData2.series.map { BarChartDataEntry(x: $0.date, y: $0.value, data: $0.date) }
        let dataSet2: BarChartDataSet = BarChartDataSet(entries: entries2)
        dataSet2.setupStyle(color: chartData2.legend.color, entriesCount: entries2.count)
        if !sameOrdinate {
            dataSet2.axisDependency = .right
        }
        
        let groupSpace = 0.08
        let barSpace = 0.03
        let barWidth = 0.2
        let groupsCount: Int = min(entries1.count, entries2.count)
        let xStart: Double = max(entries1.first?.x ?? 0.0, entries2.first?.x ?? 0.0)
        
        let barChartView: BarChartView = BarChartView()
        let data: BarChartData = BarChartData(dataSets: [dataSet1, dataSet2])
        data.barWidth = barWidth
        data.groupBars(fromX: xStart, groupSpace: groupSpace, barSpace: barSpace)
        barChartView.data = data
        
        barChartView.xAxis.axisMinimum = xStart
        barChartView.xAxis.axisMaximum = xStart + data.groupWidth(groupSpace: groupSpace, barSpace: barSpace) * Double(groupsCount)
        
        barChartView.setupFor(chartData1: chartData1, chartData2: chartData2, sameOrdinate: sameOrdinate, allowInteractions: allowInteractions)
        barChartView.fitBars = true
        
        return barChartView
    }
    
    static func createCombinedChart(chartData1: KeyFigureChartData, chartData2: KeyFigureChartData, sameOrdinate: Bool, allowInteractions: Bool) -> CombinedChartView {
        let entries1: [ChartDataEntry] = chartData1.chartKind == .line ? chartData1.series.map { ChartDataEntry(x: $0.date, y: $0.value, data: $0.date) } : chartData1.series.map { BarChartDataEntry(x: $0.date, y: $0.value, data: $0.date) }
        let dataSet1: ChartDataSet = chartData1.chartKind == .line ? LineChartDataSet(entries: entries1) : BarChartDataSet(entries: entries1)
        dataSet1.setupStyle(color: chartData1.legend.color, entriesCount: entries1.count)
        
        let entries2: [ChartDataEntry] = chartData2.chartKind == .line ? chartData2.series.map { ChartDataEntry(x: $0.date, y: $0.value, data: $0.date) } : chartData2.series.map { BarChartDataEntry(x: $0.date, y: $0.value, data: $0.date) }
        let dataSet2: ChartDataSet = chartData2.chartKind == .line ? LineChartDataSet(entries: entries2) : BarChartDataSet(entries: entries2)
        dataSet2.setupStyle(color: chartData2.legend.color, entriesCount: entries2.count)
        if !sameOrdinate {
            dataSet2.axisDependency = .right
        }
        
        let chartView: CombinedChartView = CombinedChartView()
        let data: CombinedChartData = CombinedChartData()
        
        let lineDataSets: [LineChartDataSet] = [dataSet1, dataSet2].compactMap { $0 as? LineChartDataSet }
        if !lineDataSets.isEmpty {
            data.lineData = LineChartData(dataSets: lineDataSets)
        }
        
        let barDataSets: [BarChartDataSet] = [dataSet1, dataSet2].compactMap { $0 as? BarChartDataSet }
        if !barDataSets.isEmpty {
            let barData: BarChartData = BarChartData(dataSets: barDataSets)
            barData.setupStyle(entriesCount: barDataSets.first?.entries.count ?? 0)
            data.barData = barData
            chartView.xAxis.spaceMin = 12*3600
            chartView.xAxis.spaceMax = 12*3600
        }
        
        chartView.setupFor(chartData1: chartData1, chartData2: chartData2, sameOrdinate: sameOrdinate, allowInteractions: allowInteractions)
        chartView.data = data
        
        return chartView
    }
    
    func setupFor(chartData1: KeyFigureChartData, chartData2: KeyFigureChartData, sameOrdinate: Bool, allowInteractions: Bool) {
        setupStyle(allowInteractions: allowInteractions, withRightAxis: !sameOrdinate)
        xAxis.setupStyle()
        xAxis.valueFormatter = ChartsDateFormatter()
        
        let minValue1: Double = chartData1.minValue
        let maxValue1: Double = chartData1.maxValue
        let minValue2: Double = chartData2.minValue
        let maxValue2: Double = chartData2.maxValue
        
        leftAxis.setupStyle(color: chartData1.legend.color)
        leftAxis.valueFormatter = ChartsValueFormatter()
        rightAxis.setupStyle(color: chartData2.legend.color)
        rightAxis.valueFormatter = ChartsValueFormatter()
        
        if sameOrdinate {
            leftAxis.setupStyle(color: .gray)
            leftAxis.axisMinimum = min(minValue1, minValue2)
            leftAxis.axisMaximum = max(0.0, max(maxValue1 + (maxValue1 - minValue1) * 0.1, maxValue2 + (maxValue2 - minValue2) * 0.1))
        } else {
            leftAxis.axisMinimum = 0.0
            rightAxis.axisMinimum = 0.0
            leftAxis.axisMaximum = max(0.0, maxValue1 + (maxValue1 - minValue1) * 0.1)
            rightAxis.axisMaximum = max(0.0, maxValue2 + (maxValue2 - minValue2) * 0.1)
        }
        
        let yLeftAxisRenderer: YAxisCustomRenderer = YAxisCustomRenderer(
            viewPortHandler: viewPortHandler,
            yAxis: leftAxis,
            transformer: getTransformer(forAxis: .left)
        )
        leftYAxisRenderer = yLeftAxisRenderer
        
        let yRightAxisRenderer: YAxisCustomRenderer = YAxisCustomRenderer(
            viewPortHandler: viewPortHandler,
            yAxis: rightAxis,
            transformer: getTransformer(forAxis: .right)
        )
        rightYAxisRenderer = yRightAxisRenderer
        
        if allowInteractions { marker = MarkerView(chartView: self) }
    }

    func setupStyle(allowInteractions: Bool = false, withRightAxis: Bool = false) {
        legend.enabled = false
        chartDescription?.enabled = false
        isUserInteractionEnabled = allowInteractions
        extraBottomOffset = 16.0
        rightAxis.enabled = withRightAxis
        pinchZoomEnabled = false
        dragEnabled = allowInteractions
        doubleTapToZoomEnabled = false
        highlightPerTapEnabled = allowInteractions
        scaleYEnabled = false
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

private extension ChartDataSet {
    @objc func setupStyle(color: UIColor, entriesCount: Int) { }
}

private extension LineChartDataSet {

    var defaultCircleWidth: CGFloat { 4.0 }
    var minCircleWidth: CGFloat { 1.75 }
    var circleResizingThreshold: Int { 25 }
    var circleWidthFactorFromLineWidth: CGFloat { 2.0 }

    @objc override func setupStyle(color: UIColor, entriesCount: Int) {
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

    @objc override func setupStyle(color: UIColor, entriesCount: Int) {
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

    func setupStyle(color: UIColor? = nil) {
        drawAxisLineEnabled = false
        drawLabelsEnabled = true
        drawGridLinesEnabled = true
        gridColor = .lightGray
        setLabelCount(3, force: true)
        labelFont = Appearance.Cell.Text.subtitleFont
        labelTextColor = color ?? .gray
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
