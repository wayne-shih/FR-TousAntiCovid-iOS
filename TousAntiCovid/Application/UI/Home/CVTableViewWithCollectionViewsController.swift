// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVTableViewWithCollectionViewsController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 05/01/2022 - for the TousAntiCovid project.
//

import UIKit

struct CVCellIdentifier: Hashable {
    var xibName: String
    var contentDesc: String
    
    var identifier: String { xibName + "|" + contentDesc }
}

class CVTableViewWithCollectionViewsController: CVTableViewController {
    
    override func registerXibs() {
        var cellXibNames: Set<CVCellIdentifier> = Set<CVCellIdentifier>()
        var sectionXibNames: Set<String> = Set<String>()
        sections.forEach { section in
            if let header = section.header {
                sectionXibNames.insert(header.xibName.rawValue)
            }
            if let footer = section.footer {
                sectionXibNames.insert(footer.xibName.rawValue)
            }
            section.rows.forEach { cellXibNames.insert(CVCellIdentifier(xibName: $0.xibName.rawValue, contentDesc: $0.contentDesc)) }
            cellXibNames.forEach{ tableView.register(UINib(nibName: $0.xibName, bundle: nil), forCellReuseIdentifier: $0.identifier ) }
            sectionXibNames.forEach { tableView.register(UINib(nibName: $0, bundle: nil), forHeaderFooterViewReuseIdentifier: $0) }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row: CVRow = rowObject(at: indexPath)
        let identifier: String = CVCellIdentifier(xibName: row.xibName.rawValue, contentDesc: row.contentDesc).identifier
        let cell: CVTableViewCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! CVTableViewCell
        cell.setup(with: row)
        cell.layoutSubviews()
        return cell
    }
}
