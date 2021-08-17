// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesHistoryViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/11/2020 - for the TousAntiCovid project.
//

import UIKit
import StorageSDK
import RobertSDK

final class VenuesHistoryViewController: CVTableViewController {
    
    
    init() {
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "venuesHistoryController.title".localized
        initUI()
        reloadUI()
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    private func initUI() {
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.delaysContentTouches = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    private func addObservers() {
        VenuesManager.shared.addObserver(self)
    }
    
    private func removeObservers() {
        VenuesManager.shared.removeObserver(self)
    }
    
    override func createRows() -> [CVRow] {
        let venuesQrCodes: [VenueQrCodeInfo] = VenuesManager.shared.venuesQrCodes.sorted { $0.ntpTimestamp > $1.ntpTimestamp }
        updateEmptyView(areThereQrCodes: !venuesQrCodes.isEmpty, isSick: RBManager.shared.isImmune)
        guard !venuesQrCodes.isEmpty else { return [] }
        var rows: [CVRow] = venuesQrCodes.map { venueQrCodeInfo in
            CVRow(title: venueQrCodeInfo.venueTypeDisplayName,
                  subtitle: venueQrCodeInfo.ltid,
                  xibName: .venueHistoryCell,
                  theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                     topInset: 8.0,
                                     bottomInset: 8.0,
                                     rightInset: 8.0,
                                     textAlignment: .natural,
                                     titleFont: { Appearance.Cell.Text.standardFont },
                                     subtitleFont: { Appearance.Cell.Text.subtitleFont },
                                     subtitleColor: Appearance.Cell.Text.subtitleColor.withAlphaComponent(0.5),
                                     separatorLeftInset: Appearance.Cell.leftMargin),
                  secondarySelectionAction: { [weak self] in
                    self?.deleteVenueQrCodeInfo(venueQrCodeInfo)
                  })
        }
        guard rows.count >= 1 else { return rows }
        let footerText: String = "venuesHistoryController.footer".localizedOrEmpty
        if footerText.isEmpty {
            rows.append(.emptyFor(topInset: 0.0, bottomInset: 0.0, showSeparator: false))
        } else {
            let footerRow: CVRow = CVRow(title: footerText,
                                         xibName: .textCell,
                                         theme:  CVRow.Theme(topInset: 20.0,
                                                             bottomInset: 0.0,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Cell.Text.footerFont },
                                                             titleColor: Appearance.Cell.Text.captionTitleColor,
                                                             separatorLeftInset: 0.0,
                                                             separatorRightInset: 0.0))
            rows.append(footerRow)
        }
        return rows
    }
    
    private func updateEmptyView(areThereQrCodes: Bool, isSick: Bool) {
        tableView.backgroundView = areThereQrCodes ? nil : VenuesHistoryEmptyView.view(isSick: isSick)
    }
    
    private func deleteVenueQrCodeInfo(_ venueQrCodeInfo: VenueQrCodeInfo) {
        showAlert(title: "venuesHistoryController.delete.alert.title".localized,
                  message: "venuesHistoryController.delete.alert.message".localized,
                  okTitle: "common.delete".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.cancel".localized, handler: {
            VenuesManager.shared.deleteVenueQrCodeInfo(venueQrCodeInfo)
        })
    }
    
}

extension VenuesHistoryViewController: VenuesChangesObserver {

    func venuesDidUpdate() {
        reloadUI(animated: true)
    }

}
