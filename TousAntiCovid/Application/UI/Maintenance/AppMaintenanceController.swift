// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AppMaintenanceController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/05/2020 - for the TousAntiCovid project.
//


import UIKit
import PKHUD

final class AppMaintenanceController: CVTableViewController, MaintenanceController {

    var maintenanceInfo: MaintenanceInfo {
        didSet {
            if isViewLoaded {
                reloadUI()
            }
        }
    }
    private let didTouchAbout: () -> ()
    private let didTouchLater: () -> ()
    
    init(maintenanceInfo: MaintenanceInfo, didTouchAbout: @escaping () -> (), didTouchLater: @escaping () -> ()) {
        self.maintenanceInfo = maintenanceInfo
        self.didTouchLater = didTouchLater
        self.didTouchAbout = didTouchAbout
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("You must use the standard init() method.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "app.name".localized
        initUI()
        reloadUI()
    }

    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                imageRow()
                textRow()
                if let buttonTitle = maintenanceInfo.localizedButtonTitle, let buttonUrl = maintenanceInfo.localizedButtonUrl, maintenanceInfo.mode == .upgrade {
                    buttonRow(title: buttonTitle, url: buttonUrl)
                } else {
                    retryRow()
                }
                laterRow()
            }
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationChildController?.scrollViewDidScroll(scrollView)
    }
    
    private func initUI() {
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "common.about".localized, style: .plain, target: self, action: #selector(didTouchAboutButton))
    }
    
    @objc private func didTouchAboutButton() {
        didTouchAbout()
    }
    
    @objc private func didTouchButton() {
        HUD.show(.progress)
        MaintenanceManager.shared.checkMaintenanceState {
            HUD.hide()
        }
    }

}

// MARK: - Rows -
private extension AppMaintenanceController {
    func imageRow() -> CVRow { CVRow(image: Asset.Images.maintenance.image,
                                     xibName: .onboardingImageCell,
                                     theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                                        imageRatio: Appearance.Cell.Image.defaultRatio))
    }

    func textRow() -> CVRow {
        let message: String = maintenanceInfo.localizedMessage ?? ""
        let messageComponents: [String] = message.components(separatedBy: "\n")
        let title: String = messageComponents[0]
        let subtitle: String = message.replacingOccurrences(of: "\(title)\n", with: "")
        return CVRow(title: title,
                             subtitle: subtitle,
                             xibName: .textCell,
                             theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge))
    }

    func buttonRow(title: String, url: String) -> CVRow {
        CVRow(title: title,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                 bottomInset: .zero),
              selectionAction: { _ in
            URL(string: url)?.openInSafari()
        })
    }

    func retryRow() -> CVRow {
        CVRow(title: "common.tryAgain".localized,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                 bottomInset: .zero),
              selectionAction: { [weak self] _ in
            self?.didTouchButton()
        })
    }

    func laterRow() -> CVRow {
        CVRow(title: "appMaintenanceController.later.button.title".localized,
              xibName: .buttonCell,
              theme: CVRow.Theme(topInset: .zero,
                                 buttonStyle: .quaternary),
              selectionAction: { [weak self] _ in
            self?.didTouchLater()
        })
    }
}
