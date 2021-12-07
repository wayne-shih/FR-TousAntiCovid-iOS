// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  BottomSheetAlertController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/10/2021 - for the TousAntiCovid project.
//

import UIKit
import LBBottomSheet

final class BottomSheetAlertController: BottomSheetedTableViewController {
    
    enum InterfaceStyle {
        case light
        case dark
    }
    
    private let alertImageTintColor: UIColor?
    private let alertTitle: String?
    private let alertMessage: String?
    private let alertImage: UIImage?
    private let okTitle: String
    private let cancelTitle: String?
    private let didTouchConfirm: (() -> ())?
    private let interfaceStyle: InterfaceStyle?
    
    init(title: String?, message: String?, image: UIImage? = nil, imageTintColor: UIColor? = nil, okTitle: String, cancelTitle: String? = nil, interfaceStyle: InterfaceStyle? = nil, didTouchConfirm: (() -> ())? = nil) {
        self.alertTitle = title
        self.alertMessage = message
        self.alertImage = image
        self.alertImageTintColor = imageTintColor
        self.okTitle = okTitle
        self.cancelTitle = cancelTitle
        self.didTouchConfirm = didTouchConfirm
        self.interfaceStyle = interfaceStyle
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
            CVSection {
                if let image = alertImage { imageRow(image: image) }
                if let title = alertTitle { titleRow(title: title) }
                if let message = alertMessage { messageRow(message: message) }
                confirmRow()
                if cancelTitle != nil { cancelRow() }
            }
        }
    }
    
    func show() {
        if let style = interfaceStyle, #available(iOS 13.0, *) {
            UIApplication.shared.topPresentedController?.presentAsBottomSheet(self, theme: bottomSheetTheme).overrideUserInterfaceStyle = style == .light ? .light : .dark
        } else {
            UIApplication.shared.topPresentedController?.presentAsBottomSheet(self, theme: bottomSheetTheme)
        }
    }
}

// MARK: - UI configuration -
private extension BottomSheetAlertController {
    func initUI() {
        addHeaderView()
        addFooterView(height: 8.0)
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = Appearance.Cell.cardBackgroundColor
    }
}

// MARK: - Rows creation -
private extension BottomSheetAlertController {
    func imageRow(image: UIImage) -> CVRow {
        let ratio: CGFloat = image.size.width / image.size.height
        let imageHeight: CGFloat = 36.0
        return CVRow(image: image,
                     xibName: .imageCell,
                     theme: CVRow.Theme(
                        topInset: Appearance.Cell.Inset.small,
                        bottomInset: .zero,
                        imageSize: CGSize(width: imageHeight * ratio, height: imageHeight)),
                     willDisplay: { [weak self] cell in
                            (cell as? ImageCell)?.cvImageView?.tintColor = self?.alertImageTintColor
        })
    }
    
    func titleRow(title: String) -> CVRow {
        CVRow(title: title,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: .zero,
                                 bottomInset: .zero,
                                 titleFont: { Appearance.Cell.Text.smallHeadTitleFont }))
    }

    func messageRow(message: String) -> CVRow {
        CVRow(title: message,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                 bottomInset: .zero,
                                 titleFont: { Appearance.Cell.Text.subtitleFont }))
    }

    func confirmRow() -> CVRow {
        CVRow(title: okTitle,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                 bottomInset: .zero,
                                 buttonStyle: .primary),
              selectionAction: { [weak self] in
            self?.dismiss(animated: true) {
                self?.didTouchConfirm?()
            }
        })
    }

    func cancelRow() -> CVRow {
        CVRow(title: cancelTitle,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.small,
                                 bottomInset: .zero,
                                 buttonStyle: .tertiary),
              selectionAction: { [weak self] in
            self?.dismiss(animated: true)
        })
    }
}
