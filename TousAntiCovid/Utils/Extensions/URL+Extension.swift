// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  URL+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/04/2020 - for the TousAntiCovid project.
//

import UIKit

extension URL {

    var size: Int64 {
        if isDirectory {
            let urls: [URL] = (try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [])) ?? []
            let size: Int64 = urls.reduce(0) { $0 + $1.size }
            return size
        } else {
            return Int64((try? resourceValues(forKeys: [.totalFileSizeKey]))?.totalFileSize ?? 0)
        }
    }

    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
    }

    var modificationDate: Date? { (try? FileManager.default.attributesOfItem(atPath: path))?[.modificationDate] as? Date }

    func openInSafari() {
        if UIApplication.shared.canOpenURL(self) {
            UIApplication.shared.open(self)
        }
    }
    
    func share(from controller: UIViewController, fromButton: UIButton? = nil) {
        let activityController: UIActivityViewController = UIActivityViewController(activityItems: [self], applicationActivities: nil)
        if let button = fromButton {
            activityController.popoverPresentationController?.setSourceButton(button)
        }
        controller.present(activityController, animated: true, completion: nil)
    }
    
    mutating func addSkipBackupAttribute() throws {
        var values: URLResourceValues = URLResourceValues()
        values.isExcludedFromBackup = true
        try setResourceValues(values)
    }
    
}

extension Array where Element == URL {

    func share(from controller: UIViewController, fromButton: UIButton? = nil) {
        let activityController: UIActivityViewController = UIActivityViewController(activityItems: self, applicationActivities: nil)
        if let button = fromButton {
            activityController.popoverPresentationController?.setSourceButton(button)
        }
        controller.present(activityController, animated: true, completion: nil)
    }

}
