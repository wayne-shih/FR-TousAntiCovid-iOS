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
    
    private lazy var noWaitDoses: Int = { ParametersManager.shared.noWaitDoses.first(where: { $0.code.trimLowercased() == certificate.medicalProductCode?.trimLowercased() ?? "" })?.value ?? ParametersManager.shared.noWaitDoses.first(where: { $0.code.trimLowercased() == "default" })?.value ?? 0 }()
    private lazy var noWaitDosesPivotDate: Date = {
        guard let dateStr = ParametersManager.shared.noWaitDosesPivotDate else { return .distantFuture }
        return Date(dateString: dateStr) ?? .distantFuture
    }()
    private lazy var shouldShowNoWaitWarning: Bool = { noWaitDoses > 0 && certificate.dosesNumber ?? 0 >= noWaitDoses && certificate.timestamp < noWaitDosesPivotDate.timeIntervalSince1970 }()
    
    private lazy var completedDate: Date = {
        if shouldShowNoWaitWarning {
            return Date(timeIntervalSince1970: certificate.timestamp)
        } else {
            return Date(timeIntervalSince1970: certificate.timestamp + Double((daysAfterCompletion * 24 * 3600)))
        }
    }()
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
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }

    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                infoRows()
                if isVaccineCompleted {
                    addToFavoriteRows()
                } else {
                    notifyMeRows()
                    notifyMeAndFavoriteRows()
                }
            }
        }
    }
}

// MARK: - Rows -
private extension CompletedVaccinationController {
    func infoRows() -> [CVRow] {
        let headerImageRow: CVRow = CVRow(image: Asset.Images.thumbsup.image,
                                          xibName: .imageCell,
                                          theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                                             imageTintColor: Appearance.tintColor,
                                                             imageSize: CGSize(width: 90, height: 90)))
        let title: String
        var message: String
        if isVaccineCompleted {
            title = "vaccineCompletionController.completed.explanation.title".localized
            message = shouldShowNoWaitWarning ? "\(String(format: "vaccineCompletionController.noWait.explanation.body".localized, "\((certificate.dosesNumber ?? 0) - 1)"))\n\n" : ""
            message += "vaccineCompletionController.completed.explanation.body".localized
        } else {
            title = String(format: "vaccineCompletionController.pending.explanation.title".localized, completedDate.dayMonthYearFormatted())
            message = String(format: "vaccineCompletionController.pending.explanation.body".localized, completedDate.dayMonthYearFormatted())
        }

        let explanationsRow: CVRow = CVRow(title: title,
                                           subtitle: message,
                                           xibName: .standardCardCell,
                                           theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                              topInset: Appearance.Cell.Inset.small,
                                                              bottomInset: .zero,
                                                              textAlignment: .center,
                                                              titleFont: { Appearance.Cell.Text.headTitleFont }))
        return [headerImageRow, explanationsRow]
    }

    func notifyMeRows() -> [CVRow] {
        let footer: String = String(format: "vaccineCompletionController.footer.notify".localized, completedDate.dayMonthFormatted())
        let notifyMeRow: CVRow = CVRow(title: String(format: "vaccineCompletionController.pending.button.notifyMe.title".localized, completedDate.dayMonthFormatted()),
                                       xibName: .buttonCell,
                                       theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                                          bottomInset: .zero),
                                       selectionAction: { [weak self] _ in
            self?.notifyMe()
            self?.dismiss(animated: true, completion: nil)
        },
                                       willDisplay: { cell in
            (cell as? ButtonCell)?.button.accessibilityHint = footer
        })
        let footerRow: CVRow = footerRow(title: footer)
        return [notifyMeRow, footerRow]
    }

    func addToFavoriteRows() -> [CVRow] {
        let footer: String = "vaccineCompletionController.footer.favorite".localized
        let addToFavorieRow: CVRow = CVRow(title: "vaccineCompletionController.button.favorite.title".localized,
                                           xibName: .buttonCell,
                                           theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                                              bottomInset: .zero),
                                           selectionAction: { [weak self] _ in
            self?.addToFavorite()
            self?.dismiss(animated: true, completion: nil)
        },
                                           willDisplay: { cell in
            (cell as? ButtonCell)?.button.accessibilityHint = footer
        })
        let footerRow: CVRow = footerRow(title: footer)
        return [addToFavorieRow, footerRow]
    }

    func notifyMeAndFavoriteRows() -> [CVRow] {
        let footer: String = String(format: "vaccineCompletionController.footer.notifyAndFavorite".localized, completedDate.dayMonthFormatted())
        let notifyMeAndFavoriteRow: CVRow = CVRow(title: String(format: "vaccineCompletionController.button.notifyAndFavorite.title".localized, completedDate.dayMonthFormatted()),
                                                  xibName: .buttonCell,
                                                  theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                                                     bottomInset: .zero),
                                                  selectionAction: { [weak self] _ in
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

    func footerRow(title: String) -> CVRow {
        CVRow(title: title,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.small,
                                 bottomInset: .zero,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.accessoryFont },
                                 titleColor: Appearance.Cell.Text.captionTitleColor),
              willDisplay: { cell in
            cell.isAccessibilityElement = false
            cell.accessibilityElements = []
            cell.accessibilityElementsHidden = true
        })
    }

    func notifyMe() {
        NotificationsManager.shared.scheduleCompletedVaccination(triggerDate: completedDate)
        HUD.flash(.success)
    }

    func addToFavorite() {
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
