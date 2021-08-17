// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CGPDFDocument+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 28/07/2021 - for the TousAntiCovid project.
//

import UIKit

extension CGPDFDocument {

    static func getQrCodesInPdf(at url: URL, controller: UIViewController?, completion: @escaping (_ codes: [String]?) -> ()) {
        getPdfFirstPageImage(url: url, controller: controller) { image in
            guard let image = image else {
                completion(nil)
                return
            }
            let imageBottomHalf: UIImage? = image.cropImage(rect: CGRect(x: 0.0, y: image.size.height * UIScreen.main.nativeScale / 2.0, width: image.size.width * UIScreen.main.nativeScale, height: image.size.height * UIScreen.main.nativeScale / 2.0))
            completion([imageBottomHalf?.getQRCodeValue(), image.getQRCodeValue()].compactMap { $0 })
        }
    }

    static func getPdfFirstPageImage(url: URL, controller: UIViewController?, completion: @escaping (_ image: UIImage?) -> ()) {
        guard let document = CGPDFDocument(url as CFURL) else {
            completion(nil)
            return
        }
        if document.isEncrypted {
            requestDocumentPassword(document: document, controller: controller) { isUnlocked in
                if isUnlocked {
                    completion(extractFirstPageImage(document: document))
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(extractFirstPageImage(document: document))
        }
    }

    private static func requestDocumentPassword(document: CGPDFDocument, controller: UIViewController?, completion: @escaping (_ unlocked: Bool) -> ()) {
        guard let controller = controller else {
            completion(false)
            return
        }
        controller.showTextFieldAlert("pdfImport.protected.enterPassword.alert.title".localized,
                                      message: "pdfImport.protected.enterPassword.alert.message".localized,
                                      textFieldPlaceHolder: "pdfImport.protected.enterPassword.alert.placeholder".localized,
                                      isSecure: true,
                                      cancelHandler: {
            completion(false)
        }) { [weak controller] password in
            if document.unlockWithPassword(password) {
                completion(true)
            } else {
                guard let controller = controller else {
                    completion(false)
                    return
                }
                controller.showAlert(title: "pdfImport.protected.wrongPassword.alert.title".localized,
                                     message: "pdfImport.protected.wrongPassword.alert.message".localized,
                                     okTitle: "common.yes".localized,
                                     isOkDestructive: false,
                                     cancelTitle: "common.no".localized) { [weak controller] in
                    self.requestDocumentPassword(document: document, controller: controller, completion: completion)
                } cancelHandler: {
                    completion(false)
                }
            }
        }
    }

    private static func extractFirstPageImage(document: CGPDFDocument) -> UIImage? {
        guard let page = document.page(at: 1) else { return nil }
        let pageRect: CGRect = page.getBoxRect(.mediaBox)
        let renderer: UIGraphicsImageRenderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)

            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

            ctx.cgContext.drawPDFPage(page)
        }
        return image
    }

}
