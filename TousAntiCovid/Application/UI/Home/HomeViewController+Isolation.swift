// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  HomeViewController+Isolation.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/12/2020 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK
import PKHUD

extension HomeViewController {
    
    func isolationRows(isLastSectionBlock: Bool) -> [CVRow] {
        var rows: [CVRow] = []
        
        let recommendationState: IsolationManager.RecommendationState = IsolationManager.shared.currentRecommendationState
        let actionRows: [CVRow] = actionRowsFor(recommendationState: recommendationState)
        if recommendationState.isInitialSafeCase {
            rows.append(isolationSafeRow(recommendationState: recommendationState))
        } else {
            rows.append(isolationBlockTopRow(recommendationState: recommendationState, followedByActions: !actionRows.isEmpty, isLastSectionBlock: isLastSectionBlock))
        }
        rows.append(contentsOf: actionRows)
        
        return rows
    }
    
    private func isolationSafeRow(recommendationState: IsolationManager.RecommendationState) -> CVRow {
        let title: String = "isolation.recommendation.\(recommendationState.rawValue).title".localized
        let subtitle: String = "isolation.recommendation.\(recommendationState.rawValue).body".localized
        let row: CVRow = CVRow(title: title,
                               subtitle: subtitle,
                               image: Asset.Images.doctorCard.image,
                               xibName: .isolationInitialCaseSafeCell,
                               theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                  topInset: .zero,
                                                  bottomInset: Appearance.Cell.Inset.medium,
                                                  textAlignment: .natural),
                               selectionAction: { [weak self] _ in
                                self?.didTouchOpenIsolationForm()
                               })
        
