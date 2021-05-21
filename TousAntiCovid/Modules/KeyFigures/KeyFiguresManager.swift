// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFiguresManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK

protocol KeyFiguresChangesObserver: class {
    
    func postalCodeDidUpdate(_ postalCode: String?)
    func keyFiguresDidUpdate()
    
}

final class KeyFiguresObserverWrapper: NSObject {
    
    weak var observer: KeyFiguresChangesObserver?
    
    init(observer: KeyFiguresChangesObserver) {
        self.observer = observer
    }
    
}

final class KeyFiguresManager: NSObject {
    
    static let shared: KeyFiguresManager = KeyFiguresManager()
    
    var keyFigures: [KeyFigure] = []
    var highlightedKeyFigure: KeyFigure? { keyFigures.filter { $0.isFeatured && ($0.isHighlighted == true) }.first }
    var featuredKeyFigures: [KeyFigure] { [KeyFigure](keyFigures.filter { $0.isFeatured && ($0.isHighlighted != true) }.prefix(3)) }
    
    var displayDepartmentLevel: Bool { ParametersManager.shared.displayDepartmentLevel }
    
    @UserDefault(key: .isOnboardingDone)
    private var isOnboardingDone: Bool = false

    @UserDefault(key: .currentPostalCode)
    var currentPostalCode: String? {
        didSet {
            currentDepartmentName = departmentNameForPostalCode(currentPostalCode)
            notifyPostalCodeUpdate(currentPostalCode)
        }
    }
    
    @UserDefault(key: .currentDepartmentName)
    var currentDepartmentName: String?
    
    var currentFormattedDepartmentNameAndPostalCode: String? {
        guard displayDepartmentLevel else { return nil }
        guard let departmentName = currentDepartmentName, let postalCode = currentPostalCode else { return nil }
        return "\(departmentName) - \(postalCode)".uppercased()
    }
    
    private var observers: [KeyFiguresObserverWrapper] = []
    
    func start() {
        loadLocalKeyFigures()
        addObserver()
    }
    
    func fetchKeyFigures() {
        fetchAllFiles()
    }
    
    func isDepartmentSupportedForPostalCode(_ postalCode: String) -> Bool {
        !keyFigures.compactMap { $0.departmentSpecificKeyFigureForPostalCode(postalCode) }.isEmpty
    }
    
    func departmentNameForPostalCode(_ postalCode: String?) -> String? {
        var departmentName: String?
        for keyFigure in keyFigures {
            if let departmentKeyFigure = keyFigure.departmentSpecificKeyFigureForPostalCode(postalCode) {
                departmentName = departmentKeyFigure.label
                break
            }
        }
        return departmentName
    }
    
    func updateLocation(from viewController: UIViewController) {
        if currentPostalCode == nil {
            defineNewPostalCode(from: viewController)
        } else {
            updatePostalCode(from: viewController)
        }
    }
    
    func generateChartData(from keyFigure: KeyFigure) -> [KeyFigureChartData] {
        var chartDatas: [KeyFigureChartData] = []
        if let series = keyFigure.ascendingSeries, !series.isEmpty {
            var color: UIColor = keyFigure.color
            if keyFigure.currentDepartmentSpecificKeyFigure?.ascendingSeries?.isEmpty == false && keyFigure.displayOnSameChart {
                color = keyFigure.color.add(overlay: UIColor.white.withAlphaComponent(0.6))
            }
            let legend: KeyFigureChartLegend = KeyFigureChartLegend(title: "common.country.france".localized,
                                                                    image: Asset.Images.chartLegend.image,
                                                                    color: color)
            let lastDate: Date = Date(timeIntervalSince1970: series.last!.date)
            let globalFigureToDisplay: String = keyFigure.valueGlobalToDisplay.formattingValueWithThousandsSeparatorIfPossible()
            chartDatas.append(KeyFigureChartData(legend: legend,
                                                 series: series,
                                                 currentValueToDisplay: keyFigure.valueGlobalToDisplay,
                                                 footer: String(format: "keyFigureDetailController.section.evolution.subtitle".localized, keyFigure.label, lastDate.dayMonthFormatted(), globalFigureToDisplay),
                                                 limitLineValue: keyFigure.limitLine,
                                                 limitLineLabel: keyFigure.limitLineLabel,
                                                 chartKind: keyFigure.displayOnSameChart ? .line : keyFigure.chartKind))
        }
        if let departmentKeyFigure = keyFigure.currentDepartmentSpecificKeyFigure, let departmentSeries = departmentKeyFigure.ascendingSeries, !departmentSeries.isEmpty {
            let departmentLegend: KeyFigureChartLegend = KeyFigureChartLegend(title: departmentKeyFigure.label,
                                                                              image: Asset.Images.chartLegend.image,
                                                                              color: keyFigure.color)
            let lastDate: Date = Date(timeIntervalSince1970: departmentSeries.last?.date ?? 0.0)
            let departmentKeyFigureToDisplay: String = departmentKeyFigure.valueToDisplay.formattingValueWithThousandsSeparatorIfPossible()
            let footer: String
            if chartDatas.isEmpty {
                footer = String(format: "keyFigureDetailController.section.evolution.subtitle".localized, keyFigure.label, departmentKeyFigureToDisplay, lastDate.dayShortMonthFormatted())
            } else {
                let globalFigureToDisplay: String = keyFigure.valueGlobalToDisplay.formattingValueWithThousandsSeparatorIfPossible()
                footer = String(format: "keyFigureDetailController.section.evolution.subtitle2Charts".localized, keyFigure.label, lastDate.dayMonthFormatted(), departmentKeyFigureToDisplay, globalFigureToDisplay)
            }
            chartDatas.insert(KeyFigureChartData(legend: departmentLegend,
                                                 series: departmentSeries,
                                                 currentValueToDisplay: departmentKeyFigure.valueToDisplay,
                                                 footer: footer,
                                                 limitLineValue: keyFigure.displayOnSameChart ? nil : keyFigure.limitLine,
                                                 limitLineLabel: keyFigure.displayOnSameChart ? nil : keyFigure.limitLineLabel,
                                                 chartKind: keyFigure.displayOnSameChart ? .line : keyFigure.chartKind),
                              at: 0)
        }
        if let averageSeries = keyFigure.avgSeries, !averageSeries.isEmpty {
            let color: UIColor = keyFigure.color
            let legend: KeyFigureChartLegend = KeyFigureChartLegend(title: String(format: "keyFigureDetailController.section.evolutionAvg.legendWithLocation".localized, "common.country.france".localized),
                                                                    image: Asset.Images.chartLegend.image,
                                                                    color: color)
            chartDatas.append(KeyFigureChartData(legend: legend,
                                                 series: averageSeries,
                                                 currentValueToDisplay: keyFigure.valueGlobalToDisplay,
                                                 footer: String(format: "keyFigureDetailController.section.evolutionAvg.subtitle".localized, keyFigure.label),
                                                 isAverage: true,
                                                 limitLineValue: keyFigure.limitLine,
                                                 limitLineLabel: keyFigure.limitLineLabel,
                                                 chartKind: .line))
        }
        return chartDatas
    }
    
