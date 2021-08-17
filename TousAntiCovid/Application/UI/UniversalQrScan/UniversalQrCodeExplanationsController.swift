// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UniversalQrCodeExplanationsController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 11/06/2021 - for the TousAntiCovid project.
//

import UIKit

final class UniversalQrCodeExplanationsController: CVTableViewController {

    private(set) weak var imageView: UIImageView?
    private let didTouchClose: (_ imageView: UIImageView?) -> ()
    private let didDismissManually: () -> ()

    init(didTouchClose: @escaping (_ imageView: UIImageView?) -> (), didDismissManually: @escaping () -> ()) {
        self.didTouchClose = didTouchClose
        self.didDismissManually = didDismissManually
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        reloadUI()
    }

    private func initUI() {
        title = "universalQrScanExplanationsController.title".localized
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.delaysContentTouches = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
        navigationController?.presentationController?.delegate = self
    }

    @objc private func didTouchCloseButton() {
        didTouchClose(imageView)
    }

    override func createRows() -> [CVRow] {
        let headerImageRow: CVRow = CVRow(image: Asset.Images.qrScan.image,
                                          xibName: .imageCell,
                                          theme: CVRow.Theme(topInset: 20.0,
                                                             imageTintColor: Appearance.tintColor,
                                                             imageSize: CGSize(width: 90.0, height: 90.0)),
                                          willDisplay: { [weak self] cell in
                                            self?.imageView = cell.cvImageView
                                          })
        let explanationsRow: CVRow = CVRow(title: "universalQrScanExplanationsController.explanation.title".localized,
                                           subtitle: "universalQrScanExplanationsController.explanation.subtitle".localized,
                                           xibName: .standardCardCell,
                                           theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                              topInset: 10.0,
                                                              bottomInset: 0.0,
                                                              textAlignment: .center,
                                                              titleFont: { Appearance.Cell.Text.headTitleFont }))
        let buttonRow: CVRow = CVRow(title: "universalQrScanExplanationsController.button.title".localized,
                                     xibName: .buttonCell,
                                     theme: CVRow.Theme(topInset: 20.0, bottomInset: 0.0, buttonStyle: .primary),
                                     selectionAction: { [weak self] in
                                        self?.didTouchCloseButton()
                                     })
        return [headerImageRow, explanationsRow, buttonRow]
    }

}

extension UniversalQrCodeExplanationsController: UIAdaptivePresentationControllerDelegate {

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        didDismissManually()
    }

}
