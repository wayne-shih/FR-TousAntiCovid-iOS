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
import PKHUD
import ServerSDK
import SwiftProtobuf
import Gzip

protocol KeyFiguresChangesObserver: AnyObject {
    
    func postalCodeDidUpdate(_ postalCode: String?)
    func keyFiguresDidUpdate()
    
}

final class KeyFiguresObserverWrapper: NSObject {
    
    weak var observer: KeyFiguresChangesObserver?
    
    init(observer: KeyFiguresChangesObserver) {
        self.observer = observer
    }
    
}

final class KeyFiguresManager {
    
    static let shared: KeyFiguresManager = KeyFiguresManager()
    
    var keyFigures: [KeyFigure] = []
    var highlightedKeyFigure: KeyFigure? { keyFigures.filter { $0.isFeatured && ($0.isHighlighted == true) }.first }
    var featuredKeyFigures: [KeyFigure] { [KeyFigure](keyFigures.filter { $0.isFeatured && ($0.isHighlighted != true) }.prefix(3)) }
    
    var displayDepartmentLevel: Bool { ParametersManager.shared.displayDepartmentLevel }
    var canShowCurrentlyNeededFile: Bool { localFileExists() }

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

    @UserDefault(key: .isOnboardingDone)
    private var isOnboardingDone: Bool = false
    
    private var observers: [KeyFiguresObserverWrapper] = []
    private var canNotifyPostalCodeUpdates: Bool = true
    
    func start() {
        loadLocalKeyFigures()
        addObserver()
    }
    
    func fetchKeyFigures(_ completion: (() -> ())? = nil) {
        fetchAllFiles(completion)
    }
    
    func departmentNameForPostalCode(_ postalCode: String?) -> String? {
        var departmentName: String?
        for keyFigure in keyFigures {
            if let departmentKeyFigure = keyFigure.valuesDepartments?.first {
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
    
    func generateChartData(from keyFigure: KeyFigure, daysCount: Int) -> [KeyFigureChartData] {
        var chartDatas: [KeyFigureChartData] = []
        if let series = keyFigure.ascendingSeries, !series.isEmpty {
            var color: UIColor = keyFigure.color
            if keyFigure.currentDepartmentSpecificKeyFigure?.ascendingSeries?.isEmpty == false && keyFigure.displayOnSameChart && canShowCurrentlyNeededFile {
                color = keyFigure.color.add(overlay: UIColor.white.withAlphaComponent(0.6))
            }
            let legend: KeyFigureChartLegend = KeyFigureChartLegend(title: "common.country.france".localized,
                                                                    image: Asset.Images.chartLegend.image,
                                                                    color: color)
            let lastDate: Date = Date(timeIntervalSince1970: series.last!.date)
            let globalFigureToDisplay: String = keyFigure.valueGlobalToDisplay.formattingValueWithThousandsSeparatorIfPossible()
            chartDatas.append(KeyFigureChartData(legend: legend,
                                                 series: series.suffix(daysCount),
                                                 currentValueToDisplay: keyFigure.valueGlobalToDisplay,
                                                 footer: String(format: "keyFigureDetailController.section.evolution.subtitle".localized, keyFigure.label, lastDate.dayMonthFormatted(), globalFigureToDisplay),
                                                 limitLineValue: keyFigure.limitLine,
                                                 limitLineLabel: keyFigure.limitLineLabel,
                                                 chartKind: keyFigure.displayOnSameChart ? .line : keyFigure.chartKind))
        }
        if let departmentKeyFigure = keyFigure.currentDepartmentSpecificKeyFigure, let departmentSeries = departmentKeyFigure.ascendingSeries, !departmentSeries.isEmpty, canShowCurrentlyNeededFile {
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
                                                 series: departmentSeries.suffix(daysCount),
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
                                                 series: averageSeries.sorted { $0.date < $1.date }.suffix(daysCount),
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
        alertController.addAction(UIAlertAction(title: "home.infoSection.updatePostalCode.alert.deletePostalCode".localized, style: .destructive, handler: { [weak self] _ in
            self?.deletePostalCode()
        }))
        alertController.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel))
        viewController.present(alertController, animated: true, completion: nil)
    }

    func defineNewPostalCode(from viewController: UIViewController, defaultValue: String? = nil) {
        viewController.showTextFieldAlert("home.infoSection.newPostalCode.alert.title".localized, message: "home.infoSection.newPostalCode.alert.subtitle".localized, textFieldPlaceHolder: "home.infoSection.newPostalCode.alert.placeholder".localized, textFieldDefaultValue: defaultValue, keyboardType: UIKeyboardType.numberPad) { [weak self] textFieldValue in
            guard textFieldValue.isPostalCode else {
                viewController.showAlert(title: "home.infoSection.newPostalCode.alert.wrongPostalCode".localized, okTitle: "common.ok".localized, handler:  { [weak self] in
                    self?.defineNewPostalCode(from: viewController, defaultValue: textFieldValue)
                })
                return
            }
            self?.currentPostalCode = textFieldValue
            HUD.show(.progress)
            self?.fetchKeyFiguresFile {
                self?.loadLocalKeyFigures()
                self?.notifyKeyFiguresUpdate()
                HUD.hide()
            }
        }
    }

    func deletePostalCode() {
        currentPostalCode = nil
        HUD.show(.progress)
        fetchKeyFiguresFile { [weak self] in
            self?.loadLocalKeyFigures()
            self?.notifyKeyFiguresUpdate()
            HUD.hide()
        }
    }

    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func appDidBecomeActive() {
        fetchAllFiles()
    }

    private func departmentCode(for postalCode: String) -> String {
        var departmentCode: String = "\(postalCode.prefix(2))"
        if departmentCode == "20" {
            departmentCode = ["200", "201"].contains(postalCode.prefix(3)) ? "2A" : "2B"
        } else if ["97", "98"].contains(postalCode.prefix(2)) {
            departmentCode = "\(postalCode.prefix(3))"
        }
        return departmentCode
    }

}

// MARK: - All fetching methods -
extension KeyFiguresManager {

    private func fetchAllFiles(_ completion: (() -> ())? = nil) {
        fetchKeyFiguresFile {
            self.notifyKeyFiguresUpdate()
            completion?()
        }
    }

    private func fetchKeyFiguresFile(_ completion: @escaping () -> ()) {
        let dataTask: URLSessionDataTask = UrlSessionManager.shared.session.dataTaskWithETag(with: remoteFileUrl()) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async { completion() }
                return
            }
            do {
                let uncompressedData: Data = try data.gunzipped()
                let keyNumbers: KeyNumbers = try KeyNumbers(serializedData: uncompressedData)
                self.keyFigures = keyNumbers.toAppModel()
                try uncompressedData.write(to: self.localKeyFiguresUrl())
                DispatchQueue.main.async { completion() }
            } catch {
                DispatchQueue.main.async { completion() }
            }
        }
        dataTask.resume()
    }

