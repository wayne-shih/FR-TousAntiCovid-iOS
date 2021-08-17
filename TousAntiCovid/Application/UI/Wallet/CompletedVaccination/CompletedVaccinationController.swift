// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CompletedVaccinationController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/06/2021 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK
import PKHUD

final class CompletedVaccinationController: CVTableViewController {

    private let certificate: EuropeanCertificate
    private var confettiView: ConfettiView?

    private lazy var daysAfterCompletion: Int = { ParametersManager.shared.daysAfterCompletion.first(where: { $0.code.trimLowercased() == certificate.medicalProductCode?.trimLowercased() ?? "" })?.value ?? ParametersManager.shared.daysAfterCompletion.first(where: { $0.code.trimLowercased() == "default" })?.value ?? 0 }()
    
    private lazy var completedDate: Date = { Date(timeIntervalSince1970: certificate.timestamp + Double((daysAfterCompletion * 24 * 3600))) }()
    private lazy var isVaccineCompleted = { completedDate <= Date() }()

    init(certificate: EuropeanCertificate) {
        self.certificate = certificate
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startConfettiWithHaptic()
    }

    private func initUI() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }

    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    override func createRows() -> [CVRow] {
        var rows: [CVRow] = infoRows()
        if isVaccineCompleted {
            rows.append(contentsOf: addToFavoriteRows())
        } else {
            rows.append(contentsOf: notifyMeRows())
            rows.append(contentsOf: notifyMeAndFavoriteRows())
        }
        return rows
    }

    private func infoRows() -> [CVRow] {
        let headerImageRow: CVRow = CVRow(image: Asset.Images.thumbsup.image,
                                          xibName: .imageCell,
                                          theme: CVRow.Theme(topInset: 20.0,
                                                             imageTintColor: Appearance.tintColor,
                                                             imageSize: CGSize(width: 90, height: 90)))
        let title: String
        let message: String
        if isVaccineCompleted {
            title =  "vaccineCompletionController.completed.explanation.title".localized
            message =  "vaccineCompletionController.completed.explanation.body".localized
        } else {
            title = String(format: "vaccineCompletionController.pending.explanation.title".localized, completedDate.dayMonthYearFormatted())
            message = String(format: "vaccineCompletionController.pending.explanation.body".localized, completedDate.dayMonthYearFormatted())
        }

        let explanationsRow: CVRow = CVRow(title: title,
                                           subtitle: message,
                                           xibName: .standardCardCell,
                                           theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                              topInset: 10.0,
                                                              bottomInset: 0.0,
                                                              textAlignment: .center,
                                                              titleFont: { Appearance.Cell.Text.headTitleFont }))
        return [headerImageRow, explanationsRow]
    }

    private func notifyMeRows() -> [CVRow] {
        let footer: String = String(format: "vaccineCompletionController.footer.notify".localized, completedDate.dayMonthFormatted())
        let notifyMeRow: CVRow = CVRow(title: String(format: "vaccineCompletionController.pending.button.notifyMe.title".localized, completedDate.dayMonthFormatted()),
                                       xibName: .buttonCell,
                                       theme: CVRow.Theme(topInset: 40.0,
                                                          bottomInset: 0.0),
                                       selectionAction: { [weak self] in
                                        self?.notifyMe()
                                        self?.dismiss(animated: true, completion: nil)
                                       },
                                       willDisplay: { cell in
                                        (cell as? ButtonCell)?.button.accessibilityHint = footer
                                       })
        let footerRow: CVRow = footerRow(title: footer)
        return [notifyMeRow, footerRow]
    }

    private func addToFavoriteRows() -> [CVRow] {
        let footer: String = "vaccineCompletionController.footer.favorite".localized
        let addToFavorieRow: CVRow = CVRow(title: "vaccineCompletionController.button.favorite.title".localized,
                                           xibName: .buttonCell,
                                           theme: CVRow.Theme(topInset: 40.0,
                                                              bottomInset: 0.0),
                                           selectionAction: { [weak self] in
                                            self?.addToFavorite()
                                            self?.dismiss(animated: true, completion: nil)
                                           },
                                           willDisplay: { cell in
                                            (cell as? ButtonCell)?.button.accessibilityHint = footer
                                           })
        let footerRow: CVRow = footerRow(title: footer)
        return [addToFavorieRow, footerRow]
    }

    private func notifyMeAndFavoriteRows() -> [CVRow] {
        let footer: String = String(format: "vaccineCompletionController.footer.notifyAndFavorite".localized, completedDate.dayMonthFormatted())
        let notifyMeAndFavoriteRow: CVRow = CVRow(title: String(format: "vaccineCompletionController.button.notifyAndFavorite.title".localized, completedDate.dayMonthFormatted()),
                                                  xibName: .buttonCell,
                                                  theme: CVRow.Theme(topInset: 40.0,
                                                                     bottomInset: 0.0),
                                                  selectionAction: { [weak self] in
                                                    self?.notifyMe()
                                                    self?.addToFavorite()
                                                    self?.dismiss(animated: true, completion: nil)
                                                  },
                                                  willDisplay: { cell in
                                                    (cell as? ButtonCell)?.button.accessibilityHint = footer
                                                  })
        let footerRow: CVRow = footerRow(title: footer)
        return [notifyMeAndFavoriteRow, footerRow]
    }

    private func footerRow(title: String) -> CVRow {
        CVRow(title: title,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: 10.0,
                                 bottomInset: 0.0,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.accessoryFont },
                                 titleColor: Appearance.Cell.Text.captionTitleColor),
              willDisplay: { cell in
                cell.isAccessibilityElement = false
                cell.accessibilityElements = []
                cell.accessibilityElementsHidden = true
              })
    }

    private func notifyMe() {
        NotificationsManager.shared.scheduleCompletedVaccination(triggerDate: completedDate)
        HUD.flash(.success)
    }

    private func addToFavorite() {
        WalletManager.shared.setFavorite(certificate: certificate)
    }

}

extension CompletedVaccinationController {
    private func startConfettiWithHaptic() {
        stopConfetti()
        confettiView = ConfettiView(frame: view.bounds)
        guard let confettiView = confettiView else { return }
        view.window?.addSubview(confettiView)
        confettiView.startConfetti(birthRate: ParametersManager.shared.confettiBirthRate)
        haptic()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            confettiView.stopConfetti()
        }
    }

    private func stopConfetti() {
        if let oldConfetti = confettiView {
            oldConfetti.removeFromSuperview()
            confettiView = nil
        }
    }

    private func haptic() {
        if #available(iOS 13.0, *) {
            HapticManager.shared.hapticFirework()
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        startConfettiWithHaptic()
    }
}
