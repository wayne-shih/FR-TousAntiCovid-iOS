// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ManageDataController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 05/05/2020 - for the TousAntiCovid project.
//


import UIKit
import PKHUD
import RobertSDK
import ServerSDK

final class ManageDataController: CVTableViewController {
    
    @UserDefault(key: .autoBrightnessActivated)
    private var autoBrightnessActivated: Bool = true
    
    init() {
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("You must use the standard init() method.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }
    
    deinit {
        LocalizationsManager.shared.removeObserver(self)
    }
    
    func updateTitle() {
        title = "manageDataController.title".localized
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                sectionHeaderRow(textPrefix: "manageDataController.showInfoNotifications")
                switchRow(textPrefix: "manageDataController.showInfoNotifications",
                          isOn: NotificationsManager.shared.showNewInfoNotification, dynamicSwitchLabel: false) { isOn in
                    NotificationsManager.shared.showNewInfoNotification = isOn
                }
            } header: {
                .groupedHeader
            }

            CVSection {
                sectionHeaderRow(textPrefix: "manageDataController.userLanguage")
                selectableRow(title: "manageDataController.languageFR".localized,
                              isSelected: Locale.currentAppLanguageCode == Constant.Language.french, separatorLeftInset: Appearance.Cell.leftMargin,
                              selectionBlock: {
                    Constant.appLanguage =  Constant.Language.french
                })
                selectableRow(title: "manageDataController.languageEN".localized,
                              isSelected: Locale.currentAppLanguageCode == Constant.Language.english,
                              selectionBlock: {
                    Constant.appLanguage =  Constant.Language.english
                })
            } header: {
                .groupedHeader
            }
            
            if ParametersManager.shared.smartWalletFeatureActivated {
                CVSection {
                    sectionHeaderRow(textPrefix: "manageDataController.smartWalletActivation")
                    switchRow(textPrefix: "manageDataController.smartWalletActivation",
                              isOn: WalletManager.shared.smartWalletActivated, dynamicSwitchLabel: true) { isOn in
                        WalletManager.shared.smartWalletActivated = isOn
                    }
                } header: {
                    .groupedHeader
                }
            }

            CVSection {
                sectionHeaderRow(textPrefix: "manageDataController.hideStatus")
                switchRow(textPrefix: "manageDataController.hideStatus",
                          isOn: StatusManager.shared.hideStatus,
                          dynamicSwitchLabel: false) { isOn in
                    StatusManager.shared.hideStatus = isOn
                }
            } header: {
                .groupedHeader
            }
            
            CVSection {
                sectionHeaderRow(textPrefix: "common.settings.fullBrightnessSwitch")
                switchRow(textPrefix: "common.settings.fullBrightnessSwitch",
                          isOn: autoBrightnessActivated,
                          dynamicSwitchLabel: true) { [weak self] isOn in
                    self?.autoBrightnessActivated = isOn
                }
            } header: {
                .groupedHeader
            }

            CVSection {
                sectionHeaderRow(textPrefix: "manageDataController.attestationsData")
                buttonRow(textPrefix: "manageDataController.attestationsData") { [weak self] in
                    self?.eraseAttestationDataButtonPressed()
                }
            } header: {
                .groupedHeader
            }

            if WalletManager.shared.isWalletActivated {
                CVSection {
                    let activityPassAutoRenewable: Bool = WalletManager.shared.isActivityPassActivated && ParametersManager.shared.activityPassAutoRenewable
                    if activityPassAutoRenewable {
                        sectionHeaderRow(textPrefix: "manageDataController.walletDataAndActivityPass")
                        buttonRow(textPrefix: "manageDataController.walletData", separatorLeftInset: Appearance.Cell.leftMargin) { [weak self] in
                            self?.eraseWalletDataButtonPressed()
                        }
                        switchRow(textPrefix: "manageDataController.activityPass", isOn: WalletManager.shared.activityPassAutoRenewalActivated, dynamicSwitchLabel: false) { [weak self] isOn in
                            WalletManager.shared.activityPassAutoRenewalActivated = isOn
                            self?.reloadUI()
                        }
                    } else {
                        sectionHeaderRow(textPrefix: "manageDataController.walletData")
                        buttonRow(textPrefix: "manageDataController.walletData", separatorLeftInset: nil) { [weak self] in
                            self?.eraseWalletDataButtonPressed()
                        }
                    }
                } header: {
                    .groupedHeader
                }
            }

            if ConfigManager.shared.venuesFeaturedWasActivatedAtLeastOneTime || !VenuesManager.shared.venuesQrCodes.isEmpty {
                CVSection {
                    sectionHeaderRow(textPrefix: "manageDataController.venuesData")
                    buttonRow(textPrefix: "manageDataController.venuesData") { [weak self] in
                        self?.eraseVenuesDataButtonPressed()
                    }
                } header: {
                    .groupedHeader
                }
            }

            if ParametersManager.shared.displayIsolation {
                CVSection {
                    sectionHeaderRow(textPrefix: "manageDataController.isolationData")
                    buttonRow(textPrefix: "manageDataController.isolationData") { [weak self] in
                        self?.eraseIsolationDataButtonPressed()
                    }
                } header: {
                    .groupedHeader
                }
            }

            CVSection {
                sectionHeaderRow(textPrefix: "manageDataController.eraseLocalHistory")
                buttonRow(textPrefix: "manageDataController.eraseLocalHistory") { [weak self] in
                    self?.eraseLocalHistoryButtonPressed()
                }
            } header: {
                .groupedHeader
            }

            CVSection {
                sectionHeaderRow(textPrefix: "manageDataController.eraseRemoteContact")
                buttonRow(textPrefix: "manageDataController.eraseRemoteContact") { [weak self] in
                    self?.eraseContactsButtonPressed()
                }
            } header: {
                .groupedHeader
            }


            if ParametersManager.shared.isAnalyticsOn {
                CVSection {
                    sectionHeaderRow(textPrefix: "manageDataController.analytics")
                    switchRow(textPrefix: "manageDataController.analytics",
                              separatorLeftInset: Appearance.Cell.leftMargin,
                              isOn: AnalyticsManager.shared.isOptIn,
                              dynamicSwitchLabel: true) { isOptIn in
                        AnalyticsManager.shared.setOptIn(to: isOptIn)
                    }
                    buttonRow(textPrefix: "manageDataController.analytics") { [weak self] in
                        self?.eraseAnalyticsButtonPressed()
                    }
                } header: {
                    .groupedHeader
                }
            }

            CVSection {
                let logsFilesUrls: [URL] = StackLogger.getLogFilesUrls()
                let subtitle: String =  getLogSubtitle(logsFileUrlsCount: logsFilesUrls.count)
                sectionHeaderRow(title: "manageDataController.logFiles.title".localized, subtitle: subtitle)
                if !logsFilesUrls.isEmpty {
                    buttonRow(textPrefix: "manageDataController.logFiles.share", separatorLeftInset: Appearance.Cell.leftMargin, isDestuctive: false) { [weak self] in
                        guard let self = self else { return }
                        logsFilesUrls.share(from: self)
                    }
                    buttonRow(textPrefix: "manageDataController.logFiles.delete", isDestuctive: true) { [weak self] in
                        self?.deleteLogsFilesButtonPressed()
                    }
                }

            } header: {
                .groupedHeader
            }

            CVSection {
                sectionHeaderRow(textPrefix: "manageDataController.quitStopCovid")
                buttonRow(textPrefix: "manageDataController.quitStopCovid", isDestuctive: true) { [weak self] in
                    self?.quitButtonPressed()
                }
            } header: {
                .groupedHeader
            }
        }
    }

