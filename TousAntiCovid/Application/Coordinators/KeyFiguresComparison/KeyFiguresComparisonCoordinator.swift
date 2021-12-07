// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFiguresComparisonCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/11/2021 - for the TousAntiCovid project.
//

import UIKit
import Charts

final class KeyFiguresComparisonCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []

    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?

    init(presentingController: UIViewController?, parent: Coordinator) {
        self.presentingController = presentingController
        self.parent = parent
        start()
    }
}

// MARK: - Utils
private extension KeyFiguresComparisonCoordinator {
    func start() {
        let comparisonController: KeyFiguresComparisonController = .init { [weak self] keyFigures in
            self?.showSharingScreen(for: keyFigures)
        } didTouchChart: { [weak self] chartDatas in
            self?.showFullscreenChart(chartDatas: chartDatas)
        } didTouchSelection: { [weak self] currentSelection, didChangeBlock in
            self?.showSelectionScreen(for: currentSelection, didChangeSelection: didChangeBlock)
        } deinitBlock: { [weak self] in
            self?.didDeinit()
        }

        let navigationController: CVNavigationController = .init(rootViewController: comparisonController)
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }
}

// MARK: - Selection related functions
private extension KeyFiguresComparisonCoordinator {
    func showSelectionScreen(for selection: [KeyFigure], didChangeSelection: @escaping ([KeyFigure]) -> ()) {
        let selectionCoordinator: KeyFiguresSelectionCoordinator = .init(presentingController: navigationController, parent: self, selection: selection) { newSelection in
            didChangeSelection(newSelection)
        }
        addChild(coordinator: selectionCoordinator)
    }
}

// MARK: - fullScreen related functions
private extension KeyFiguresComparisonCoordinator {
    func showFullscreenChart(chartDatas: [KeyFigureChartData]) {
        let chartController: KeyFigureChartController = KeyFigureChartController.controller(chartDatas: chartDatas, mode: .comparison) { [weak self] in
            self?.closeFullscreenChart()
        }
        chartController.modalTransitionStyle = .crossDissolve
        chartController.modalPresentationStyle = .fullScreen
        navigationController?.present(chartController, animated: true)
    }
    
    func closeFullscreenChart() {
        navigationController?.dismiss(animated: true)
    }
}

// MARK: - sharing related functions
private extension KeyFiguresComparisonCoordinator {
    func showSharingScreen(for chartImage: UIImage?) {
        let activityItems: [Any?] = [chartImage]
        let controller: UIActivityViewController = UIActivityViewController(activityItems: activityItems.compactMap { $0 }, applicationActivities: nil)
        controller.excludedActivityTypes = [.saveToCameraRoll, .print]
        navigationController?.present(controller, animated: true, completion: nil)
    }
}
