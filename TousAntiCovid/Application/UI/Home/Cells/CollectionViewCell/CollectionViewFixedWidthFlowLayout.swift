// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CollectionViewFixedWidthFlowLayout.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/12/2021 - for the TousAntiCovid project.
//

import UIKit

final class CollectionViewFixedWidthFlowLayout: UICollectionViewFlowLayout {
    
    var isDirty: Bool = false
    
    private var estimatedContentSize: CGSize = .zero
    private let heightThreshold: Double = 1.0
    private var shouldInvalidate: Bool = false
    private var fixedWidthCollectionView: FixedWidthCollectionView? { collectionView as? FixedWidthCollectionView }
    private var tempMaxHeight: CGFloat = .zero
    private var maxHeight: CGFloat {
        get { fixedWidthCollectionView?.maxHeight ?? .zero }
        set { fixedWidthCollectionView?.maxHeight = newValue }
    }
    private var cellWidth: CGFloat {
        get { fixedWidthCollectionView?.cellsWidth ?? .zero }
        set { fixedWidthCollectionView?.cellsWidth = newValue }
    }
    
    override init() {
        super.init()
        scrollDirection = .horizontal
        minimumInteritemSpacing = .zero
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var collectionViewContentSize: CGSize {
        var size = super.collectionViewContentSize
        if maxHeight > .zero {
            size.height = maxHeight
        }
        estimatedContentSize = size
        return size
    }
    
    func invalidate() {
        cellWidth = .zero
        maxHeight = .zero
        tempMaxHeight = .zero
        estimatedContentSize = .zero
    }
    
    override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        cellWidth = preferredAttributes.size.width
        if abs(preferredAttributes.size.height - tempMaxHeight) > heightThreshold {
            tempMaxHeight = preferredAttributes.size.height
        }
        if preferredAttributes.indexPath.isLastElement(in: collectionView) && maxHeight != tempMaxHeight {
            maxHeight = tempMaxHeight
            isDirty = true
            shouldInvalidate = true
        }
        return shouldInvalidate
    }
    
    override func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        let context: UICollectionViewLayoutInvalidationContext = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
        let contentHeightAdjustment: CGFloat = maxHeight - estimatedContentSize.height
        context.contentSizeAdjustment = .init(width: .zero, height: contentHeightAdjustment)
        shouldInvalidate = false
        return context
    }
    
    override func prepare() {
        guard cellWidth > .zero, maxHeight > .zero, isDirty else { return }
        super.prepare()
        itemSize = .init(width: cellWidth, height: maxHeight)
        estimatedItemSize = .zero
        isDirty = false
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let cellAttributesArray: [UICollectionViewLayoutAttributes]? = super.layoutAttributesForElements(in: rect)
        cellAttributesArray?.forEach {
            if $0.frame.minY != .zero, $0.representedElementCategory == .cell {
                // Collection view bug fix
                $0.frame = .init(x: $0.frame.minX, y: .zero, width: $0.frame.width, height: $0.frame.height)
            }
        }
        return cellAttributesArray
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return proposedContentOffset }
        
        let proposedRect: CGRect = determineProposedRect(collectionView: collectionView, proposedContentOffset: proposedContentOffset)
        
        guard let layoutAttributes = layoutAttributesForElements(in: proposedRect),
              let candidateAttributesForRect = attributesForRect(
                collectionView: collectionView,
                layoutAttributes: layoutAttributes,
                proposedContentOffset: proposedContentOffset
              ) else { return proposedContentOffset }
        
        var newOffset: CGFloat = candidateAttributesForRect.center.x - collectionView.bounds.size.width / 2
        let offset: CGFloat = newOffset - collectionView.contentOffset.x
        
        if (velocity.x < 0 && offset > 0) || (velocity.x > 0 && offset < 0) {
            let pageWidth: CGFloat = itemSize.width + minimumLineSpacing
            newOffset += velocity.x > 0 ? pageWidth : -pageWidth
        }
        
        return CGPoint(x: newOffset, y: proposedContentOffset.y)
    }

}

private extension CollectionViewFixedWidthFlowLayout {
    func determineProposedRect(collectionView: UICollectionView, proposedContentOffset: CGPoint) -> CGRect {
        let size: CGSize = collectionView.bounds.size
        let origin: CGPoint = .init(x: proposedContentOffset.x, y: collectionView.contentOffset.y)
        return CGRect(origin: origin, size: size)
    }
    
    func attributesForRect(
        collectionView: UICollectionView,
        layoutAttributes: [UICollectionViewLayoutAttributes],
        proposedContentOffset: CGPoint
    ) -> UICollectionViewLayoutAttributes? {
        
        var candidateAttributes: UICollectionViewLayoutAttributes?
        let proposedCenterOffset: CGFloat = proposedContentOffset.x + collectionView.bounds.size.width / 2
        
        for attributes in layoutAttributes {
            guard attributes.representedElementCategory == .cell else { continue }
            guard candidateAttributes != nil else {
                candidateAttributes = attributes
                continue
            }
            if abs(attributes.center.x - proposedCenterOffset) < abs(candidateAttributes!.center.x - proposedCenterOffset) {
                candidateAttributes = attributes
            }
        }
        return candidateAttributes
    }
}

private extension IndexPath {
    func isLastElement(in collectionView: UICollectionView?) -> Bool {
        guard let collectionView = collectionView else { return false }
        let lastSection: Int = collectionView.numberOfSections - 1
        let lastItem: Int = collectionView.numberOfItems(inSection: lastSection) - 1
        return self == IndexPath(item: lastItem, section: lastSection)
    }
}
