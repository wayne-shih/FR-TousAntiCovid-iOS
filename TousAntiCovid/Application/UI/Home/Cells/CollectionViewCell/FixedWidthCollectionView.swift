// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  FixedWidthCollectionView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 22/12/2021 - for the TousAntiCovid project.
//

import UIKit

final class FixedWidthCollectionView: UICollectionView {
    
    var layout: CollectionViewFixedWidthFlowLayout { collectionViewLayout as! CollectionViewFixedWidthFlowLayout }
    var isReady: Bool { !layout.isDirty }
    
    var maxHeight: CGFloat = .zero
    var cellsWidth: CGFloat = .zero
    
    var requiredCellsWidth: CGFloat = 300.0 {
        didSet {
            layout.estimatedItemSize = .init(width: requiredCellsWidth, height: 0.0)
        }
    }
    
    private var first: Bool = true
    private var initialContentOffset: CGPoint?
    private var rows: [CVRow] = [] {
        didSet {
            registerXibs()
        }
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        initialSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialSetup()
    }
    
    override var intrinsicContentSize: CGSize {
        return layout.collectionViewContentSize
    }
    
    override func invalidateIntrinsicContentSize() {
        guard frame.size != layout.collectionViewContentSize else { return }
        super.invalidateIntrinsicContentSize()
    }
    
    override func reloadData() {
        layout.invalidate()
        super.reloadData()
    }
    
    func reloadData(completion: @escaping () -> ()) {
        reloadData()
        DispatchQueue.main.async { [weak self] in
            self?.invalidateIntrinsicContentSize()
            completion()
        }
    }
    
    func makeRows(@CVRowsBuilder _ content: () -> [CVRow]) { rows = content() }
    
    func resetContentOffset(animated: Bool) {
        layoutIfNeeded()
        DispatchQueue.main.async { [weak self] in
            guard let offset = self?.initialContentOffset else { return }
            self?.setContentOffset(offset, animated: animated)
        }
    }
}

// MARK: - Utils
private extension FixedWidthCollectionView {
    func initialSetup() {
        delegate = self
        dataSource = self
        collectionViewLayout = CollectionViewFixedWidthFlowLayout()
        decelerationRate = UIScrollView.DecelerationRate.fast
    }
    
    func rowObject(at indexPath: IndexPath) -> CVRow {
        rows[indexPath.row]
    }
    
    func registerXibs() {
        let cellXibNames: Set<String> = Set<String>(rows.compactMap { $0.xibName.rawValue })
        cellXibNames.forEach{ register(UINib(nibName: $0, bundle: nil), forCellWithReuseIdentifier: $0) }
    }
}

// MARK: - UICollectionViewDataSource
extension FixedWidthCollectionView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        rows.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let row: CVRow = rowObject(at: indexPath)
        let identifier: String = row.xibName.rawValue
        let cell: CVCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CVCollectionViewCell
        cell.setup(with: row)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FixedWidthCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let row: CVRow = rowObject(at: indexPath)
        row.selectionAction?(nil)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if initialContentOffset == nil { initialContentOffset = contentOffset }
    }
}
