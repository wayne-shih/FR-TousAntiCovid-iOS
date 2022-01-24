// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MyHealthController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK
import Lottie

final class MyHealthController: CVTableViewController {
    
    private let didTouchAbout: () -> ()
    private let didTouchCautionMeasures: () -> ()
    private let didTouchRisksUILevelSectionLink: (RisksUILevelSectionLink?) -> ()
    private weak var animationView: AnimationView?
    
    init(didTouchAbout: @escaping () -> (), didTouchCautionMeasures: @escaping () -> (), didTouchRisksUILevelSectionLink: @escaping (RisksUILevelSectionLink?) -> ()) {
        self.didTouchAbout = didTouchAbout
        self.didTouchCautionMeasures = didTouchCautionMeasures
        self.didTouchRisksUILevelSectionLink = didTouchRisksUILevelSectionLink
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
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    private func updateTitle() {
        title = RBManager.shared.isImmune ? "myHealthController.sick.title".localized : "myHealthController.title".localized
    }
    
    override func createSections() -> [CVSection] {
        var rows: [CVRow] = []
        let ameliUrl: String = ParametersManager.shared.ameliUrl
        if RBManager.shared.isImmune {
            rows = sickHeaderRows()
            if let declarationToken = RBManager.shared.declarationToken, !declarationToken.isEmpty, !ameliUrl.isEmpty {
                let ameliWithDeclarationUrl: String = String(format: ameliUrl, declarationToken)
                rows.append(contentsOf: workStoppingSection(with: ameliWithDeclarationUrl))
            }
            rows.append(contentsOf: sickActionsRows())
        } else if !RBManager.shared.isRegistered {
            rows = [headerRow()] + notRegisteredRows()
        } else if let currentRiskLevel = RisksUIManager.shared.currentLevel {
            rows = [headerRow()]
            if RBManager.shared.lastStatusReceivedDate != nil {
                let isStatusOnGoing: Bool = StatusManager.shared.isStatusOnGoing
                rows.append(riskRow(for: currentRiskLevel, isStatusOnGoing: isStatusOnGoing))
                if isStatusOnGoing {
                    rows.append(statusVerificationRow(for: currentRiskLevel))
                }
            }
            if let declarationToken = RBManager.shared.declarationToken, !declarationToken.isEmpty, !ameliUrl.isEmpty {
                let ameliWithDeclarationUrl: String = String(format: ameliUrl, declarationToken)
                rows.append(contentsOf: workStoppingSection(with: ameliWithDeclarationUrl))
            }
            rows.append(contentsOf: sectionRows(for: currentRiskLevel))
        }
        return [CVSection(rows: rows)]
    }

    private func riskRow(for currentRiskLevel: RisksUILevel, isStatusOnGoing: Bool) -> CVRow {
        let notificationDate: Date? = RBManager.shared.lastStatusReceivedDate
        let notificationDateString: String? = currentRiskLevel.riskLevel == 0 ? notificationDate?.relativelyFormatted() : nil
        var lastContactDateString: String? = nil
        if let lastContactDateFrom = RisksUIManager.shared.lastContactDateFrom?.dayShortMonthFormatted(), let lastContactDateTo = RisksUIManager.shared.lastContactDateTo?.dayShortMonthYearFormatted(timeZoneIndependant: true) {
            lastContactDateString = String(format: "myHealthStateHeaderCell.exposureDate.range".localized, lastContactDateFrom, lastContactDateTo)
        } else if let lastContactDate = RisksUIManager.shared.lastContactDateFrom?.dayMonthYearFormatted() {
            lastContactDateString = lastContactDate
        }

        return CVRow(title: currentRiskLevel.labels.detailTitle.localized,
                     subtitle: currentRiskLevel.labels.detailSubtitle.localized,
                     accessoryText: notificationDateString,
                     footerText: lastContactDateString,
                     xibName: .myHealthStateHeaderCell,
                     theme: CVRow.Theme(topInset: .zero,
                                        bottomInset: isStatusOnGoing ? .zero : Appearance.Cell.Inset.medium,
                                        textAlignment: .natural,
                                        accessoryTextFont: { Appearance.Cell.Text.accessoryFont },
                                        maskedCorners: isStatusOnGoing ? .top : .all),
                     associatedValue: currentRiskLevel)
    }

    private func statusVerificationRow(for currentRiskLevel: RisksUILevel) -> CVRow {
        CVRow(title: "home.healthSection.statusState".localized,
              xibName: .statusVerificationCell,
              theme: CVRow.Theme(topInset: -2.0,
                                 bottomInset: Appearance.Cell.Inset.medium,
                                 textAlignment: .natural,
                                 maskedCorners: .bottom),
              associatedValue: currentRiskLevel)

    }
    
    private func sickHeaderRows() -> [CVRow] {
        var rows: [CVRow] = []
        let imageRow: CVRow = CVRow(image: Asset.Images.sick.image,
                                    xibName: .onboardingImageCell,
                                    theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium))
        rows.append(imageRow)
        let declarationTextRow: CVRow = CVRow(title: "myHealthController.sick.mainMessage.title".localized,
                                              subtitle: "myHealthController.sick.mainMessage.subtitle".localized,
                                              xibName: .textCell,
                                              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.large, bottomInset: Appearance.Cell.Inset.large))
        rows.append(declarationTextRow)
        return rows
    }

    private func sickActionsRows() -> [CVRow] {
        var rows: [CVRow] = []

        let recommendationsButton: CVRow = CVRow(title: "myHealthController.button.recommendations".localized,
                                        xibName: .buttonCell,
                                        theme: CVRow.Theme(topInset: Appearance.Cell.Inset.small, bottomInset: Appearance.Cell.Inset.small),
                                        selectionAction: { _ in
            URL(string: "myHealthController.button.recommendations.url".localized)?.openInSafari()
        })
        rows.append(recommendationsButton)
        let phoneButton: CVRow = CVRow(title: "myHealthController.step.appointment.buttonTitle".localized,
                                            xibName: .buttonCell,
                                            theme: CVRow.Theme(topInset: Appearance.Cell.Inset.small, bottomInset: Appearance.Cell.Inset.small),
                                            selectionAction: { [weak self] _ in
            guard let self = self else { return }
            "callCenter.phoneNumber".localized.callPhoneNumber(from: self)
        })
        rows.append(phoneButton)
        let measuresButton: CVRow = CVRow(title: "myHealthController.button.cautionMeasures".localized,
                                            xibName: .buttonCell,
                                            theme: CVRow.Theme(topInset: Appearance.Cell.Inset.small, bottomInset: Appearance.Cell.Inset.small),
                                            selectionAction: { [weak self] _ in
                                                self?.didTouchCautionMeasures()
        })
        rows.append(measuresButton)
        return rows
    }

    private func headerRow() -> CVRow {
        if StatusManager.shared.currentStatusRiskLevel?.riskLevel ?? 0.0 > 0.0 {
            let animation: Animation = Animation.named("DoctorAlert")!
            return CVRow(accessoryText: Date().shortDateTimeFormatted(),
                         animation: animation,
                         xibName: .animatedHeaderCell,
                         theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                            accessoryTextFont: { .marianneBold(size: 14.0) },
                                            accessoryTextColor: .white),
                         secondarySelectionAction: { [weak self] in
                self?.showRiskMoreInfoAlert()
            }, willDisplay: { [weak self] cell in
                self?.animationView = (cell as? AnimatedHeaderCell)?.animationView
            })
        } else {
            return CVRow(image: Asset.Images.health.image,
                         xibName: .imageCell,
                         theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium,
                                            imageRatio: 375.0 / 116.0))
        }
    }

    private func notRegisteredRows() -> [CVRow] {
        let textRow: CVRow = CVRow(title: "myHealthController.notRegistered.mainMessage.title".localized,
                                   subtitle: "myHealthController.notRegistered.mainMessage.subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: Appearance.Cell.Inset.medium))
        return [textRow]
    }

    private func sectionRows(for currentRiskLevel: RisksUILevel) -> [CVRow] {
        currentRiskLevel.sections.map { section in
            CVRow(title: section.section.localized,
                  subtitle: section.description.localized,
                  buttonTitle: section.link?.label.localized,
                  xibName: .paragraphCell,
                  theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                     topInset: .zero,
                                     bottomInset: Appearance.Cell.Inset.medium,
                                     textAlignment: .left,
                                     titleFont: { Appearance.Cell.Text.headTitleFont }),
                  selectionAction: section.link == nil ? nil : { [weak self] _ in
                    self?.didTouchRisksUILevelSectionLink(section.link)
                  })
        }
    }

    private func workStoppingSection(with ameliWithDeclarationUrl: String) -> [CVRow] {
        var rows: [CVRow] = [workStoppingTopRow()]
        let workStoppingLinkRow: CVRow = actionRow(title: "myHealthController.workStopping.link".localized, isLastAction: false) {
            URL(string: ameliWithDeclarationUrl)?.openInSafari()
        }
        rows.append(workStoppingLinkRow)

        let workStoppingShareRow: CVRow = actionRow(title: "myHealthController.workStopping.share".localized, isLastAction: true) { [weak self] in
            self?.didTouchSharing(sharingText: ameliWithDeclarationUrl)
        }
        rows.append(workStoppingShareRow)
        return rows
    }

    private func workStoppingTopRow() -> CVRow {
        let backgroundColor: UIColor = Appearance.tintColor
        let row: CVRow = CVRow(title: "myHealthController.workStopping.title".localized,
                               subtitle: "myHealthController.workStopping.message".localized,
                               image: Asset.Images.hand.image,
                               xibName: .isolationTopCell,
                               theme:  CVRow.Theme(backgroundColor: backgroundColor,
                                                   topInset: .zero,
                                                   bottomInset: .zero,
                                                   textAlignment: .natural,
                                                   titleColor: Appearance.Button.Primary.titleColor,
                                                   subtitleColor: Appearance.Button.Primary.titleColor,
                                                   imageTintColor: Appearance.Button.Primary.titleColor,
                                                   separatorLeftInset: Appearance.Cell.leftMargin,
                                                   separatorRightInset: Appearance.Cell.leftMargin,
                                                   maskedCorners: .top))
        return row
    }

    private func actionRow(title: String, isLastAction: Bool, actionBlock: @escaping () -> ()) -> CVRow {
        let row: CVRow = CVRow(title: title,
                               xibName: .standardCardCell,
                               theme:  CVRow.Theme(backgroundColor: Appearance.Cell.Isolation.actionBackgroundColor,
                                                   topInset: .zero,
                                                   bottomInset: isLastAction ? Appearance.Cell.Inset.normal : .zero,
                                                   textAlignment: .natural,
                                                   titleFont: { Appearance.Cell.Text.actionTitleFont },
                                                   titleColor: Appearance.Button.Primary.titleColor,
                                                   separatorLeftInset: isLastAction ? nil : Appearance.Cell.leftMargin,
                                                   separatorRightInset: isLastAction ? nil : Appearance.Cell.leftMargin,
                                                   maskedCorners: isLastAction ? .bottom : .none),
                               selectionAction: { _ in
                                actionBlock()
                               })
        return row
    }

    private func didTouchSharing(sharingText: String) {
        let activityItems: [Any?] = [sharingText]
        let controller: UIActivityViewController = UIActivityViewController(activityItems: activityItems.compactMap { $0 }, applicationActivities: nil)
        controller.excludedActivityTypes = [.saveToCameraRoll, .print]
        present(controller, animated: true, completion: nil)
    }

    private func showRiskMoreInfoAlert() {
        let alertController: BottomSheetAlertController = .init(title: "myHealthController.riskMoreInfoAlert.title".localized,
                                                                message: "myHealthController.riskMoreInfoAlert.message".localized,
                                                                okTitle: "common.ok".localized)
        alertController.show()
    }

    private func initUI() {
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.animationView?.play()
        }
        LocalizationsManager.shared.addObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(statusDataChanged), name: .statusDataDidChange, object: nil)
    }

    private func removeObservers() {
        LocalizationsManager.shared.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func statusDataChanged() {
        reloadUI()
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationChildController?.scrollViewDidScroll(scrollView)
    }

}

extension MyHealthController: LocalizationsChangesObserver {

    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }

}
