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
        reloadUI()
        if #available(iOS 13.0, *) { navigationController?.overrideUserInterfaceStyle = .light }
    }

    private func initUI() {
        title = "activityPassParametersController.title".localized
        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        let barButtonItem: UIBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        barButtonItem.accessibilityHint = "accessibility.closeModal.zGesture".localized
        (bottomButtonContainerController ?? self).navigationItem.leftBarButtonItem = barButtonItem
    }

    @objc private func didTouchCloseButton() {
        dismissBlock()
    }

    override func createRows() -> [CVRow] {
        makeRows {
            headerImageRow()
            explanationsRow()
            confirmationQuestionRow()
            confirmRow()
            cguRow()
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
                     theme: CVRow.Theme(topInset: 30.0,
                                        bottomInset: 0.0,
                                        imageSize: CGSize(width: imageHeight * ratio, height: imageHeight)))
    }

    private func explanationsRow() -> CVRow {
        CVRow(title: "activityPassParametersController.explanations".localized,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: 30.0,
                                 bottomInset: 0.0,
                                 titleFont: { Appearance.Cell.Text.footerFont }))
    }

    private func confirmationQuestionRow() -> CVRow {
        CVRow(title: "activityPassParametersController.doYouConfirm".localized,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: 60.0,
                                 bottomInset: 0.0,
                                 titleFont: { Appearance.Cell.Text.titleFont }))
    }

    private func confirmRow() -> CVRow {
        CVRow(title: "common.confirm".localized,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: 30.0,
                                 bottomInset: 0.0,
                                 buttonStyle: .primary),
              selectionAction: { [weak self] in
                self?.didTouchConfirm()
              })
    }

    private func cguRow() -> CVRow {
        CVRow(title: "activityPassParametersController.button.readCGU".localized,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: 10.0,
                                 bottomInset: 0.0,
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
                                 topInset: 10.0,
                                 bottomInset: 10.0,
                                 textAlignment: .left,
                                 titleFont: { Appearance.Cell.Text.standardFont },
                                 separatorLeftInset: 0.0,
                                 separatorRightInset: 0.0),
              valueChanged: { value in
                guard let isOn = value as? Bool else { return }
                handler(isOn)
              })
    }

}
