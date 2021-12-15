// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFiguresSelectionCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/11/2021 - for the TousAntiCovid project.
//

import UIKit

final class KeyFiguresSelectionCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []

    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?
    
    private let didChangeSelection: (_ selection: [KeyFigure]) -> ()
    private var selection: [KeyFigure]

    init(presentingController: UIViewController?, parent: Coordinator, selection: [KeyFigure], didChangeSelection: @escaping (_ selection: [KeyFigure]) -> ()) {
        self.presentingController = presentingController
        self.parent = parent
        self.didChangeSelection = didChangeSelection
        self.selection = selection
        start()
    }
}

// MARK: - Selection Screen related functions
private extension KeyFiguresSelectionCoordinator {
    func start() {
        let selectionController: KeyFiguresSelectionController = .init(selectedKeyFigures: selection) { [weak self] selectionDidUpdate in
            guard let self = self else { return }
            self.showListScreen(mode: .keyFigure1, with: self.selection) {
                self.selection[0] = $0
                selectionDidUpdate(self.selection)
            }
        } didTouchSecondKeyFigure: { [weak self] selectionDidUpdate in
            guard let self = self else { return }
            self.showListScreen(mode: .keyFigure2, with: self.selection) {
                self.selection[1] = $0
                selectionDidUpdate(self.selection)
            }
        } didTouchPredifinedCombination: { [weak self] in
            self?.selection = $0
        } didChose: { [weak self] keyFigures in
            self?.didChangeSelection(keyFigures)
        } didTouchClose: { [weak self] in
            self?.closeSelectionController()
        } deinitBlock: { [weak self] in
            self?.didDeinit()
        }
        let navigationController: CVNavigationController = .init(rootViewController: BottomButtonContainerController.controller(selectionController))
        self.navigationController = navigationController
        if #available(iOS 13.0, *) {
            navigationController.isModalInPresentation = true
        }
        presentingController?.present(navigationController, animated: true)
    }
    
    func closeSelectionController() {
        presentingController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - List Screen related functions
private extension KeyFiguresSelectionCoordinator {
    func showListScreen(mode: KeyFiguresChoiceController.SelectionMode, with selection: [KeyFigure], didSelect: @escaping (_ keyfigure: KeyFigure) -> ()) {
        let listController: KeyFiguresChoiceController = .init(
            mode: mode,
            keyFigures: KeyFiguresManager.shared.keyFigures,
            selected: selection) { [weak self] keyFigure in
                didSelect(keyFigure)
                self?.closeListScreen()
            } deinitBlock: {
                // Nothing to do
            }
        navigationController?.pushViewController(listController, animated: true)
    }

    func closeListScreen() {
        navigationController?.popViewController(animated: true)
    }
}
