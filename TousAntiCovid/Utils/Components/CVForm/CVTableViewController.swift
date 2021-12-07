// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVTableViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

class CVTableViewController: UITableViewController {

    var sections: [CVSection] = []
    private var cellHeights: [IndexPath: CGFloat] = [:]
    private var sectionsHeights: [Int: CGFloat] = [:]

    override func loadView() {
        super.loadView()
        tableView = CVTableView(frame: .zero, style: .plain)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addHeaderView()
        addFooterView()
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        if #available(iOS 15.0, *) {
            UITableView.appearance().sectionHeaderTopPadding = 0
        }
    }
    
    func createSections() -> [CVSection] { [] }
    func makeSections(@CVSectionsBuilder _ content: () -> [CVSection]) -> [CVSection] { content() }

    func reloadUI(animated: Bool = false, animatedView: UIView? = nil, completion: (() -> ())? = nil) {
        sections = createSections()
        registerXibs()
        if #available(iOS 13.0, *) {
            if animated {
                UIView.transition(with: animatedView ?? tableView, duration: 0.2, options: [.transitionCrossDissolve], animations: {
                    self.tableView.reloadData()
                }) { _ in
                    completion?()
                }
            } else {
                tableView.reloadData()
                completion?()
            }
        } else {
            tableView.reloadData()
            completion?()
        }
    }
    
    private func rowObject(at indexPath: IndexPath) -> CVRow {
        sections[indexPath.section].rows[indexPath.row]
    }
    
    private func registerXibs() {
        var cellXibNames: Set<String> = Set<String>()
        var sectionXibNames: Set<String> = Set<String>()
        sections.forEach { section in
            if let header = section.header {
                sectionXibNames.insert(header.xibName.rawValue)
            }
            if let footer = section.footer {
                sectionXibNames.insert(footer.xibName.rawValue)
            }
            section.rows.forEach { cellXibNames.insert($0.xibName.rawValue) }
            cellXibNames.forEach{ tableView.register(UINib(nibName: $0, bundle: nil), forCellReuseIdentifier: $0) }
            sectionXibNames.forEach { tableView.register(UINib(nibName: $0, bundle: nil), forHeaderFooterViewReuseIdentifier: $0) }
        }

    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row: CVRow = rowObject(at: indexPath)
        let identifier: String = row.xibName.rawValue
        let cell: CVTableViewCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! CVTableViewCell
        cell.setup(with: row)
        cell.layoutSubviews()
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
        guard let cell = cell as? CVTableViewCell else { return }
        let row: CVRow = rowObject(at: indexPath)
        row.willDisplay?(cell)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row: CVRow = rowObject(at: indexPath)
        row.selectionAction?()
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        cellHeights[indexPath] ?? UITableView.automaticDimension
    }

    override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerSection = sections[section].header else { return nil }
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerSection.xibName.rawValue) as? CVHeaderFooterSectionView else { return nil }
        view.setup(with: headerSection)
        return view
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        sectionsHeights[section] = view.frame.size.height
        guard let headerSection = sections[section].header else { return }
        guard let view = view as? CVHeaderFooterSectionView else { return }
        headerSection.willDisplay?(view)
    }

    override open func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        sections[section].header == nil ? 0.0 : sectionsHeights[section] ?? 1
    }
    
    override open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerSection = sections[section].footer else { return nil }
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: footerSection.xibName.rawValue) as? CVHeaderFooterSectionView else { return nil }
        view.setup(with: footerSection)
        return view
    }

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        sectionsHeights[section] = view.frame.size.height
        guard let footerSection = sections[section].footer else { return }
        guard let view = view as? CVHeaderFooterSectionView else { return }
        footerSection.willDisplay?(view)
    }

    override open func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        sections[section].footer == nil ? 0.0 : sectionsHeights[section] ?? 1
    }

    override func accessibilityPerformEscape() -> Bool {
        if let navigationController = navigationController, navigationController.viewControllers.first !== self {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
        return true
    }
    
}

// MARK: - Header/Bottom View Management-
extension CVTableViewController {
    func addHeaderView(height: CGFloat = Appearance.TableView.Header.standardHeight) {
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: height))
    }

    func addFooterView(height: CGFloat = Appearance.TableView.Footer.standardHeight) {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: height))
    }
}