    private func remoteFileUrl() -> URL {
        let defaultUrl: URL = KeyFiguresConstant.baseUrl.appendingPathComponent("key-figures-nat.pb.gz")
        guard let postalCode = currentPostalCode else { return defaultUrl }
        let departmentCode: String = departmentCode(for: postalCode)
        return KeyFiguresConstant.baseUrl.appendingPathComponent(departmentCode).appendingPathComponent("key-figures-\(departmentCode).pb.gz")
    }

}

// MARK: - Local files management -
extension KeyFiguresManager {
    
    private func localKeyFiguresUrl() -> URL {
        let directoryUrl: URL = self.createWorkingDirectoryIfNeeded()
        return directoryUrl.appendingPathComponent(remoteFileUrl().lastPathComponent.replacingOccurrences(of: ".gz", with: ""))
    }

    private func localFileExists() -> Bool {
        FileManager.default.fileExists(atPath: localKeyFiguresUrl().path)
    }
    
    private func loadLocalKeyFigures() {
        let localUrl: URL?
        if FileManager.default.fileExists(atPath: localKeyFiguresUrl().path) {
            localUrl = localKeyFiguresUrl()
        } else {
            localUrl = (try? FileManager.default.contentsOfDirectory(at: createWorkingDirectoryIfNeeded(), includingPropertiesForKeys: nil, options: []))?.sorted { $0.modificationDate ?? .distantPast > $1.modificationDate ?? .distantPast }.first
        }
        guard let url = localUrl else { return }
        guard let data = try? Data(contentsOf: url) else { return }
        guard let keyNumbers = try? KeyNumbers(serializedData: data) else { return }
        self.keyFigures = keyNumbers.toAppModel()
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
        guard canNotifyPostalCodeUpdates else { return }
        observers.forEach { $0.observer?.postalCodeDidUpdate(postalCode) }
    }
    
    private func notifyKeyFiguresUpdate() {
        observers.forEach { $0.observer?.keyFiguresDidUpdate() }
    }
    
}
