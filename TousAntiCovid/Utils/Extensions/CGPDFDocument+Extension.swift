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

    static func getQrCodesInPdf(at url: URL) -> [String] {
        let image: UIImage = CGPDFDocument.getPdfFirstPageImage(url: url)!
        let imageBottomHalf: UIImage? = image.cropImage(rect: CGRect(x: 0.0, y: image.size.height * UIScreen.main.nativeScale / 2.0, width: image.size.width * UIScreen.main.nativeScale, height: image.size.height * UIScreen.main.nativeScale / 2.0))
        return [imageBottomHalf?.getQRCodeValue(), image.getQRCodeValue()].compactMap { $0 }
    }

    static func getPdfFirstPageImage(url: URL) -> UIImage? {
        guard let document = CGPDFDocument(url as CFURL) else { return nil }
        guard let page = document.page(at: 1) else { return nil }

        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let img = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)

            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

            ctx.cgContext.drawPDFPage(page)
        }

        return img
    }

}
