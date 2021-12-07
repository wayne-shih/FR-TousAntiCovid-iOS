// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ActivityPassParametersViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 19/08/2021 - for the TousAntiCovid project.
//

import UIKit

final class ActivityPassParametersViewController: CVTableViewController {

    let didTouchConfirm: () -> ()
    let didTouchReadCGU: () -> ()
    let dismissBlock: () -> ()
    
    @objc var preferredHeightInBottomSheet: CGFloat { tableView.contentSize.height + (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0) }

    @UserDefault(key: .activityPassNotificationActivated)
    private var activityPassNotificationActivated: Bool = false

    init(didTouchConfirm: @escaping () -> (), didTouchReadCGU: @escaping () -> (), dismissBlock: @escaping () -> ()) {
        self.didTouchConfirm = didTouchConfirm
        self.didTouchReadCGU = didTouchReadCGU
        self.dismissBlock = dismissBlock
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        if #available(iOS 13.0, *) { overrideUserInterfaceStyle = .light }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadUI { [weak self] in
            self?.bottomSheetController?.preferredHeightInBottomSheetDidUpdate()
        }
    }

    private func initUI() {
        title = "activityPassParametersController.title".localized
        if #available(iOS 13.0, *) {
            addHeaderView(height: bottomSheetController?.topInset ?? 0.0)
        }
        addFooterView(height: 8.0)
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        let barButtonItem: UIBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        barButtonItem.accessibilityHint = "accessibility.closeModal.zGesture".localized
        (bottomButtonContainerController ?? self).navigationItem.leftBarButtonItem = barButtonItem
    }

    @objc private func didTouchCloseButton() {
        dismissBlock()
    }

    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                headerImageRow()
                explanationsRow()
                confirmationQuestionRow()
                confirmRow()
                cguRow()
            }
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        dismissBlock()
        return true
    }

}

extension ActivityPassParametersViewController {

    private func headerImageRow() -> CVRow {
        let image: UIImage = Asset.Images.logoPS.image
        let ratio: CGFloat = image.size.width / image.size.height
        let imageHeight: CGFloat = 36.0
        return CVRow(image: Asset.Images.logoPS.image,
                     xibName: .imageCell,
                     theme: CVRow.Theme(topInset: Appearance.Cell.Inset.small,
                                        bottomInset: .zero,
                                        imageSize: CGSize(width: imageHeight * ratio, height: imageHeight)))
    }

    private func explanationsRow() -> CVRow {
        CVRow(title: "activityPassParametersController.explanations".localized,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.large,
                                 bottomInset: .zero,
                                 titleFont: { Appearance.Cell.Text.footerFont }))
    }

    private func confirmationQuestionRow() -> CVRow {
        CVRow(title: "activityPassParametersController.doYouConfirm".localized,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.large * 2,
                                 bottomInset: .zero,
                                 titleFont: { Appearance.Cell.Text.titleFont }))
    }

    private func confirmRow() -> CVRow {
        CVRow(title: "common.confirm".localized,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.large,
                                 bottomInset: .zero,
                                 buttonStyle: .primary),
              selectionAction: { [weak self] in
                self?.didTouchConfirm()
              })
    }

    private func cguRow() -> CVRow {
        CVRow(title: "activityPassParametersController.button.readCGU".localized,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.small,
                                 bottomInset: .zero,
                                 buttonStyle: .tertiary),
              selectionAction: { [weak self] in
                self?.didTouchReadCGU()
              })
    }

    private func switchRow(title: String, isOn: Bool, handler: @escaping (_ isOn: Bool) -> ()) -> CVRow {
        CVRow(title: title,
              isOn: isOn,
              xibName: .standardSwitchCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.small,
                                 bottomInset: Appearance.Cell.Inset.small,
                                 textAlignment: .left,
                                 titleFont: { Appearance.Cell.Text.standardFont },
                                 separatorLeftInset: .zero,
                                 separatorRightInset: .zero),
              valueChanged: { value in
                guard let isOn = value as? Bool else { return }
                handler(isOn)
              })
    }

}
