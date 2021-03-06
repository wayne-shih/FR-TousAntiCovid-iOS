// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UIViewController+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD

extension UIViewController {
    
    var topPresentedController: UIViewController {
        var presentedController: UIViewController = self
        while let controller = presentedController.presentedViewController {
            presentedController = controller
        }
        return presentedController
    }
    
    func addChildViewController(_ childController: UIViewController, containerView: UIView) {
        addChild(childController)
        let childView: UIView = childController.view
        containerView.addConstrainedSubview(childView)
        childController.didMove(toParent: self)
    }
    
    func showAlert(title: String? = nil, message: String? = nil, okTitle: String, isOkDestructive: Bool = false, cancelTitle: String? = nil, handler: (() -> ())? = nil, cancelHandler: (() -> ())? = nil) {
        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: okTitle, style: isOkDestructive ? .destructive : .default, handler: { _ in handler?() }))
        if let cancelTitle = cancelTitle {
            alertController.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: { _ in cancelHandler?() }))
        }
        topPresentedController.present(alertController, animated: true, completion: nil)
    }
    
    func showActionSheet(title: String? = nil, message: String? = nil, firstActionTitle: String, secondActionTitle: String? = nil, showCancel: Bool = false, firstActionHandler: (() -> ())? = nil, secondActionHandler: (() -> ())? = nil) {
        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: firstActionTitle, style: .default, handler: { _ in firstActionHandler?() }))
        if let secondActionTitle = secondActionTitle {
            alertController.addAction(UIAlertAction(title: secondActionTitle, style: .default, handler: { _ in secondActionHandler?() }))
        }
        if showCancel {
            alertController.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel, handler: { _ in alertController.dismiss(animated: true) }))
        }
        topPresentedController.present(alertController, animated: true, completion: nil)
    }
    
    func showActionSheet(title: String? = nil, message: String? = nil, actions: [UIAlertAction], showCancel: Bool = false) {
        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for action in actions { alertController.addAction(action) }
        if showCancel {
            alertController.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel, handler: { _ in alertController.dismiss(animated: true) }))
        }
        topPresentedController.present(alertController, animated: true, completion: nil)
    }
    
    func showLeftAlignedAlert(title: String? = nil, message: String? = nil, okTitle: String, isOkDestructive: Bool = false, cancelTitle: String? = nil, handler: (() -> ())? = nil) {
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attributedMessageText: NSMutableAttributedString = NSMutableAttributedString(string: message ?? "",
                                                                                         attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle,
                                                                                                      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0)]
        )
        let alertController: UIAlertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertController.setValue(attributedMessageText, forKey: "attributedMessage")
        alertController.addAction(UIAlertAction(title: okTitle, style: isOkDestructive ? .destructive : .default, handler: { _ in handler?() }))
        if let cancelTitle = cancelTitle {
            alertController.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        }
        topPresentedController.present(alertController, animated: true, completion: nil)
    }
    
    func showRetryAlert(title: String? = nil, message: String? = nil, retryTitle: String, retryHandler: @escaping () -> (), cancelTitle: String, isCancelDestructive: Bool = false, cancelHandler: @escaping () -> ()) {
        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: retryTitle, style: .default, handler: { _ in retryHandler() }))
        alertController.addAction(UIAlertAction(title: cancelTitle, style: isCancelDestructive ? .destructive : .default, handler: { _ in cancelHandler() }))
        topPresentedController.present(alertController, animated: true, completion: nil)
    }
    
    func showLinkAlert(title: String? = nil, message: String? = nil, okTitle: String, okHandler: @escaping () -> (), linkTitle: String, linkHandler: @escaping () -> (), cancelTitle: String, isCancelDestructive: Bool = false, cancelHandler: @escaping () -> ()) {
        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: okTitle, style: .default, handler: { _ in okHandler() }))
        alertController.addAction(UIAlertAction(title: linkTitle, style: .default, handler: { _ in linkHandler() }))
        alertController.addAction(UIAlertAction(title: cancelTitle, style: isCancelDestructive ? .destructive : .default, handler: { _ in cancelHandler() }))
        topPresentedController.present(alertController, animated: true, completion: nil)
    }
    
    func showFlash(success: Bool = true) {
        HUD.flash(success ? .success : .error, onView: self.view.window, delay: 0.8)
    }
    
    func showTextFieldAlert(_ title: String? = nil, message: String? = nil, textFieldPlaceHolder: String? = nil, textFieldDefaultValue: String? = nil, keyboardType: UIKeyboardType = UIKeyboardType.default, isSecure: Bool = false, cancelHandler: (() -> Void)? = nil, completion: @escaping (_ newValue: String) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.text = textFieldDefaultValue
            textField.placeholder = textFieldPlaceHolder
            textField.keyboardType = keyboardType
            textField.isSecureTextEntry = isSecure
        })
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default, handler: { _ in
            let textField = alert.textFields![0] as UITextField
            completion(textField.text ?? textFieldDefaultValue ?? "")
        }))
        alert.addAction(UIAlertAction(title: "common.cancel".localized, style: UIAlertAction.Style.cancel, handler: { _ in
            cancelHandler?()
        }))
        topPresentedController.present(alert, animated: true, completion: nil)
    }

}