    private func updatePostalCode(from viewController: UIViewController) {
        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "home.infoSection.updatePostalCode.alert.newPostalCode".localized, style: .default, handler: { [weak self] _ in
            self?.defineNewPostalCode(from: viewController)
        }))
        alertController.addAction(UIAlertAction(title: "home.infoSection.updatePostalCode.alert.deletePostalCode".localized, style: .destructive, handler: { _ in
            KeyFiguresManager.shared.currentPostalCode = nil
        }))
        alertController.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel))
        viewController.present(alertController, animated: true, completion: nil)
    }

    private func defineNewPostalCode(from viewController: UIViewController, defaultValue: String? = nil) {
        viewController.showTextFieldAlert("home.infoSection.newPostalCode.alert.title".localized, message: "home.infoSection.newPostalCode.alert.subtitle".localized, textFieldPlaceHolder: "home.infoSection.newPostalCode.alert.placeholder".localized, textFieldDefaultValue: defaultValue, keyboardType: UIKeyboardType.numberPad) { [weak self] textFieldValue in
            guard textFieldValue.isPostalCode else {
                viewController.showAlert(title: "home.infoSection.newPostalCode.alert.wrongPostalCode".localized, okTitle: "common.ok".localized, handler:  { [weak self] in
                    self?.defineNewPostalCode(from: viewController, defaultValue: textFieldValue)
                })
                return
            }
            guard KeyFiguresManager.shared.isDepartmentSupportedForPostalCode(textFieldValue) else {
                viewController.showAlert(title: "home.infoSection.newPostalCode.alert.unknownPostalCode".localized, okTitle: "common.ok".localized, handler:  { [weak self] in
                    self?.defineNewPostalCode(from: viewController, defaultValue: textFieldValue)
                })
                return

            }
            KeyFiguresManager.shared.currentPostalCode = textFieldValue
            viewController.showFlash()
        }
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        fetchAllFiles()
    }
    
}

// MARK: - All fetching methods -
extension KeyFiguresManager {
    
    private func fetchAllFiles() {
        fetchKeyFiguresFile {
            DispatchQueue.main.async {
                self.notifyKeyFiguresUpdate()
            }
        }
    }
    
    private func fetchKeyFiguresFile(_ completion: @escaping () -> ()) {
        let session: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let dataTask: URLSessionDataTask = session.dataTask(with: KeyFiguresConstant.jsonUrl) { data, response, error in
            guard let data = data else {
                completion()
                return
            }
            do {
                self.keyFigures = try JSONDecoder().decode([KeyFigure].self, from: data)
                try data.write(to: self.localKeyFiguresUrl())
                DispatchQueue.main.async {
                    completion()
                }
            } catch {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
        dataTask.resume()
    }
    
}

// MARK: - Local files management -
extension KeyFiguresManager {
    
    private func localKeyFiguresUrl() -> URL {
        let directoryUrl: URL = self.createWorkingDirectoryIfNeeded()
        return directoryUrl.appendingPathComponent("keyFigures.json")
    }
    
    private func loadLocalKeyFigures() {
        let localUrl: URL = localKeyFiguresUrl()
        guard FileManager.default.fileExists(atPath: localUrl.path) else { return }
        guard let data = try? Data(contentsOf: localUrl) else { return }
        keyFigures = (try? JSONDecoder().decode([KeyFigure].self, from: data)) ?? []
    }
    
    private func createWorkingDirectoryIfNeeded() -> URL {
        let directoryUrl: URL = FileManager.libraryDirectory().appendingPathComponent("KeyFigures")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }
    
}

extension KeyFiguresManager {
    
    func addObserver(_ observer: KeyFiguresChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(KeyFiguresObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: KeyFiguresChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: KeyFiguresChangesObserver) -> KeyFiguresObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
    private func notifyPostalCodeUpdate(_ postalCode: String?) {
        observers.forEach { $0.observer?.postalCodeDidUpdate(postalCode) }
    }
    
    private func notifyKeyFiguresUpdate() {
        observers.forEach { $0.observer?.keyFiguresDidUpdate() }
    }
    
}

extension KeyFiguresManager: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning.validateChallenge(challenge, certificateFile: Constant.Server.resourcesCertificate) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
     
}
