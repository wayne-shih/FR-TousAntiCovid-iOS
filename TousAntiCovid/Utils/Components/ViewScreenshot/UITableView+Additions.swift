import Foundation
import UIKit

extension UITableView {

    public override var screenshot: UIImage? {
        return self.screenshotExcludingHeadersAtSections(excludedHeaderSections: nil, excludingFootersAtSections: nil, excludingRowsAtIndexPaths: nil)
    }

    func screenshotOfCellAtIndexPath(indexPath: IndexPath) -> UIImage? {
        let currTableViewOffset: CGPoint = contentOffset
        scrollToRow(at: indexPath as IndexPath, at: .top, animated: false)
        let cellScreenshot: UIImage? = cellForRow(at: indexPath)?.screenshot
        setContentOffset(currTableViewOffset, animated: false)
        return cellScreenshot
    }

    var screenshotOfHeaderView: UIImage? {
        let originalOffset: CGPoint = contentOffset
        guard let headerRect = tableHeaderView?.frame else { return nil }
        self.scrollRectToVisible(headerRect, animated: false)
        let headerScreenshot: UIImage? = screenshotForCroppingRect(croppingRect: headerRect)
        setContentOffset(originalOffset, animated: false)
        return headerScreenshot
    }

    var screenshotOfFooterView: UIImage? {
        let originalOffset: CGPoint = contentOffset
        guard let footerRect = tableFooterView?.frame else { return nil }
        scrollRectToVisible(footerRect, animated: false)
        let footerScreenshot: UIImage? = screenshotForCroppingRect(croppingRect: footerRect)
        setContentOffset(originalOffset, animated: false)
        return footerScreenshot
    }

    func screenshotOfHeaderViewAtSection(section: Int) -> UIImage? {
        let originalOffset: CGPoint = contentOffset
        let headerRect: CGRect = rectForHeader(inSection: section)
        scrollRectToVisible(headerRect, animated: false)
        let headerScreenshot: UIImage? = screenshotForCroppingRect(croppingRect: headerRect)
        setContentOffset(originalOffset, animated: false)
        return headerScreenshot
    }

    func screenshotOfFooterViewAtSection(section: Int) -> UIImage? {
        let originalOffset: CGPoint = contentOffset
        let footerRect: CGRect = rectForFooter(inSection: section)
        scrollRectToVisible(footerRect, animated: false)
        let footerScreenshot: UIImage? = screenshotForCroppingRect(croppingRect: footerRect)
        setContentOffset(originalOffset, animated: false)
        return footerScreenshot
    }

    func screenshotExcludingAllHeaders(withoutHeaders: Bool, excludingAllFooters: Bool, excludingAllRows: Bool) -> UIImage? {
        var excludedHeadersOrFootersSections: [Int]?
        if withoutHeaders || excludingAllFooters {
            excludedHeadersOrFootersSections = self.allSectionsIndexes
        }
        var excludedRows: [IndexPath]?
        if excludingAllRows { excludedRows = allRowsIndexPaths }
        return self.screenshotExcludingHeadersAtSections(excludedHeaderSections: withoutHeaders ? NSSet(array: excludedHeadersOrFootersSections!) : nil,
                                                         excludingFootersAtSections: excludingAllFooters ? NSSet(array: excludedHeadersOrFootersSections!) : nil, excludingRowsAtIndexPaths: excludingAllRows ? NSSet(array: excludedRows!) : nil)
    }

    func screenshotExcludingHeadersAtSections(excludedHeaderSections: NSSet?, excludingFootersAtSections: NSSet?,
                                              excludingRowsAtIndexPaths: NSSet?) -> UIImage? {
        var screenshots: [UIImage] = []
        if let headerScreenshot = screenshotOfHeaderView {
            screenshots.append(headerScreenshot)
        }
        for section in 0..<numberOfSections {
            if let headerScreenshot = screenshotOfHeaderViewAtSection(section: section, excludedHeaderSections: excludedHeaderSections) {
                screenshots.append(headerScreenshot)
            }
            for row in 0..<numberOfRows(inSection: section) {
                let cellIndexPath = IndexPath(row: row, section: section)
                if let cellScreenshot = screenshotOfCellAtIndexPath(indexPath: cellIndexPath) {
                    screenshots.append(cellScreenshot)
                }
            }
            if let footerScreenshot = screenshotOfFooterViewAtSection(section: section, excludedFooterSections: excludingFootersAtSections) {
                screenshots.append(footerScreenshot)
            }
        }
        if let footerScreenshot = screenshotOfFooterView {
            screenshots.append(footerScreenshot)
        }
        return UIImage.verticalImageFromArray(imagesArray: screenshots)
    }

