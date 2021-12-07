// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  FullscreenOptionsController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 10/11/2021 - for the TousAntiCovid project.
//

import UIKit

final class FullscreenOptionsController: BottomSheetedTableViewController {
    
    @UserDefault(key: .autoBrightnessActivated)
    private var autoBrightnessActivated: Bool = true
    
    private var didTouchShareCertificateButton: () -> ()
    private var autoBrightnessDidChange: (_ activated: Bool) -> ()
    
    init(autoBrightnessDidChange: @escaping (_ activated: Bool) -> (),
         didTouchShareCertificateButton: @escaping () -> ()) {
        self.didTouchShareCertificateButton = didTouchShareCertificateButton
        self.autoBrightnessDidChange = autoBrightnessDidChange
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection(footerTitle: "common.settings.fullBrightnessSwitch.subtitle".localized) {
                shareRow()
                brightnessRow(activated: autoBrightnessActivated)
            }
        }
    }
    
}

// MARK: - UI configuration
private extension FullscreenOptionsController {
    func initUI() {
        addHeaderView()
        addFooterView(height: 8.0)
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
    }
}

// MARK: - Rows creation
private extension FullscreenOptionsController {
    func brightnessRow(activated: Bool) -> CVRow {
        CVRow(title: "common.settings.fullBrightnessSwitch.title".localized,
              image: activated ? Asset.Images.brightnessOn.image : Asset.Images.brightnessOff.image,
              isOn: activated,
              xibName: .standardCardSwitchCell,
              theme: .init(backgroundColor: Appearance.Cell.cardBackgroundColor,
                           topInset: Appearance.Cell.Inset.small,
                           bottomInset: .zero,
                           textAlignment: .natural,
                           titleFont: { Appearance.Cell.Text.standardFont },
                           titleColor: Appearance.Cell.Text.headerTitleColor,
                           imageTintColor: Appearance.Cell.Text.headerTitleColor),
              valueChanged: { [weak self] newValue in
            self?.autoBrightnessDidChange(newValue as? Bool ?? true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.reloadUI()
            }
        })
    }
    
    func shareRow() -> CVRow {
        CVRow(title: "common.share".localized,
              image: Asset.Images.shareItem.image,
              xibName: .standardCardCell,
              theme: .init(backgroundColor: Appearance.Cell.cardBackgroundColor,
                           topInset: .zero,
                           bottomInset: .zero,
                           textAlignment: .natural,
                           titleFont: { Appearance.Cell.Text.standardFont },
                           titleColor: Appearance.Cell.Text.headerTitleColor,
                           imageTintColor: Appearance.Cell.Text.headerTitleColor),
              selectionAction: { [weak self] in
            self?.dismiss(animated: true) {
                self?.didTouchShareCertificateButton()
            }
        })
    }
}