        return row
    }
    
    private func isolationBlockTopRow(recommendationState: IsolationManager.RecommendationState, followedByActions: Bool, isLastSectionBlock: Bool) -> CVRow {
        let title: String = "isolation.recommendation.\(recommendationState.rawValue).title".localized
        var subtitle: String = "isolation.recommendation.\(recommendationState.rawValue).body".localized
        
        if let date = IsolationManager.shared.currentIsolationEndDate {
            let placeholder: String = "%@"
            let cleanedString: String = subtitle.replacingOccurrences(of: "%@", with: "")
            let placeholdersCount: Int = (subtitle.count - cleanedString.count) / placeholder.count
            let values: [String] = (0..<placeholdersCount).map { _ in date.dayMonthYearFormatted() }
            subtitle = String(format: subtitle, arguments: values.map { $0 as CVarArg })
        }
        
        let image: UIImage = recommendationState.isInitialCase ? Asset.Images.badge.image : Asset.Images.hand.image
        let backgroundColor: UIColor = Appearance.tintColor
        let row: CVRow = CVRow(title: title,
                               subtitle: subtitle,
                               image: image,
                               xibName: .isolationTopCell,
                               theme:  CVRow.Theme(backgroundColor: backgroundColor,
                                                   topInset: .zero,
                                                   bottomInset: followedByActions ? .zero : (isLastSectionBlock ? .zero : Appearance.Cell.Inset.medium),
                                                   textAlignment: .natural,
                                                   titleColor: Appearance.Button.Primary.titleColor,
                                                   subtitleColor: Appearance.Button.Primary.titleColor,
                                                   imageTintColor: Appearance.Button.Primary.titleColor,
                                                   separatorLeftInset: followedByActions ? Appearance.Cell.leftMargin : nil,
                                                   separatorRightInset: followedByActions ? Appearance.Cell.leftMargin : nil,
                                                   maskedCorners: followedByActions ? .top : .all),
                               selectionAction: { [weak self] _ in
                                    self?.didTouchOpenIsolationForm()
                               })
        return row
    }
    
    private func actionRowsFor(recommendationState: IsolationManager.RecommendationState) -> [CVRow] {
        let rows: [CVRow]
        switch recommendationState {
        case .initialCaseSafe:
            rows = []
        case .initialCaseAtRiskOrSick:
            rows = [defineIsolationActionRow(recommendationState: recommendationState)]
        case .allGood:
            rows = [changeStateActionRow(recommendationState: recommendationState)]
        case .symptoms:
            rows = [testingSitesActionRow(recommendationState: recommendationState),
                    positiveTestActionRow(recommendationState: recommendationState),
                    negativeTestActionRow(recommendationState: recommendationState, openFormController: false)]
        case .symptomsTested:
            rows = [changeStateActionRow(recommendationState: recommendationState)]
        case .contactCaseUnknownIndex:
            rows = [testingSitesActionRow(recommendationState: recommendationState),
                    symptomsActionRow(recommendationState: recommendationState, isLastAction: false),
                    positiveTestActionRow(recommendationState: recommendationState),
                    negativeTestActionRow(recommendationState: recommendationState, openFormController: false)]
        case .contactCaseKnownIndexNotTested:
            rows = [testingSitesActionRow(recommendationState: recommendationState),
                    positiveTestActionRow(recommendationState: recommendationState),
                    negativeTestActionRow(recommendationState: recommendationState, openFormController: true)]
        case .contactCaseKnownIndexTestedKnownDate:
            rows = [symptomsActionRow(recommendationState: recommendationState, isLastAction: true)]
        case .contactCaseKnownIndexTestedUnknownDate:
            rows = [havingDateActionRow(recommendationState: recommendationState, isLastAction: false),
                    symptomsActionRow(recommendationState: recommendationState, isLastAction: true)]
        case .contactCasePostIsolationPeriod:
            rows = []
        case .positiveCaseNoSymptoms:
            rows = []
        case .positiveCaseSymptomsDuringIsolation:
            rows = IsolationManager.shared.isolationIsFeverReminderScheduled == true ? [] : [scheduleReminderActionRow(recommendationState: recommendationState)]
        case .positiveCaseSymptomsAfterIsolation:
            rows = [answerStillHavingFeverActionRow(recommendationState: recommendationState)]
        case .positiveCasePostIsolationPeriod:
            rows = []
        case .positiveCaseSymptomsAfterIsolationStillHavingFever:
            rows = [noMoreFeverActionRow(recommendationState: recommendationState)]
        case .indeterminate:
            rows = []
        }
        return rows
    }
    
    private func defineIsolationActionRow(recommendationState: IsolationManager.RecommendationState) -> CVRow {
        actionRow(title: "isolation.recommendation.\(recommendationState.rawValue).defineIsolationPeriod".localized, isLastAction: true) { [weak self] in
            IsolationManager.shared.resetData()
            self?.didTouchOpenIsolationForm()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                IsolationManager.shared.updateStateBasedOnAppMainStateIfNeeded()
            }
        }
    }
    
    private func changeStateActionRow(recommendationState: IsolationManager.RecommendationState) -> CVRow {
        actionRow(title: "isolation.recommendation.\(recommendationState.rawValue).changeMyState".localized, isLastAction: true) { [weak self] in
            self?.didTouchOpenIsolationForm()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                IsolationManager.shared.resetData()
            }
        }
    }
    
    private func testingSitesActionRow(recommendationState: IsolationManager.RecommendationState) -> CVRow {
        actionRow(title: "isolation.recommendation.\(recommendationState.rawValue).testingSites".localized, isLastAction: false) {
            URL(string: "myHealthController.testingSites.url".localized)?.openInSafari()
        }
    }
    
    private func positiveTestActionRow(recommendationState: IsolationManager.RecommendationState) -> CVRow {
        actionRow(title: "isolation.recommendation.\(recommendationState.rawValue).positiveTest".localized, isLastAction: false) { [weak self] in
            self?.didTouchOpenIsolationForm()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                IsolationManager.shared.updateState(.positiveCase)
            }
        }
    }
    
    private func negativeTestActionRow(recommendationState: IsolationManager.RecommendationState, openFormController: Bool) -> CVRow {
        actionRow(title: "isolation.recommendation.\(recommendationState.rawValue).negativeTest".localized, isLastAction: true) { [weak self] in
            if openFormController {
                self?.didTouchOpenIsolationForm()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    IsolationManager.shared.setNegativeTest()
                }
            } else {
                IsolationManager.shared.setNegativeTest()
            }
        }
    }

    private func symptomsActionRow(recommendationState: IsolationManager.RecommendationState, isLastAction: Bool) -> CVRow {
        actionRow(title: "isolation.recommendation.\(recommendationState.rawValue).symptoms".localized, isLastAction: isLastAction) { [weak self] in
            guard let self = self else { return }
            IsolationManager.shared.showSymptomsAlert(on: self) { [weak self] in
                self?.didTouchOpenIsolationForm()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    IsolationManager.shared.updateState(.symptoms)
                }
            }
        }
    }
    
    private func havingDateActionRow(recommendationState: IsolationManager.RecommendationState, isLastAction: Bool) -> CVRow {
        actionRow(title: "isolation.recommendation.\(recommendationState.rawValue).havingTheDate".localized, isLastAction: isLastAction) { [weak self] in
            self?.didTouchOpenIsolationForm()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                IsolationManager.shared.setKnowsIndexSymptomsEndDate(true)
            }
        }
    }
    
    private func scheduleReminderActionRow(recommendationState: IsolationManager.RecommendationState) -> CVRow {
        actionRow(title: "isolation.recommendation.\(recommendationState.rawValue).scheduleReminder".localized, isLastAction: true) {
            NotificationsManager.shared.scheduleStillHavingFeverNotification(minHour: ParametersManager.shared.minHourContactNotif,
                                                                             maxHour: ParametersManager.shared.maxHourContactNotif,
                                                                             triggerDate: IsolationManager.shared.stillHavingFeverNotificationTriggerDate)
            IsolationManager.shared.setFeverReminderScheduled()
            HUD.flash(.success)
        }
    }
    
    private func answerStillHavingFeverActionRow(recommendationState: IsolationManager.RecommendationState) -> CVRow {
        actionRow(title: "isolation.recommendation.\(recommendationState.rawValue).stillHavingFever".localized, isLastAction: true) { [weak self] in
            self?.didTouchOpenIsolationForm()
        }
    }
    
    private func noMoreFeverActionRow(recommendationState: IsolationManager.RecommendationState) -> CVRow {
        actionRow(title: "isolation.recommendation.\(recommendationState.rawValue).noMoreFever".localized, isLastAction: true) {
            IsolationManager.shared.setStillHavingFever(false)
        }
    }
    
    func actionRow(title: String, isLastAction: Bool, actionBlock: @escaping () -> ()) -> CVRow {
        let row: CVRow = CVRow(title: title,
                               xibName: .standardCardCell,
                               theme:  CVRow.Theme(backgroundColor: Appearance.Cell.Isolation.actionBackgroundColor,
                                                   topInset: .zero,
                                                   bottomInset: isLastAction ? Appearance.Cell.Inset.medium : .zero,
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
    
}
