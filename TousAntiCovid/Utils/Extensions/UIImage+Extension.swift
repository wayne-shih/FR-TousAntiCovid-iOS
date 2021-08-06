// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UIImage+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

extension UIImage {

    convenience init(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: (image?.cgImage!)!)
    }

    func getQRCodeValue() -> String? {
        guard let ciImage = CIImage(image: self) else { return nil }
        let detector: CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
        let features: [CIQRCodeFeature] = detector.features(in: ciImage) as? [CIQRCodeFeature] ?? []
        return features.compactMap { $0.messageString }.first
    }

    func cropImage(rect: CGRect) -> UIImage? {
        guard let croppedCGImage = cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: croppedCGImage)
    }

}
