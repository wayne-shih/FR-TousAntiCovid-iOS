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

    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                CVRow(image: Asset.Images.qrScan.image,
                      xibName: .imageCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                         imageTintColor: Appearance.tintColor,
                                         imageSize: CGSize(width: 90.0, height: 90.0)),
                      willDisplay: { [weak self] cell in
                    self?.imageView = cell.cvImageView
                })
                CVRow(title: "universalQrScanExplanationsController.explanation.title".localized,
                      subtitle: "universalQrScanExplanationsController.explanation.subtitle".localized,
                      xibName: .standardCardCell,
                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                         topInset: Appearance.Cell.Inset.small,
                                         bottomInset: .zero,
                                         textAlignment: .center,
                                         titleFont: { Appearance.Cell.Text.headTitleFont }))
                CVRow(title: "universalQrScanExplanationsController.button.title".localized,
                      xibName: .buttonCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                         bottomInset: .zero,
                                         buttonStyle: .primary),
                      selectionAction: { [weak self] in
                    self?.didTouchCloseButton()
                })
            }
        }
    }

}

extension UniversalQrCodeExplanationsController: UIAdaptivePresentationControllerDelegate {

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        didDismissManually()
    }

}