    private func updateLeftBarButton() {
        navigationItem.leftBarButtonItem?.title = "common.close".localized
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
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

    private func sectionHeaderRow(textPrefix: String) -> CVRow {
        sectionHeaderRow(title: "\(textPrefix).title".localized,
                         subtitle: "\(textPrefix).subtitle".localized)
    }
    
    private func sectionHeaderRow(title: String, subtitle: String) -> CVRow {
        var textRow: CVRow = CVRow(title: title,
                                   subtitle: subtitle,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                                      bottomInset: Appearance.Cell.Inset.normal,
                                                      textAlignment: .natural,
                                                      titleFont: { Appearance.Cell.Text.smallHeadTitleFont },
                                                      separatorLeftInset: Appearance.Cell.leftMargin))
        textRow.theme.backgroundColor = Appearance.Cell.cardBackgroundColor
        return textRow
    }

    private func selectableRow(title: String, isSelected: Bool, separatorLeftInset: CGFloat? = nil, selectionBlock: @escaping () -> ()) -> CVRow {
        CVRow(title: title,
              isOn: isSelected,
              xibName: .selectableCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.normal,
                                 bottomInset: Appearance.Cell.Inset.normal,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.standardFont },
                                 separatorLeftInset: separatorLeftInset),
              selectionAction: {
            selectionBlock()
        })
    }
    
    private func switchRow(textPrefix: String, separatorLeftInset: CGFloat? = nil, isOn: Bool, dynamicSwitchLabel: Bool, handler: @escaping (_ isOn: Bool) -> ()) -> CVRow {
        CVRow(title: (dynamicSwitchLabel ? (isOn ? "\(textPrefix).switch.on" : "\(textPrefix).switch.off") : "\(textPrefix).button").localized,
              isOn: isOn,
              xibName: .standardSwitchCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.small,
                                 bottomInset: Appearance.Cell.Inset.small,
                                 textAlignment: .left,
                                 titleFont: { Appearance.Cell.Text.standardFont },
                                 separatorLeftInset: separatorLeftInset),
              valueChanged: { [weak self] value in
            guard let isOn = value as? Bool else { return }
            handler(isOn)
            self?.reloadUI()
        })
    }
    
    private func buttonRow(textPrefix: String, separatorLeftInset: CGFloat? = nil, isDestuctive: Bool = false, handler: @escaping () -> ()) -> CVRow {
        var buttonRow: CVRow = CVRow(title: "\(textPrefix).button".localized,
                                     xibName: .standardCell,
                                     theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                                        bottomInset: Appearance.Cell.Inset.normal,
                                                        textAlignment: .natural,
                                                        titleFont: { Appearance.Cell.Text.standardFont },
                                                        titleColor: isDestuctive ? Asset.Colors.error.color : Asset.Colors.tint.color,
                                                        separatorLeftInset: separatorLeftInset,
                                                        accessoryType: UITableViewCell.AccessoryType.none),
                                     selectionAction: { handler() },
                                     willDisplay: { cell in
            cell.cvTitleLabel?.accessibilityTraits = .button
        })
        buttonRow.theme.backgroundColor = Appearance.Cell.cardBackgroundColor
        return buttonRow
    }
    
    @objc private func didTouchBackButton() {
        navigationController?.popViewController(animated: true)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationChildController?.scrollViewDidScroll(scrollView)
    }
    
    private func eraseAttestationDataButtonPressed() {
        showAlert(title: "manageDataController.attestationsData.confirmationDialog.title".localized,
                  message: "manageDataController.attestationsData.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized, handler:  { [weak self] in
            AttestationsManager.shared.clearAllData()
            self?.showFlash()
        })
    }
    
    private func eraseVenuesDataButtonPressed() {
        showAlert(title: "manageDataController.venuesData.confirmationDialog.title".localized,
                  message: "manageDataController.venuesData.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized, handler:  { [weak self] in
            VenuesManager.shared.clearAllData()
            self?.showFlash()
        })
    }
    
    private func eraseIsolationDataButtonPressed() {
        showAlert(title: "manageDataController.isolationData.confirmationDialog.title".localized,
                  message: "manageDataController.isolationData.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized, handler:  { [weak self] in
            IsolationManager.shared.resetData()
            self?.showFlash()
        })
    }
    
    private func eraseLocalHistoryButtonPressed() {
        showAlert(title: "manageDataController.eraseLocalHistory.confirmationDialog.title".localized,
                  message: "manageDataController.eraseLocalHistory.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized, handler:  { [weak self] in
            RBManager.shared.clearLocalProximityList()
            self?.showFlash()
        })
    }
    
    private func eraseWalletDataButtonPressed() {
        showAlert(title: "manageDataController.walletData.confirmationDialog.title".localized,
                  message: "manageDataController.walletData.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized, handler: { [weak self] in
            WalletManager.shared.clearAllData()
            self?.showFlash()
        })
    }
    
    private func eraseContactsButtonPressed() {
        showAlert(title: "manageDataController.eraseRemoteContact.confirmationDialog.title".localized,
                  message: "manageDataController.eraseRemoteContact.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized, handler: { [weak self] in
            if RBManager.shared.isRegistered {
                HUD.show(.progress)
                RBManager.shared.deleteExposureHistory { error in
                    HUD.hide()
                    if let error = error {
                        AnalyticsManager.shared.reportError(serviceName: "deleteExposureHistory", apiVersion: ParametersManager.shared.apiVersion, code: (error as NSError).code)
                        if (error as NSError).code == -1 {
                            self?.showAlert(title: "common.error.clockNotAligned.title".localized,
                                            message: "common.error.clockNotAligned.message".localized,
                                            okTitle: "common.ok".localized)
                        } else {
                            let message: String = error.isNetworkConnectionError ? "homeScreen.error.networkUnreachable".localized : "common.error.server".localized
                            self?.showAlert(title: "common.error".localized,
                                            message: message,
                                            okTitle: "common.ok".localized)
                        }
                    } else {
                        self?.showFlash()
                    }
                }
            } else {
                self?.showFlash()
            }
        })
    }
    
    private func eraseAnalyticsButtonPressed() {
        showAlert(title: "manageDataController.analytics.confirmationDialog.title".localized,
                  message: "manageDataController.analytics.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  cancelTitle: "common.no".localized, handler:  { [weak self] in
            self?.deleteAnalytics()
        })
    }

    private func deleteAnalytics() {
        AnalyticsManager.shared.reportAppEvent(.e17)
        AnalyticsManager.shared.requestDeleteAnalytics()
        StatusManager.shared.status()
        showAlert(title: "manageDataController.analytics.successDialog.title".localized,
                  message: "manageDataController.analytics.successDialog.message".localized,
                  okTitle: "common.ok".localized)
    }
    
    private func quitButtonPressed() {
        showAlert(title: "manageDataController.quitStopCovid.confirmationDialog.title".localized,
                  message: "manageDataController.quitStopCovid.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized, handler:  {
            switch ParametersManager.shared.apiVersion {
            case .v5, .v6:
                HUD.show(.progress)
                RBManager.shared.unregister { [weak self] error, isErrorBlocking in
                    HUD.hide()
                    if let error = error {
                        AnalyticsManager.shared.reportError(serviceName: "unregister", apiVersion: ParametersManager.shared.apiVersion, code: (error as NSError).code)
                        let message: String = error.isNetworkConnectionError ? "homeScreen.error.networkUnreachable".localized : "common.error.server".localized
                        self?.showAlert(title: "common.error".localized,
                                        message: message,
                                        okTitle: "common.ok".localized)
                    }
                    self?.processPostUnregisterActions(error, isErrorBlocking: isErrorBlocking)
                }
            }
        })
    }

    private func getLogSubtitle(logsFileUrlsCount: Int) -> String {
        var subtitle: String =  "manageDataController.logFiles.subtitle".localized
        if logsFileUrlsCount > 0 {
            subtitle += "\n\n\(String(format: "manageDataController.logFiles.logsFilesCount".localized, logsFileUrlsCount))"
        } else {
            subtitle += "\n\n\("manageDataController.logFiles.noLogs".localized)"
        }
        return subtitle
    }

    private func deleteLogsFilesButtonPressed() {
        showAlert(title: "manageDataController.logFiles.delete.confirmationDialog.title".localized,
                  message: "manageDataController.logFiles.delete.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized, handler:  { [weak self] in
            StackLogger.deleteAllLogsFiles()
            HUD.flash(.success)
            self?.reloadUI()
        })
    }
    
    private func processPostUnregisterActions(_ error: Error?, isErrorBlocking: Bool) {
        if let error = error, (error as NSError).code == -1 {
            showAlert(title: "common.error.clockNotAligned.title".localized,
                      message: "common.error.clockNotAligned.message".localized,
                      okTitle: "common.ok".localized)
        } else if let error = error, isErrorBlocking {
            let message: String = error.isNetworkConnectionError ? "homeScreen.error.networkUnreachable".localized : "common.error.server".localized
            showAlert(title: "common.error".localized,
                            message: message,
                            okTitle: "common.ok".localized)
        } else {
            KeyFiguresManager.shared.currentPostalCode = nil
            AttestationsManager.shared.clearAllData()
            VenuesManager.shared.clearAllData()
            VaccinationCenterManager.shared.clearAllData()
            WalletManager.shared.clearAllData()
            ETagManager.shared.clearAllData()
            SVETagManager.shared.clearAllData()

            AnalyticsManager.shared.reset()
            AnalyticsManager.shared.setOptIn(to: true)
            NotificationCenter.default.post(name: .changeAppState, object: RootCoordinator.State.onboarding, userInfo: nil)
        }
    }
    
}

extension ManageDataController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        updateLeftBarButton()
        reloadUI()
    }
    
}
