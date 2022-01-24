// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AdditionalInfoCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 11/01/2022 - for the TousAntiCovid project.
//

import UIKit

final class AdditionalInfoCell: CardCell {
    private var isCollapsed: Bool = true
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard isCollapsed else { return }
        super.setHighlighted(highlighted, animated: animated)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cvSubtitleLabel?.isHidden = !isCollapsed
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.isCollapsed != (self.cvTitleLabel?.isTruncated == true) {
                self.isCollapsed = self.cvTitleLabel?.isTruncated == true
                self.currentAssociatedRow?.didValidateValue?(nil, self)
            }
        }
    }
}
