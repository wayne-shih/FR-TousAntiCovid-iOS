// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  EnterCodeController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK

final class EnterCodeController: CVTableViewController {
    
    weak var textField: UITextField?
    var code: String?
    
    private let didEnterCode: (_ code: String?) -> ()
    private let deinitBlock: () -> ()
    private var isFirstLoad: Bool = true
    
    init(initialCode: String?, didEnterCode: @escaping (_ code: String?) -> (), deinitBlock: @escaping () -> ()) {
        self.code = initialCode
        self.didEnterCode = didEnterCode
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use standard init() method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "declareController.button.tap".localized
        DeepLinkingManager.shared.enterCodeController = self
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstLoad {
            isFirstLoad = false
            if let code = code {
                textField?.text = code
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.didTouchValidate()
                }
            } else {
                textField?.becomeFirstResponder()
            }
        } else {
            textField?.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textField?.resignFirstResponder()
    }
    
    deinit {
        LocalizationsManager.shared.removeObserver(self)
        deinitBlock()
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                CVRow(title: "enterCodeController.title".localized,
                      xibName: .textCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge,
                                         bottomInset: Appearance.Cell.Inset.large,
                                         textAlignment: .center,
                                         titleFont: { Appearance.Controller.titleFont }))
                CVRow(title: "enterCodeController.mainMessage.title".localized,
                      subtitle: "enterCodeController.mainMessage.subtitle".localized,
                      xibName: .textCell,
                      theme: CVRow.Theme(topInset: .zero))
                CVRow(placeholder: "enterCodeController.textField.placeholder".localized,
                      xibName: .textFieldCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.large,
                                         placeholderColor: Appearance.Cell.Text.placeholderColor,
                                         separatorLeftInset: Appearance.Cell.leftMargin,
                                         separatorRightInset: Appearance.Cell.leftMargin),
                      textFieldKeyboardType: .default,
                      textFieldReturnKeyType: .done,
                      willDisplay: { [weak self] cell in
                    self?.textField = (cell as? TextFieldCell)?.cvTextField
                }, valueChanged: { [weak self] value in
                    guard let code = value as? String else { return }
                    self?.code = code
                }, didValidateValue: { [weak self] value, _ in
                    guard let code = value as? String else { return }
                    self?.code = code
                    self?.didTouchValidate()
                })
                CVRow(title: "enterCodeController.button.validate".localized,
                      xibName: .buttonCell,
                      theme: CVRow.Theme(topInset: Appearance.Cell.Inset.extraLarge),
                      selectionAction: { [weak self] _ in
                    self?.didTouchValidate()
                })
            }
        }
    }
    
    private func initUI() {
        tableView.showsVerticalScrollIndicator = false
        tableView.keyboardDismissMode = .onDrag
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "enterCodeController.button.validate".localized, style: .plain, target: self, action: #selector(didTouchValidate))
    }
    
    func enterCode(_ code: String) {
        navigationController?.popToViewController(self, animated: false)
        self.code = code
        textField?.text = code
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.didTouchValidate()
        }
    }
    
    @objc private func didTouchValidate() {
        if let code = code?.trimmingCharacters(in: .whitespaces), code.isShortCode || code.isUuidCode {
            tableView.endEditing(true)
            didEnterCode(code)
        } else {
            showAlert(title: "enterCodeController.alert.invalidCode.title".localized,
                      message: "enterCodeController.alert.invalidCode.message".localized,
                      okTitle: "common.ok".localized)
        }
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

}

extension EnterCodeController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        reloadUI()
    }
    
}

