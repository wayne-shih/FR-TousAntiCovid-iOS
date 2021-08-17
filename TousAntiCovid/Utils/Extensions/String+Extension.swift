// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  String+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 16/04/2020 - for the TousAntiCovid project.
//

import UIKit
import CommonCrypto
#if !PROXIMITY
import ZXingObjC
#endif

extension String {
    
    var isSingleEmoji: Bool { count == 1 && containsEmoji }
    var containsEmoji: Bool { contains { $0.isEmoji } }
    var containsOnlyEmoji: Bool { !isEmpty && !contains { !$0.isEmoji } }
    var emojiString: String { emojis.map { String($0) }.reduce("", +) }
    var emojis: [Character] { filter { $0.isEmoji } }
    var emojiScalars: [UnicodeScalar] { filter{ $0.isEmoji }.flatMap { $0.unicodeScalars } }
    
    var camelCased: String {
        if contains("_") {
            let allComponents: [String] = components(separatedBy: "_")
            var words: [String] = [(allComponents.first ?? "").lowercased()]
            words.append(contentsOf: allComponents[1..<allComponents.count].map { $0.lowercased().capitalized })
            return words.joined()
        } else {
            return self
        }
    }
    
    var isUuidCode: Bool { self ~> "^[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}$" }
    var isShortCode: Bool { self ~> "^[A-Za-z0-9]{6}$" }
    var isPostalCode: Bool { self ~> "^[0-9]{5}$" }

    static func ~> (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let range: NSRange = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
    }

    subscript(_ range: ClosedRange<Int>) -> String {
        let startIndex: Index = index(self.startIndex, offsetBy: range.lowerBound)
        return String(self[startIndex..<index(startIndex, offsetBy: range.count)])
    }
    
    subscript(_ range: Range<Int>) -> String {
        let startIndex: Index = index(self.startIndex, offsetBy: range.lowerBound)
        return String(self[startIndex..<index(startIndex, offsetBy: range.count)])
    }
    
    subscript(safe range: ClosedRange<Int>) -> String? {
        guard count > range.upperBound else { return nil }
        let startIndex: Index = index(self.startIndex, offsetBy: range.lowerBound)
        return String(self[startIndex..<index(startIndex, offsetBy: range.count)])
    }
    
    subscript(safe range: Range<Int>) -> String? {
        guard count > range.upperBound else { return nil }
        let startIndex: Index = index(self.startIndex, offsetBy: range.lowerBound)
        return String(self[startIndex..<index(startIndex, offsetBy: range.count)])
    }
    
    func removingEmojis() -> String {
        components(separatedBy: .symbols).filter { !$0.isEmpty }.joined().trimmingCharacters(in: .whitespaces)
    }

    func flag() -> String {
        let base: UInt32 = 127397
        var flagEmoji: String = ""
        unicodeScalars.forEach { flagEmoji.unicodeScalars.append(UnicodeScalar(base + $0.value)!) }
        return flagEmoji
    }
    
    func callPhoneNumber(from controller: UIViewController) {
        guard let url = URL(string: "tel://\(self)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            let controller: UIAlertController = UIAlertController(title: "common.error.callImpossible".localized, message: nil, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
            controller.view.tintColor = Asset.Colors.tint.color
            controller.present(controller, animated: true, completion: nil)
        }
    }
    
    func cleaningForCSV(_ commaReplacement: String = ".") -> String {
        replacingOccurrences(of: ",", with: commaReplacement)
    }
    
    func cleaningEscapedCharacters() -> String {
        return replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\r", with: "\r").replacingOccurrences(of: "\\\"", with: "\"")
    }
    
    func share(from controller: UIViewController, fromButton: UIButton? = nil) {
        let activityController: UIActivityViewController = UIActivityViewController(activityItems: [self], applicationActivities: nil)
        if let button = fromButton {
            activityController.popoverPresentationController?.setSourceButton(button)
        }
        controller.present(activityController, animated: true, completion: nil)
    }
    
    func cleaningForServerFileName() -> String {
        clearingDiacritics().clearingSpecialCharacters()
    }
    
    func clearingDiacritics() -> String {
        folding(options: .diacriticInsensitive, locale: nil)
    }
    
    func clearingSpecialCharacters() -> String {
        let pattern: String = "[^A-Za-z0-9]+"
        return replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
    }
    
    func formattingValueWithThousandsSeparatorIfPossible() -> String {
        if let numberValue = Int(self) {
            return numberValue.formattedWithThousandsSeparator()
        } else {
            return self
        }
    }
    
    func accessibilityNumberFormattedString() -> String {
        guard let intValue = Int(self.replacingOccurrences(of: "common.thousandsSeparator".localized, with: "")) else { return self }
        let numberValue: NSNumber = NSNumber(integerLiteral: intValue)
        return NumberFormatter.localizedString(from: numberValue, number: .spellOut)
    }
    
    func qrCode(small: Bool = false) -> UIImage? {
        guard let data = data(using: .utf8) else { return nil }
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let factor: CGFloat = small ? 2.0 : 5.0
            let transform: CGAffineTransform = CGAffineTransform(scaleX: factor, y: factor)
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    #if !PROXIMITY
    func dataMatrix() -> UIImage? {
        let writer: ZXMultiFormatWriter = ZXMultiFormatWriter()
        do {
            let result: ZXBitMatrix = try writer.encode(self, format: kBarcodeFormatDataMatrix, width: 500, height: 500)
            guard let cgImage = ZXImage(matrix: result)?.cgimage else { return nil }
            return UIImage(cgImage: cgImage)
        } catch {
            print(error)
            return nil
        }
    }
    #endif
    
    func sha256() -> String {
        if let stringData = self.data(using: String.Encoding.utf8) {
            return stringData.sha256()
        }
        return ""
    }
    
    func cleaningPEMStrings() -> String {
        replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "-----BEGIN EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
            .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
    }

    func base64urlToBase64() -> String {
        var base64: String = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        return base64
    }
    
    func trimLowercased() -> String {
        trimmingCharacters(in: .whitespaces).lowercased()
    }
    
}
