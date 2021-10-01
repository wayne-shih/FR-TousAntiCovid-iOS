// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SegmentedCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/05/2021 - for the TousAntiCovid project.
//

import UIKit

final class SegmentedCell: CVTableViewCell {

    @IBOutlet private var segmentedControl: UISegmentedControl!

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupContent(with: row)
    }
    
    private func setupUI(with row: CVRow) {
        segmentedControl.setTitleTextAttributes([.font: row.theme.titleFont()], for: .selected)
        segmentedControl.setTitleTextAttributes([.font: row.theme.subtitleFont()], for: .normal)
    }
    
    private func setupContent(with row: CVRow) {
        guard let titles = row.segmentsTitles else { return }
        segmentedControl.removeAllSegments()
        (0..<titles.count).forEach { segmentedControl.insertSegment(withTitle: titles[$0], at: $0, animated: false) }
        segmentedControl.selectedSegmentIndex = row.selectedSegmentIndex ?? 0
        
        if #available(iOS 13.0, *) {
            // We don't modify the segmented tint color for iOS 13+.
        } else {
            segmentedControl.tintColor = Appearance.tintColor
        }
    }
    
    @IBAction private func didSelectSegment(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.currentAssociatedRow?.segmentsActions?[self.segmentedControl.selectedSegmentIndex]()
        }
    }

}
