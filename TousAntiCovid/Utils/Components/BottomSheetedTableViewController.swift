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
    
    @objc var preferredHeightInBottomSheet: CGFloat { tableView.contentSize.height + (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0) }
    
    lazy var bottomSheetTheme: BottomSheetController.Theme = {
        let grabberBackground: BottomSheetController.Theme.Grabber.Background = .color(isTranslucent: false)
        var theme: BottomSheetController.Theme = .init()
        theme.grabber?.background = grabberBackground
        theme.shadow?.opacity = 0.3
        theme.dimmingBackgroundColor = Asset.Colors.bottomSheetDimmingBackground.color
        return theme
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadUI { [weak self] in
            self?.bottomSheetController?.preferredHeightInBottomSheetDidUpdate()
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