    func screenshotOfHeadersAtSections(includedHeaderSection: NSSet, footersAtSections: NSSet?, rowsAtIndexPaths: NSSet?) -> UIImage? {
        var screenshots: [UIImage] = []
        for section in 0..<numberOfSections {
            if let headerScreenshot = screenshotOfHeaderViewAtSection(section: section, includedHeaderSections: includedHeaderSection) {
                screenshots.append(headerScreenshot)
            }
            for row in 0..<numberOfRows(inSection: section) {
                if let cellScreenshot = screenshotOfCellAtIndexPath(indexPath: IndexPath(row: row, section: section), includedIndexPaths: rowsAtIndexPaths) {
                    screenshots.append(cellScreenshot)
                }
            }
            if let footerScreenshot = screenshotOfFooterViewAtSection(section: section, includedFooterSections: footersAtSections) {
                screenshots.append(footerScreenshot)
            }
        }
        return UIImage.verticalImageFromArray(imagesArray: screenshots)
    }

    func screenshotOfCellAtIndexPath(indexPath: IndexPath, excludedIndexPaths: NSSet?) -> UIImage? {
        if let excludedIndexPaths = excludedIndexPaths, excludedIndexPaths.contains(indexPath) { return nil }
        return screenshotOfCellAtIndexPath(indexPath: indexPath)
    }

    func screenshotOfHeaderViewAtSection(section: Int, excludedHeaderSections: NSSet?) -> UIImage? {
        if let excludedHeaderSections = excludedHeaderSections, excludedHeaderSections.contains(section) { return nil }
        var sectionScreenshot: UIImage? = screenshotOfHeaderViewAtSection(section: section)
        sectionScreenshot = sectionScreenshot ?? blankScreenshotOfHeaderAtSection(section: section)
        return sectionScreenshot
    }

    func screenshotOfFooterViewAtSection(section: Int, excludedFooterSections: NSSet?) -> UIImage? {
        if let excludedFooterSections = excludedFooterSections, !excludedFooterSections.contains(section) { return nil }
        var sectionScreenshot: UIImage? = screenshotOfFooterViewAtSection(section: section)
        sectionScreenshot = sectionScreenshot ?? blankScreenshotOfFooterAtSection(section: section)
        return sectionScreenshot
    }

    func screenshotOfCellAtIndexPath(indexPath: IndexPath, includedIndexPaths: NSSet?) -> UIImage? {
        if let includedIndexPaths = includedIndexPaths, !includedIndexPaths.contains(indexPath) { return nil }
        return screenshotOfCellAtIndexPath(indexPath: indexPath)
    }

    func screenshotOfHeaderViewAtSection(section: Int, includedHeaderSections: NSSet?) -> UIImage? {
        if let includedHeaderSections = includedHeaderSections, !includedHeaderSections.contains(section) { return nil }
        var sectionScreenshot: UIImage? = screenshotOfHeaderViewAtSection(section: section)
        sectionScreenshot = sectionScreenshot ?? blankScreenshotOfHeaderAtSection(section: section)
        return sectionScreenshot
    }

    func screenshotOfFooterViewAtSection(section: Int, includedFooterSections: NSSet?)
    -> UIImage? {
        if let includedFooterSections = includedFooterSections, !includedFooterSections.contains(section) { return nil }
        var sectionScreenshot: UIImage? = screenshotOfFooterViewAtSection(section: section)
        sectionScreenshot = sectionScreenshot ?? blankScreenshotOfFooterAtSection(section: section)
        return sectionScreenshot
    }

    func blankScreenshotOfHeaderAtSection(section: Int) -> UIImage? {
        let headerRectSize: CGSize = CGSize(width: bounds.size.width, height: rectForHeader(inSection: section).size.height)
        return UIImage.imageWithColor(color: UIColor.clear, size: headerRectSize)
    }

    func blankScreenshotOfFooterAtSection(section: Int) -> UIImage? {
        let footerRectSize: CGSize = CGSize(width: bounds.size.width, height: rectForFooter(inSection: section).size.height)
        return UIImage.imageWithColor(color: UIColor.clear, size: footerRectSize)
    }

    var allSectionsIndexes: [Int] { (0..<numberOfSections).map { $0 } }

    var allRowsIndexPaths: [IndexPath] {
        var allRowsIndexPaths: [IndexPath] = []
        for sectionIdx in allSectionsIndexes {
            for rowNum in 0..<numberOfRows(inSection: sectionIdx) {
                let indexPath: IndexPath = IndexPath(row: rowNum, section: sectionIdx)
                allRowsIndexPaths.append(indexPath)
            }
        }
        return allRowsIndexPaths
    }

}
