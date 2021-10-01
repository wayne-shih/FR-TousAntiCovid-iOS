// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureDetailCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit
import Charts

final class KeyFigureDetailCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []

    private let keyFigure: KeyFigure
    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?

    init(presentingController: UIViewController?, parent: Coordinator, keyFigure: KeyFigure) {
        self.presentingController = presentingController
        self.parent = parent
        self.keyFigure = keyFigure
        start()
    }

    private func start() {
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: KeyFigureDetailController(keyFigure: keyFigure, didTouchChart: { [weak self] chartDatas in
            self?.showFullscreenChart(chartDatas: chartDatas)
        }, deinitBlock: { [weak self] in
            self?.didDeinit()
        }))
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }

    private func showFullscreenChart(chartDatas: [KeyFigureChartData]) {
        let chartController: KeyFigureChartController = KeyFigureChartController.controller(chartDatas: chartDatas) { [weak self] in
            self?.closeFullscreenChart()
        }
        chartController.modalTransitionStyle = .crossDissolve
        chartController.modalPresentationStyle = .fullScreen
        navigationController?.present(chartController, animated: true)
    }

    private func closeFullscreenChart() {
        navigationController?.dismiss(animated: true)
    }

}
