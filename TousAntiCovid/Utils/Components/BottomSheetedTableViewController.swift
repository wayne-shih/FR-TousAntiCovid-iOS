// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  BottomSheetedTableViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 10/11/2021 - for the TousAntiCovid project.
//

import UIKit
import LBBottomSheet

class BottomSheetedTableViewController: CVTableViewController {
    
    enum Mode {
        case fitContent
        case twoPositions
    }
    
    private let minHeight: CGFloat = UIScreen.main.bounds.height / 2
    
    var preferredHeight: CGFloat { tableView.contentSize.height + tableView.contentInset.top + tableView.contentInset.bottom }
    
    lazy var bottomSheetTheme: BottomSheetController.Theme = {
        let grabberBackground: BottomSheetController.Theme.Grabber.Background = .color(isTranslucent: false)
        var theme: BottomSheetController.Theme = .init()
        theme.grabber?.background = grabberBackground
        theme.shadow?.opacity = 0.3
        theme.dimmingBackgroundColor = Asset.Colors.bottomSheetDimmingBackground.color
        return theme
    }()
    
    lazy var bottomSheetBehavior: BottomSheetController.Behavior = {
        let minHeightValue: BottomSheetController.Behavior.HeightValue = .custom { [weak self] in
            guard let self = self else { return 0.0 }
            return min(self.preferredHeight, self.minHeight)
        }
        let maxHeightValue: BottomSheetController.Behavior.HeightValue = .fitContent
        var behavior: BottomSheetController.Behavior = .init()
        behavior.heightMode = mode == .fitContent ? .fitContent(heightLimit: .statusBar) : .specific(values: [minHeightValue, maxHeightValue])
        return behavior
    }()
    
    var mode: Mode { .fitContent }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomSheetController?.bottomSheetPositionDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadUI { [weak self] in
            if self?.mode == .fitContent { self?.bottomSheetController?.preferredHeightInBottomSheetDidUpdate() }
        }
    }
    
    override func accessibilityPerformEscape() -> Bool {
        bottomSheetController?.dismiss()
        return true
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        bottomSheetController?.dismiss(completion)
    }
}

extension BottomSheetedTableViewController: BottomSheetPositionDelegate {
    func bottomSheetPositionDidUpdate(y: CGFloat) {
        guard mode == .twoPositions else { return }
        tableView.isScrollEnabled = y < minHeight
    }
}
