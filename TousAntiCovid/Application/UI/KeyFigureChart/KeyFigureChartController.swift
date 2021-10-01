// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureChartController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 01/09/2021 - for the TousAntiCovid project.
//

import UIKit
import Charts

final class KeyFigureChartController: UIViewController {

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    @IBOutlet private var safeAreaContainerView: UIView!
    @IBOutlet private var chartContainerView: UIView!
    @IBOutlet private var legendStackView: UIStackView!
    @IBOutlet private var footerLabel: UILabel!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var zoomOutButton: UIButton!

    @IBOutlet private var topConstraint: NSLayoutConstraint!
    @IBOutlet private var bottomConstraint: NSLayoutConstraint!
    @IBOutlet private var leftConstraint: NSLayoutConstraint!
    @IBOutlet private var rightConstraint: NSLayoutConstraint!
    @IBOutlet private var widthConstraint: NSLayoutConstraint!
    @IBOutlet private var heightConstraint: NSLayoutConstraint!

    private var chartDatas: [KeyFigureChartData] = []
    private var dismissBlock: (() -> ())?
    private weak var chartView: ChartViewBase?

    static func controller(chartDatas: [KeyFigureChartData], dismissBlock: @escaping () -> ()) -> KeyFigureChartController {
        let chartController: KeyFigureChartController = UIStoryboard(name: "KeyFigureChart", bundle: nil).instantiateViewController(withIdentifier: "KeyFigureChartController") as! KeyFigureChartController
        chartController.chartDatas = chartDatas
        chartController.dismissBlock = dismissBlock
        return chartController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupContent()
        setupChart()
    }

    private func setupUI() {
        view.backgroundColor = Asset.Colors.background.color
        closeButton.setTitle("common.close".localized, for: .normal)
        closeButton.tintColor = Appearance.Cell.Text.titleColor
        zoomOutButton.setTitle("keyFigureChartController.zoomOut".localized, for: .normal)
        zoomOutButton.tintColor = Appearance.Cell.Text.titleColor
        zoomOutButton.isHidden = true
        footerLabel.font = Appearance.Cell.Text.captionTitleFont
        footerLabel.textColor = Appearance.Cell.Text.captionTitleColor
        legendStackView?.isUserInteractionEnabled = false

        let safeAreaInsets: UIEdgeInsets = UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
        topConstraint.constant = safeAreaInsets.right
        bottomConstraint.constant = safeAreaInsets.left
        leftConstraint.constant = safeAreaInsets.top == 0.0 ? 0.0 : max(safeAreaInsets.top - 20.0, 0.0)
        rightConstraint.constant = safeAreaInsets.bottom
        widthConstraint.constant = UIScreen.main.bounds.height
        heightConstraint.constant = UIScreen.main.bounds.width
        safeAreaContainerView.transform = CGAffineTransform(rotationAngle: .pi / 2.0)
    }

    private func setupContent() {
        legendStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let legendViews: [UIView] = chartDatas.map { LegendView.view(legend: $0.legend) }
        legendViews.forEach { legendStackView.addArrangedSubview($0) }
        footerLabel.text = chartDatas.first?.footer
    }

    private func setupChart() {
        guard let chartView = ChartViewBase.create(chartDatas: chartDatas, allowInteractions: true) else { return }
        chartView.delegate = self
        self.chartView = chartView
        chartContainerView.subviews.forEach { $0.removeFromSuperview() }
        chartContainerView.addSubview(chartView)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor, constant: 0.0).isActive = true
        chartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor, constant: 0.0).isActive = true
        chartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor, constant: 0.0).isActive = true
        chartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor, constant: 0.0).isActive = true
    }

    private func limiteLine(chartData: KeyFigureChartData, position: ChartLimitLine.LabelPosition) -> ChartLimitLine {
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

    @IBAction private func didTouchCloseButton(_ sender: Any) {
        dismissBlock?()
    }

    @IBAction private func didTouchZoomOutButton(_ sender: Any) {
        (chartView as? LineChartView ?? chartView as? BarChartView)?.fitScreen()
        zoomOutButton.isHidden = true
    }

}

extension KeyFigureChartController: ChartViewDelegate {

    func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        zoomOutButton.isHidden = (chartView as? LineChartView ?? chartView as? BarChartView)?.isFullyZoomedOut ?? true
    }

}
