// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VideoPlayerCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 06/10/2021 - for the TousAntiCovid project.
//

import UIKit
import AVFoundation
import PKHUD

final class VideoPlayerCell: CVTableViewCell {
    @IBOutlet private var videoView: PlayerView!
    @IBOutlet private var heightConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        selectionStyle = .none
        accessoryType = .none
    }

    override func setup(with row: CVRow) {
        super.setup(with: row)
        if let videoUrl = row.associatedValue as? URL {
            videoView.play(with: videoUrl) { [weak self] ratio in
                guard let self = self else { return }
                self.heightConstraint.constant = self.frame.width * ratio
                self.currentAssociatedRow?.valueChanged?(nil)
            }
        }
    }
}
