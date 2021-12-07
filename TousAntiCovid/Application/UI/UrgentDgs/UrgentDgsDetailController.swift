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
    private let didTouchMoreInfo: (_ url: URL) -> ()
    private let didTouchCloseButton: () -> ()
    private let deinitBlock: () -> ()
    private var isFirstLoad: Bool = true
    
    init(
        didTouchMoreInfo: @escaping (_ url: URL) -> (),
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
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                // Video row if there is an url defined in strings
                let videoPath: String = "dgsUrgentController.videoUrl".localized
                if !videoPath.isEmpty {
                    videoRow(videoPath: videoPath)
                }
                // Information row with details on the reminders
                infosRow()
                // Need help row with possibility to call the help center
                let phoneNumber: String = "dgsUrgentController.phone.number".localized
                if !phoneNumber.isEmpty {
                    phoneRow(phoneNumber: phoneNumber)
                }
            }
        }
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
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchClose))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }
    
    @objc func didTouchClose() {
        didTouchCloseButton()
    }
}

// MARK: - Rows -
private extension UrgentDgsDetailController {
    func videoRow(videoPath: String) -> CVRow {
        CVRow(xibName: .videoPlayerCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: .zero,
                                 bottomInset: .zero,
                                 leftInset: .zero,
                                 rightInset: .zero),
              associatedValue: URL(string: videoPath),
              valueChanged: { [weak self] _ in
            guard self?.isFirstLoad == false else { return }
            self?.updateTableViewLayout()
        })
    }

    func infosRow() -> CVRow {
        CVRow(title: "dgsUrgentController.section.title".localized,
              subtitle: "dgsUrgentController.section.desc".localized,
              buttonTitle: "dgsUrgentController.section.labelUrl".localized,
              xibName: .paragraphCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.normal,
                                 bottomInset: .zero,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.headTitleFont }),
              selectionAction: "dgsUrgentController.section.url".localized.isEmpty ? nil : { [weak self] in
            guard let moreInfoUrl: URL = URL(string: "dgsUrgentController.section.url".localized) else { return }
            self?.didTouchMoreInfo(moreInfoUrl)
        })
    }

    func phoneRow(phoneNumber: String) -> CVRow {
        CVRow(title: "dgsUrgentController.phone.title".localized,
              subtitle: "dgsUrgentController.phone.subtitle".localized,
              image: Asset.Images.walletPhone.image,
              xibName: .phoneCell,
              theme: CVRow.Theme(backgroundColor: Asset.Colors.secondaryButtonBackground.color,
                                 topInset: Appearance.Cell.Inset.normal,
                                 bottomInset: .zero,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.smallHeadTitleFont },
                                 subtitleFont: { Appearance.Cell.Text.accessoryFont }),
              selectionAction: { [weak self] in
            guard let self = self else { return }
            phoneNumber.callPhoneNumber(from: self)
        })
    }
}

// MARK: - LocalizationManager observer -
extension UrgentDgsDetailController: LocalizationsChangesObserver {
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
}
