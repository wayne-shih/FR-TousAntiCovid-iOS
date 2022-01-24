// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFiguresComparisonController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 19/11/2021 - for the TousAntiCovid project.
//

import UIKit
import Charts

final class KeyFiguresComparisonController: CVTableViewController {
    
    // MARK: - Constants
    private let deinitBlock: () -> ()
    private let didTouchSharing: (_ chartImage: UIImage?) -> ()
    private let didTouchChart: (_ chartDatas: [KeyFigureChartData]) -> ()
    private let didTouchSelection: (_ currentSelection: [KeyFigure], _ selectionDidChange: @escaping ([KeyFigure]) -> ()) -> ()
    
    // MARK: - Variables
    private var currentChartRange: ChartRange = .year
    private var selectedKeyFigures: [KeyFigure] = [] {
        didSet {
            saveSelection()
            reloadUI()
        }
    }
    
    init(didTouchSharing: @escaping (_ chartImage: UIImage?) -> (),
         didTouchChart: @escaping (_ chartDatas: [KeyFigureChartData]) -> (),
         didTouchSelection: @escaping (_ currentSelection: [KeyFigure], _ selectionDidChange: @escaping ([KeyFigure]) -> ()) -> (),
         deinitBlock: @escaping () -> ()) {
        self.didTouchSharing = didTouchSharing
        self.didTouchSelection = didTouchSelection
        self.didTouchChart = didTouchChart
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
        selectedKeyFigures = KeyFiguresManager.shared.comparedKeyFigures
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        reloadUI()
    }
    
    deinit {
        deinitBlock()
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection(title: nil,
                      subtitle: "keyfigures.comparison.evolution.section.subtitle".localized) {
                if let row = rangeSelectionRow() { row }
                comparisonChartRow()
                comparisonButtonRow()
            }
        }
    }
}

// MARK: - UI
private extension KeyFiguresComparisonController {
    func initUI() {
        title = "keyfigures.comparison.screen.title".localized
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }
}

// MARK: - Actions
private extension KeyFiguresComparisonController {
    @objc func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    func showSelectionController() {
        didTouchSelection(selectedKeyFigures) { [weak self] newSelection in
            self?.selectedKeyFigures = newSelection
        }
    }
}

// MARK: - Rows
private extension KeyFiguresComparisonController {
    func comparisonChartRow() -> CVRow {
        guard selectedKeyFigures.count > 1 else { return CVRow(title: "common.error.unknown".localized, xibName: .standardCell) }
        let chartData: [KeyFigureChartData] = KeyFiguresManager.shared.generateComparisonChartData(between: selectedKeyFigures[0], and: selectedKeyFigures[1], daysCount: currentChartRange.rawValue, withFooter: "keyfigures.comparison.chart.footer".localized)
        let areComparable: Bool = selectedKeyFigures.haveSameMagnitude
        let chartView: ChartViewBase? = ChartViewBase.create(chartData1: chartData[0], chartData2: chartData[1], sameOrdinate: areComparable, allowInteractions: false)
        let data: [KeyFigureChartData] = KeyFiguresManager.shared.generateComparisonChartData(between: selectedKeyFigures[0], and: selectedKeyFigures[1], daysCount: currentChartRange.rawValue, withFooter: nil)
        return CVRow(xibName: .keyFigureChartCell,
                     theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                        topInset: Appearance.Cell.Inset.medium,
                                        bottomInset: .zero,
                                        textAlignment: .natural),
                     associatedValue: (chartData, chartView),
                     selectionActionWithCell: { [weak self] cell in
            self?.didTouchSharing((cell as? KeyFigureChartCell)?.captureWithoutFooter())
        },
                     selectionAction: { [weak self] _ in
            self?.didTouchChart(data)
        })
    }
    
    func comparisonButtonRow() -> CVRow {
        CVRow(title: "keyfigures.comparison.keyfiguresChoice.button.title".localized,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                 bottomInset: .zero,
                                 buttonStyle: .secondary),
              selectionAction: { [weak self] _ in
            self?.showSelectionController()
        })
    }
    
    func rangeSelectionRow() -> CVRow? {
        let seriesMinCount: Int = selectedKeyFigures.compactMap { $0.ascendingSeries?.count }.min() ?? 0
        var chartRanges: [ChartRange] = []
        if seriesMinCount > ChartRange.threeMonth.rawValue {
            chartRanges = [.year, .threeMonth, .month]
        } else if seriesMinCount > ChartRange.month.rawValue {
            chartRanges = [.threeMonth, .month]
        }
        guard !chartRanges.isEmpty else { return nil }
        return CVRow(segmentsTitles: chartRanges.map { "keyFigureDetailController.chartRange.segmentTitle.\($0.rawValue)".localized },
                     selectedSegmentIndex: chartRanges.firstIndex(of: currentChartRange) ?? 0,
                     xibName: .segmentedCell,
                     theme:  CVRow.Theme(backgroundColor: .clear,
                                         topInset: Appearance.Cell.Inset.small / 2,
                                         bottomInset: Appearance.Cell.Inset.small / 2,
                                         textAlignment: .natural,
                                         titleFont: { Appearance.SegmentedControl.selectedFont },
                                         subtitleFont: { Appearance.SegmentedControl.normalFont }),
                     segmentsActions: chartRanges.map { chartRange in
            { [weak self] in
                self?.currentChartRange = chartRange
                self?.reloadUI(animated: true, completion: nil)
            }
        })
    }
    
    func buttonRow(title: String, image: UIImage, separatorLeftInset: CGFloat? = nil, isDestuctive: Bool = false, handler: @escaping () -> ()) -> CVRow {
        var buttonRow: CVRow = CVRow(title: title,
                                     image: image,
                                     xibName: .standardCell,
                                     theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                                        bottomInset: Appearance.Cell.Inset.normal,
                                                        textAlignment: .natural, titleFont: { Appearance.Cell.Text.standardFont },
                                                        titleColor: isDestuctive ? Asset.Colors.error.color : Asset.Colors.tint.color,
                                                        imageTintColor: Appearance.tintColor,
                                                        imageSize: Appearance.Cell.Image.size,
                                                        separatorLeftInset: separatorLeftInset,
                                                        accessoryType: UITableViewCell.AccessoryType.none),
                                     selectionAction: { _ in handler() },
                                     willDisplay: { cell in
            cell.cvTitleLabel?.accessibilityTraits = .button
        })
        buttonRow.theme.backgroundColor = Appearance.Cell.cardBackgroundColor
        return buttonRow
    }
}

// MARK: - Utils
private extension KeyFiguresComparisonController {
    func saveSelection() {
        KeyFiguresManager.shared.comparedKeyFiguresIndexes = selectedKeyFigures.compactMap { keyFigure in
            KeyFiguresManager.shared.keyFigures.firstIndex(of: keyFigure) ?? 0
        }
    }
}
