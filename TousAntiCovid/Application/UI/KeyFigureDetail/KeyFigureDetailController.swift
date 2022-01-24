// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureDetailController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/01/2021 - for the TousAntiCovid project.
//

import UIKit
import Charts

final class KeyFigureDetailController: CVTableViewController {

    override var childForStatusBarHidden: UIViewController? { children.first }

    private var keyFigure: KeyFigure
    private let didTouchChart: (_ chartDatas: [KeyFigureChartData]) -> ()
    private let deinitBlock: () -> ()
    private var currentChartRange: ChartRange = .year
    private var chartViews: [String: ChartViewBase] = [:]

    init(keyFigure: KeyFigure, didTouchChart: @escaping (_ chartDatas: [KeyFigureChartData]) -> (), deinitBlock: @escaping () -> ()) {
        self.keyFigure = keyFigure
        self.didTouchChart = didTouchChart
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = keyFigure.shortLabel
        initUI()
        reloadUI()
        addObservers()
    }
    
    deinit {
        removeObservers()
        deinitBlock()
    }
    
    private func initUI() {
        addHeaderView(height: 10.0)
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
        updateRightBarButtonItem()
    }
    
    private func updateRightBarButtonItem() {
        if KeyFiguresManager.shared.displayDepartmentLevel {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.Images.location.image, style: .plain, target: self, action: #selector(didTouchLocationButton))
            navigationItem.rightBarButtonItem?.accessibilityLabel = "accessibility.hint.postalCode.button".localized
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    private func addObservers() {
        KeyFiguresManager.shared.addObserver(self)
    }

    private func removeObservers() {
        KeyFiguresManager.shared.removeObserver(self)
    }

    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                CVRow(title: keyFigure.label,
                      subtitle: keyFigure.description,
                      xibName: .keyFigureCell,
                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                         topInset: Appearance.Cell.Inset.small,
                                         bottomInset: .zero,
                                         textAlignment: .natural),
                      associatedValue: keyFigure,
                      selectionActionWithCell: { [weak self] cell in
                    self?.didTouchSharingFor(cell: cell)
                })
            }
            createChartSection()
            if !keyFigure.learnMore.isEmpty {
                CVSection(title: "keyFigureDetailController.section.learnmore.title".localized) {
                    CVRow(subtitle: keyFigure.learnMore,
                          xibName: .standardCardCell,
                          theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                             topInset: .zero,
                                             bottomInset: .zero,
                                             textAlignment: .natural))
                }
            }
        }
    }

    @objc private func didTouchLocationButton() {
        KeyFiguresManager.shared.updateLocation(from: self)
    }

    private func didTouchSharingFor(cell: CVTableViewCell) {
        var activityItems: [Any?] = []
        if cell is KeyFigureCell {
            let sharingText: String
            if let keyFigureDepartment = keyFigure.currentDepartmentSpecificKeyFigure {
                sharingText = String(format: "keyFigure.sharing.department".localized,
                                     keyFigure.label,
                                     keyFigureDepartment.label,
                                     keyFigureDepartment.valueToDisplay,
                                     keyFigure.label,
                                     keyFigure.valueGlobalToDisplay)
            } else {
                sharingText = String(format: "keyFigure.sharing.national".localized,
                                     keyFigure.label,
                                     keyFigure.valueGlobalToDisplay)
            }
            activityItems.append(sharingText)
            activityItems.append(KeyFigureCaptureView.captureKeyFigure(keyFigure))
        } else {
            activityItems.append(cell.capture())
        }
        let controller: UIActivityViewController = UIActivityViewController(activityItems: activityItems.compactMap { $0 }, applicationActivities: nil)
        controller.excludedActivityTypes = [.saveToCameraRoll, .print]
        present(controller, animated: true, completion: nil)
    }

    // MARK: - Section -
    private func createChartSection() -> CVSection {
        var rows: [CVRow] = []
        rangeSelectionRow().map { rows.append($0) }
        let chartDatas: [KeyFigureChartData] = KeyFiguresManager.shared.generateChartData(from: keyFigure, daysCount: currentChartRange.rawValue)
        chartViews = [:]
        if keyFigure.displayOnSameChart {
            let data: [KeyFigureChartData] = [KeyFigureChartData](chartDatas.prefix(2))
            let chartView: ChartViewBase? = ChartViewBase.create(chartDatas: data, allowInteractions: false)
            chartViews["bothCharts"] = chartView
            let chartsRow: CVRow = CVRow(xibName: .keyFigureChartCell,
                                         theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                            topInset: Appearance.Cell.Inset.medium,
                                                            bottomInset: .zero,
                                                            textAlignment: .natural),
                                         associatedValue: (data, chartViews["bothCharts"]),
                                         selectionActionWithCell: { [weak self] cell in
                self?.didTouchSharingFor(cell: cell)
            },
                                         selectionAction: { [weak self] _ in
                self?.didTouchChart(data)
            })
            rows.append(chartsRow)
        } else {
            let chartRows: [CVRow] = chartDatas.filter { !$0.isAverage }.map { chartData in
                let chartView: ChartViewBase? = ChartViewBase.create(chartDatas: [chartData], allowInteractions: false)
                chartViews[chartData.id] = chartView
                return CVRow(xibName: .keyFigureChartCell,
                             theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                topInset: Appearance.Cell.Inset.medium,
                                                bottomInset: .zero,
                                                textAlignment: .natural),
                             associatedValue: ([chartData], chartViews[chartData.id]),
                             selectionActionWithCell: { [weak self] cell in
                    self?.didTouchSharingFor(cell: cell)
                },
                             selectionAction: { [weak self] _ in
                    self?.didTouchChart([chartData])
                })
            }
            rows.append(contentsOf: chartRows)
        }
        if let chartData = chartDatas.filter({ $0.isAverage }).first {
            let chartView: ChartViewBase? = ChartViewBase.create(chartDatas: [chartData], allowInteractions: false)
            chartViews[chartData.id] = chartView
            let chartRow: CVRow = CVRow(xibName: .keyFigureChartCell,
                                        theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                           topInset: Appearance.Cell.Inset.medium,
                                                           bottomInset: .zero,
                                                           textAlignment: .natural),
                                        associatedValue: ([chartData], chartViews[chartData.id]),
                                        selectionActionWithCell: { [weak self] cell in
                self?.didTouchSharingFor(cell: cell)
            },
                                        selectionAction: { [weak self] _ in
                self?.didTouchChart([chartData])
            })
            rows.append(chartRow)
        }

        return CVSection(title: "keyFigureDetailController.section.evolution.title".localized, rows: rows)
    }

    // MARK: - Row -
    private func rangeSelectionRow() -> CVRow? {
        let seriesCount: Int = keyFigure.ascendingSeries?.count ?? 0
        var chartRanges: [ChartRange] = []
        if seriesCount > ChartRange.threeMonth.rawValue {
            chartRanges = [.year, .threeMonth, .month]
        } else if seriesCount > ChartRange.month.rawValue {
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


}

extension KeyFigureDetailController: KeyFiguresChangesObserver {

    func keyFiguresDidUpdate() {
        reloadNextToKeyFiguresUpdate()
    }
    
    func postalCodeDidUpdate(_ postalCode: String?) {}
    
    private func reloadNextToKeyFiguresUpdate() {
        if let currentKeyFigure = KeyFiguresManager.shared.keyFigures.first(where: { $0.labelKey == keyFigure.labelKey }) {
            keyFigure = currentKeyFigure
        }
        updateRightBarButtonItem()
        reloadUI(animated: true)
    }

}
