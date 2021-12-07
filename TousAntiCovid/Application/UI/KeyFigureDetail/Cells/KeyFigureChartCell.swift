// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureChartCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/01/2021 - for the TousAntiCovid project.
//

import UIKit
import Charts

final class KeyFigureChartCell: CardCell {

    @IBOutlet private var chartContainerView: UIView!
    @IBOutlet private var legendStackView: UIStackView!
    @IBOutlet private var footerLabel: UILabel!
    @IBOutlet private var sharingImageView: UIImageView!
    @IBOutlet weak var sharingButton: UIButton!

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
        setupContent(with: row)
        setupAccessibility()
    }

    func setupChartView(_ chartView: ChartViewBase) {
        chartContainerView.subviews.forEach { $0.removeFromSuperview() }
        chartContainerView.addSubview(chartView)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor, constant: 0.0).isActive = true
        chartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor, constant: 0.0).isActive = true
        chartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor, constant: 0.0).isActive = true
        chartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor, constant: 0.0).isActive = true
    }

    private func setupUI(with row: CVRow) {
        footerLabel.font = Appearance.Cell.Text.captionTitleFont
        footerLabel.textColor = Appearance.Cell.Text.captionTitleColor
        sharingImageView.image = Asset.Images.shareIcon.image
        sharingImageView.tintColor = Appearance.tintColor
        legendStackView?.isUserInteractionEnabled = false
    }

    private func setupContent(with row: CVRow) {
        legendStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let chartDatas = row.associatedValue as? [KeyFigureChartData] else { return }
        let legendViews: [UIView] = chartDatas.map { LegendView.view(legend: $0.legend) }
        legendViews.forEach { legendStackView.addArrangedSubview($0) }
        footerLabel.text = chartDatas.first?.footer
    }
        
    func captureWithoutFooter() -> UIImage? {
        footerLabel.isHidden = true
        let capture: UIImage? = capture()
        footerLabel.isHidden = false
        return capture
    }
    
    override func capture() -> UIImage? {
        sharingImageView.isHidden = true
        let image: UIImage = containerView.screenshot()!
        sharingImageView.isHidden = false
        let captureImageView: UIImageView = UIImageView(image: image)
        captureImageView.frame.size = CGSize(width: image.size.width / UIScreen.main.scale, height: image.size.height / UIScreen.main.scale)
        captureImageView.backgroundColor = Appearance.Cell.cardBackgroundColor
        return captureImageView.screenshot()
    }
    
    @IBAction private func didTouchSharingButton(_ sender: Any) {
        currentAssociatedRow?.selectionActionWithCell?(self)
    }

    override func setupAccessibility() {
        sharingButton?.isAccessibilityElement = true
        sharingButton?.accessibilityLabel = "accessibility.hint.keyFigureChart.share".localized
        containerView?.accessibilityLabel = "accessibility.hint.keyFigureChart.label".localized
        chartContainerView?.isAccessibilityElement = false
        legendStackView.isAccessibilityElement = false
        accessibilityElements = [footerLabel, sharingButton].compactMap { $0 }
    }

}
