//
//  WidgetManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 31/08/2020 - for the TousAntiCovid project.
//

import Foundation
import WidgetKit
#if !WIDGET
import UIKit
import RobertSDK
#endif

@available(iOS 14.0, *)
final class WidgetManager {
    
    static let shared: WidgetManager = WidgetManager()
    
    static let scheme: String = "tousanticovid"
    
    static let activationDeeplink: URL = URL(string: "\(scheme)://\(UrlAction.activation.rawValue)")!
    static let moreInformationsDeeplink: URL = URL(string: "\(scheme)://\(UrlAction.moreInformations.rawValue)")!
    
    var isProximityActivationWaiting: Bool = false
    
    enum UrlAction: String {
        case activation
        case moreInformations
    }

    @OptionalWidgetUserDefault(key: .currentRiskLevel)
    var currentRiskLevel: Double? {
        didSet {
            guard oldValue != currentRiskLevel else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    @OptionalWidgetUserDefault(key: .lastStatusReceivedDate)
    var lastStatusReceivedDate: Date? {
        didSet {
            guard oldValue != lastStatusReceivedDate else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    @WidgetUserDefault(key: .isOnboardingDone)
    var isOnboardingDone: Bool = false {
        didSet {
            guard oldValue != isOnboardingDone else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    @WidgetUserDefault(key: .isSick)
    var isSick: Bool = false {
        didSet {
            guard oldValue != isSick else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    @WidgetUserDefault(key: .isRegistered)
    var isRegistered: Bool = false {
        didSet {
            guard oldValue != isRegistered else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    #if !WIDGET
    @UserDefault(key: .isOnboardingDone)
    private var isAppOnboardingDone: Bool = false
    #endif
    
    @WidgetUserDefault(key: .isProximityActivated)
    private var isProximityActivated: Bool = false {
        didSet {
            guard oldValue != isProximityActivated else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    @WidgetUserDefault(key: .widgetAppName)
    var appName: String = ""
    @WidgetUserDefault(key: .widgetWelcomeTitle)
    var widgetWelcomeTitle: String = ""
    @WidgetUserDefault(key: .widgetWelcomeButtonTitle)
    var widgetWelcomeButtonTitle: String = ""
    @WidgetUserDefault(key: .widgetActivated)
    var widgetActivated: String = ""
    @WidgetUserDefault(key: .widgetDeactivated)
    var widgetDeactivated: String = ""
    @WidgetUserDefault(key: .widgetActivateProximityButtonTitle)
    var widgetActivateProximityButtonTitle: String = ""
    @WidgetUserDefault(key: .widgetFullTitleDate)
    var widgetFullTitleDate: String = ""
    @WidgetUserDefault(key: .widgetMoreInfo)
    var widgetMoreInfo: String = ""
    @WidgetUserDefault(key: .widgetOpenTheApp)
    var widgetOpenTheApp: String = ""
    @WidgetUserDefault(key: .widgetSickSmallTitle)
    var widgetSickSmallTitle: String = ""
    @WidgetUserDefault(key: .widgetSickFullTitle)
    var widgetSickFullTitle: String = ""
    @WidgetUserDefault(key: .widgetNoStatusInfo)
    var widgetNoStatusInfo: String = ""
    @WidgetUserDefault(key: .widgetSmallTitle)
    var widgetSmallTitle: String = ""
    @WidgetUserDefault(key: .widgetFullTitle)
    var widgetFullTitle: String = ""
    @WidgetUserDefault(key: .widgetGradientStartColor)
    var widgetGradientStartColor: String = ""
    @WidgetUserDefault(key: .widgetGradientEndColor)
    var widgetGradientEndColor: String = ""

    private init() {}
    
    #if !WIDGET
    func processOpeningUrl(_ url: URL) {
        guard url.scheme == WidgetManager.scheme && isOnboardingDone && !isSick else { return }
        let action: String = url.absoluteString.replacingOccurrences(of: "\(WidgetManager.scheme)://", with: "")
        guard let urlAction = WidgetManager.UrlAction(rawValue: action) else { return }
        switch urlAction {
        case .activation:
            if UIApplication.shared.applicationState == .active {
                triggerProximityActivation()
            } else {
                isProximityActivationWaiting = true
            }
        default:
            break
        }
    }
    
    func processUserActivity(_ userActivity: NSUserActivity) {
        let widgetKinds: [String] = ["TousAntiCovidWidget"]
        guard widgetKinds.contains(userActivity.activityType) && isOnboardingDone && !isSick else { return }
        guard !RBManager.shared.isRegistered else { return }
        NotificationCenter.default.post(name: .widgetDidRequestRegister, object: nil)
    }
    
    private func triggerProximityActivation() {
        guard RBManager.shared.canReactivateProximity else { return }
        if !RBManager.shared.isRegistered {
            NotificationCenter.default.post(name: .widgetDidRequestRegister, object: nil)
        } else if !RBManager.shared.isProximityActivated {
            RBManager.shared.isProximityActivated = true
            RBManager.shared.startProximityDetection()
            AnalyticsManager.shared.proximityDidStart()
        }
    }
    
    #endif
    
    func start() {
        #if !WIDGET
        NotificationCenter.default.addObserver(self, selector: #selector(statusDataChanged), name: .statusDataDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        LocalizationsManager.shared.addObserver(self)
        reloadStrings()
        #endif
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    #if !WIDGET
    @objc private func statusDataChanged() {
        isProximityActivated = RBManager.shared.isProximityActivated
        lastStatusReceivedDate = RBManager.shared.lastStatusReceivedDate
        currentRiskLevel = RisksUIManager.shared.currentLevel?.riskLevel
        isSick = RBManager.shared.isSick
        isRegistered = RBManager.shared.isRegistered
        isOnboardingDone = isAppOnboardingDone
        widgetGradientStartColor = RisksUIManager.shared.currentLevel?.color.from ?? ""
        widgetGradientEndColor = RisksUIManager.shared.currentLevel?.color.to ?? ""
        reloadStrings()
    }
    
    @objc private func appDidBecomeActive() {
        guard isProximityActivationWaiting else { return }
        isProximityActivationWaiting = false
        triggerProximityActivation()
    }
    #endif

    func areStringsAvailable() -> Bool {
        let strings: [String] = [appName, widgetWelcomeTitle, widgetWelcomeButtonTitle, widgetActivated, widgetDeactivated, widgetActivateProximityButtonTitle, widgetMoreInfo, widgetOpenTheApp, widgetSickSmallTitle, widgetSickFullTitle, widgetSmallTitle, widgetFullTitle]
        return strings.allSatisfy { !$0.isEmpty }
    }
    
}

#if !WIDGET
@available(iOS 14.0, *)
extension WidgetManager: LocalizationsChangesObserver {

    func localizationsChanged() {
        reloadStrings()
    }

    private func reloadStrings() {
        guard RBManager.shared.isInitialized else { return }
        widgetSmallTitle = RisksUIManager.shared.currentLevel?.labels.widgetShort.localizedOrEmpty ?? ""
        widgetFullTitle = RisksUIManager.shared.currentLevel?.labels.widgetLong.localizedOrEmpty ?? ""
        appName = "app.name".localizedOrEmpty
        widgetWelcomeTitle = "onboarding.welcomeController.title".localizedOrEmpty
        widgetWelcomeButtonTitle = "onboarding.welcomeController.howDoesItWork".localizedOrEmpty
        widgetActivated = "widget.title.activated".localizedOrEmpty
        widgetDeactivated = "widget.title.deactivated".localizedOrEmpty
        widgetActivateProximityButtonTitle = "proximityController.button.activateProximity".localizedOrEmpty
        widgetMoreInfo = "widget.info.moreInfo".localizedOrEmpty
        widgetOpenTheApp = "widget.openTheApp".localizedOrEmpty
        widgetSickSmallTitle = "widget.isSick.small.title".localizedOrEmpty
        widgetSickFullTitle = "home.healthSection.isSick.standaloneTitle".localizedOrEmpty
        widgetNoStatusInfo = "widget.noStatus.info".localizedOrEmpty
        let date: Date = lastStatusReceivedDate ?? Date()
        widgetFullTitleDate = date.relativelyFormattedForWidget()
        WidgetCenter.shared.reloadAllTimelines()
    }

}
#endif
