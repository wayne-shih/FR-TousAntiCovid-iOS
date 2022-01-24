// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVCollectionTableViewCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 10/12/2021 - for the TousAntiCovid project.
//

import UIKit

final class CVCollectionTableViewCell: CVTableViewCell {
    @IBOutlet weak var collectionView: FixedWidthCollectionView!
    
    private var collectionViewObserver: NSKeyValueObservation?
    private let adjustmentThreshold: CGFloat = 1.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCollectionView()
        addObserver()
    }
    
    deinit {
        collectionViewObserver?.invalidate()
        collectionViewObserver = nil
    }
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupTheme(row.theme)
        if let rows = row.associatedValue as? [CVRow] {
            collectionView.requiredCellsWidth = cellsWidth(for: rows.compactMap { $0.width }, required: row.theme.requiredWidth, maximum: row.theme.maxRequiredWidth)
            collectionView.makeRows { rows }
            collectionView.reloadData { [weak self] in
                guard let self = self else { return }
                self.currentAssociatedRow?.collectionViewDidReload?(self)
            }
        }
        accessoryType = .none
    }
    
    func resetContentOffset(animated: Bool) {
        collectionView.resetContentOffset(animated: animated)
    }
}

private extension CVCollectionTableViewCell {
    func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
    }
    
    func setupTheme(_ theme: CVRow.Theme) {
        collectionView.contentInset = UIEdgeInsets(top: .zero, left: theme.leftInset ?? Appearance.Cell.leftMargin, bottom: .zero, right: theme.rightInset ?? Appearance.Cell.rightMargin)
    }
    
    func addObserver() {
        collectionViewObserver = collectionView.observe(\.contentSize, options: [.new, .old]) { [weak self] collectionView, change in
            guard let self = self, let oldValue = change.oldValue?.height, let newValue = change.newValue?.height, abs(newValue - oldValue) >= self.adjustmentThreshold, collectionView.isReady else { return }
            self.currentAssociatedRow?.collectionViewDidReload?(self)
        }
    }
    
    func cellsWidth(for widths: [CGFloat], required: CGFloat, maximum: CGFloat?) -> CGFloat {
        let margins: CGFloat = (currentAssociatedRow?.theme.leftInset ?? Appearance.Cell.leftMargin) + (currentAssociatedRow?.theme.rightInset ?? Appearance.Cell.rightMargin)
        if let maximum = maximum {
            return maximum
        } else {
            if let maxWidth = widths.max() {
                return max(required, maxWidth + margins)
            } else {
                return required
            }
        }
    }
}
