// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  PositiveTestStepsController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 26/07/2021 - for the TousAntiCovid project.
//

import UIKit
import PKHUD

final class PositiveTestStepsController: CVTableViewController {

    private enum State {
        case addCertificate, declare
    }

    private let didTouchAddCertificate: (_ completion: @escaping (_ didSaveCertificate: Bool) -> ()) -> ()
    private let didTouchDeclare: (_ code: String?) -> ()

    private let comboUrl: URL
    private var currentState: State
    private var didSaveCertificate: Bool?

    init(comboUrl: URL, didTouchAddCertificate: @escaping (_ completion: @escaping (_ didSaveCertificate: Bool) -> ()) -> (), didTouchDeclare: @escaping (_ code: String?) -> ()) {
        self.currentState = .addCertificate
        self.comboUrl = comboUrl
        self.didTouchDeclare = didTouchDeclare
        self.didTouchAddCertificate = didTouchAddCertificate
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        (bottomButtonContainerController ?? self).title = "positiveTestStepsController.title".localized
        updateBottomButton()
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }

    deinit {
        LocalizationsManager.shared.removeObserver(self)
    }

    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                sectionRow(title: "positiveTestStepsController.sectionTitle".localized)
                selectableRow(title: "positiveTestStepsController.step.addCertificate.label".localized,
                              isDone: didSaveCertificate == true,
                              isCurrentStep: currentState == .addCertificate,
                              isLastRowInGroup: false)
                selectableRow(title: "positiveTestStepsController.step.declare.label".localized,
                              isDone: false,
                              isCurrentStep: currentState == .declare,
                              isLastRowInGroup: true)
                footerRow(title: "positiveTestStepsController.sectionFooter".localized)
            }
        }
    }

    private func initUI() {
        tableView.tintColor = Appearance.tintColor
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        let barButtonItem: UIBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        barButtonItem.accessibilityHint = "accessibility.closeModal.zGesture".localized
        (bottomButtonContainerController ?? self).navigationItem.leftBarButtonItem = barButtonItem

    }

    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    private func updateBottomButton() {
        let buttonTitle: String
        switch currentState {
        case .addCertificate:
            buttonTitle = "positiveTestStepsController.step.addCertificate.button".localized
        case .declare:
            buttonTitle  = "positiveTestStepsController.step.declare.button".localized
        }

        bottomButtonContainerController?.updateButton(title: buttonTitle) { [weak self] in
            self?.didTouchBottomButton()
        }
    }

    private func didTouchBottomButton() {
        let code: String? = DeepLinkingManager.shared.getComboCodeFrom(url: comboUrl)
        switch currentState {
        case .addCertificate:
            didTouchAddCertificate { [weak self] didSaveCertificate in
                self?.didSaveCertificate = didSaveCertificate
                self?.updateState()
            }
        case .declare:
            didTouchDeclare(code)
        }
        bottomButtonContainerController?.unlockButtons()
    }

    private func updateState() {
        if currentState == .addCertificate {
            currentState = .declare
            updateBottomButton()
            reloadUI()
        }
    }
}

// MARK: - Raw components rows -
extension PositiveTestStepsController {

    private func selectableRow(title: String, isDone: Bool, isCurrentStep: Bool, isLastRowInGroup: Bool) -> CVRow {
        CVRow(title: title,
              isOn: isDone,
              xibName: .selectableCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: Appearance.Cell.Inset.normal,
                                 bottomInset: Appearance.Cell.Inset.normal,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.standardFont },
                                 titleColor: isCurrentStep ? Appearance.Cell.Text.titleColor : Appearance.Cell.Text.disabledColor,
                                 separatorLeftInset: isLastRowInGroup ? .zero : Appearance.Cell.leftMargin,
                                 separatorRightInset: .zero))
    }


    private func sectionRow(title: String) -> CVRow {
        let row: CVRow = CVRow(title: title,
                               xibName: .textCell,
                               theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                                  bottomInset: Appearance.Cell.Inset.normal,
                                                  textAlignment: .natural,
                                                  titleColor: Appearance.tintColor,
                                                  separatorLeftInset: .zero,
                                                  separatorRightInset: .zero))
        return row
    }

    private func footerRow(title: String) -> CVRow {
        CVRow(title: title,
              xibName: .textCell,
              theme:  CVRow.Theme(topInset: Appearance.Cell.Inset.small,
                                  bottomInset: Appearance.Cell.Inset.small,
                                  textAlignment: .natural,
                                  titleFont: { Appearance.Cell.Text.footerFont },
                                  titleColor: Appearance.Cell.Text.captionTitleColor))
    }
}

extension PositiveTestStepsController: LocalizationsChangesObserver {

    func localizationsChanged() {
        reloadUI()
    }

}
