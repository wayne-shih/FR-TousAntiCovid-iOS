// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UrgentDgsDetailController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 04/10/2021 - for the TousAntiCovid project.
//

import UIKit

final class UrgentDgsDetailController: CVTableViewController {
    /// Action on the button in the reminders info row
    private let didTouchMoreInfo: () -> ()
    private let didTouchCloseButton: () -> ()
    private let deinitBlock: () -> ()
    private var isFirstLoad: Bool = true
    
    init(
        didTouchMoreInfo: @escaping () -> (),
        didTouchCloseButton: @escaping () -> (),
        deinitBlock: @escaping () -> ()) {
            self.didTouchMoreInfo = didTouchMoreInfo
            self.didTouchCloseButton = didTouchCloseButton
            self.deinitBlock = deinitBlock
            super.init(style: .plain)
        }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstLoad {
            isFirstLoad = false
            updateTableViewLayout()
        }
    }
    
    deinit {
        LocalizationsManager.shared.removeObserver(self)
        deinitBlock()
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        // Video row if there is an url defined in strings
        let videoPath: String = "dgsUrgentController.videoUrl".localized
        if !videoPath.isEmpty {
            let videoRow: CVRow = CVRow(xibName: .videoPlayerCell,
                                        theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                           topInset: 0.0,
                                                           bottomInset: 0.0,
                                                           leftInset: 0.0,
                                                           rightInset: 0.0),
                                        associatedValue: URL(string: videoPath),
                                        valueChanged: { [weak self] _ in
                guard self?.isFirstLoad == false else { return }
                self?.updateTableViewLayout()
            })
            rows.append(videoRow)
        }
        // Information row with details on the reminders
        let infosRow: CVRow = CVRow(title: "dgsUrgentController.section.title".localized,
                                    subtitle: "dgsUrgentController.section.desc".localized,
                                    buttonTitle: "dgsUrgentController.section.labelUrl".localized,
                                    xibName: .cardWithButtonCell,
                                    theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                       topInset: Appearance.Cell.leftMargin,
                                                       bottomInset: 0.0,
                                                       textAlignment: .center,
                                                       titleFont: { Appearance.Cell.Text.headTitleFont }),
                                    secondarySelectionAction: "dgsUrgentController.section.url".localized.isEmpty ? nil : { [weak self] in
            self?.didTouchInfo()
        })
        rows.append(infosRow)
        // Need help row with possibility to call the help center
        let phoneNumber: String = "dgsUrgentController.phone.number".localized
        if !phoneNumber.isEmpty {
            let phoneRow: CVRow = CVRow(title: "dgsUrgentController.phone.title".localized,
                                        subtitle: "dgsUrgentController.phone.subtitle".localized,
                                        image: Asset.Images.walletPhone.image,
                                        xibName: .phoneCell,
                                        theme: CVRow.Theme(backgroundColor: Asset.Colors.secondaryButtonBackground.color,
                                                           topInset: Appearance.Cell.leftMargin,
                                                           bottomInset: 0.0,
                                                           textAlignment: .natural,
                                                           titleFont: { Appearance.Cell.Text.smallHeadTitleFont },
                                                           subtitleFont: { Appearance.Cell.Text.accessoryFont }),
                                        selectionAction: { [weak self] in
                guard let self = self else { return }
                phoneNumber.callPhoneNumber(from: self)
            })
            rows.append(phoneRow)
        }
        
        return rows
    }

    private func updateTableViewLayout() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}

// MARK: - Privates functions -
private extension UrgentDgsDetailController {
    private func updateTitle() {
        title = "dgsUrgentController.title".localized
    }
    
    func initUI() {
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchClose))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }
    
    @objc func didTouchClose() {
        didTouchCloseButton()
    }
    
    // Button action on the reminders info row
    func didTouchInfo() {
        didTouchMoreInfo()
    }
}

// MARK: - LocalizationManager observer -
extension UrgentDgsDetailController: LocalizationsChangesObserver {
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
}
