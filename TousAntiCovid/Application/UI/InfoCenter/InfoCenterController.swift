// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  InfoCenterController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/09/2020 - for the TousAntiCovid project.
//

import UIKit

final class InfoCenterController: CVTableViewController {
    
    private let deinitBlock: () -> ()
    
    init(deinitBlock: @escaping () -> ()) {
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        updateTitle()
        reloadUI()
        addObservers()
        InfoCenterManager.shared.fetchInfo(force: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        makeNewInfoRead()
    }
    
    deinit {
        removeObservers()
        deinitBlock()
    }
    
    private func initUI() {
        addHeaderView(height: 10.0)
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.leftBarButtonItem?.accessibilityHint = "accessibility.closeModal.zGesture".localized
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    private func updateTitle() {
        title = "infoCenterController.title".localized
    }
    
    private func addObservers() {
        InfoCenterManager.shared.addObserver(self)
    }
    
    private func removeObservers() {
        InfoCenterManager.shared.removeObserver(self)
    }
    
    override func reloadUI(animated: Bool = false, animatedView: UIView? = nil, completion: (() -> ())? = nil) {
        updateEmptyView()
        super.reloadUI(animated: animated, completion: completion)
    }
    
    override func createSections() -> [CVSection] {
        updateEmptyView()
        return makeSections {
            if InfoCenterManager.shared.info.isEmpty {
                CVSection.Empty()
            } else {
                CVSection {
                    InfoCenterManager.shared.info.sorted { $0.timestamp > $1.timestamp }.map { info in
                        CVRow(title: info.title,
                              subtitle: info.description,
                              accessoryText: info.formattedDate,
                              buttonTitle: info.buttonLabel,
                              xibName: .infoCell,
                              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                 topInset: Appearance.Cell.Inset.small,
                                                 bottomInset: Appearance.Cell.Inset.small,
                                                 textAlignment: .natural,
                                                 titleFont: { Appearance.Cell.Text.headTitleFont },
                                                 titleHighlightFont: { Appearance.Cell.Text.subtitleBoldFont },
                                                 titleHighlightColor: Appearance.Cell.Text.subtitleColor,
                                                 subtitleFont: { Appearance.Cell.Text.subtitleFont },
                                                 subtitleColor: Appearance.Cell.Text.subtitleColor),
                              associatedValue: info,
                              selectionActionWithCell: { [weak self] cell in
                            self?.didTouchSharingFor(cell: cell, info: info)
                        },
                              secondarySelectionAction: {
                            info.url?.openInSafari()
                        })
                    }
                }
            }
        }
    }

    private func updateEmptyView() {
        tableView.backgroundView = InfoCenterManager.shared.info.isEmpty ? InfoCenterEmptyView.view() : nil
    }
    
    private func makeNewInfoRead() {
        InfoCenterManager.shared.didReceiveNewInfo = false
    }
    
    private func didTouchSharingFor(cell: CVTableViewCell, info: Info) {
        let sharingText: String = String(format: "info.sharing.title".localized, info.title)
        let activityItems: [Any?] = [sharingText]
        let controller: UIActivityViewController = UIActivityViewController(activityItems: activityItems.compactMap { $0 }, applicationActivities: nil)
        controller.excludedActivityTypes = [.saveToCameraRoll, .print]
        present(controller, animated: true, completion: nil)
    }

}

extension InfoCenterController: InfoCenterChangesObserver {

    func infoCenterDidUpdate() {
        reloadUI()
    }

}
