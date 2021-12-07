// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DocumentExplanationViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 11/05/2021 - for the TousAntiCovid project.
//

import UIKit

final class DocumentExplanationViewController: CVTableViewController {

    private let certificateType: WalletConstant.CertificateType
    
    init(certificateType: WalletConstant.CertificateType) {
        self.certificateType = certificateType
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()
        initUI()
        reloadUI()
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    private func updateTitle() {
        title = "documentExplanationController.\(certificateType.textKey).title".localized
    }
    
    override func createSections() -> [CVSection] {
        makeSections {
            CVSection {
                CVRow(subtitle: "documentExplanationController.\(certificateType.textKey).explanation".localized,
                      xibName: .textCell,
                      theme: CVRow.Theme(backgroundColor: .clear,
                                         topInset: .zero,
                                         bottomInset: .zero,
                                         textAlignment: .natural))
             documentImageRow()
            }
        }
    }
    
    private func initUI() {
        addHeaderView(height: Appearance.TableView.Header.largeHeight)
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
    }
    
    private func addObservers() {
        LocalizationsManager.shared.addObserver(self)
    }
    
    private func removeObservers() {
        LocalizationsManager.shared.removeObserver(self)
    }

    private func documentImageRow() -> CVRow {
        let documentImage: UIImage
        switch certificateType {
        case .vaccination:
            documentImage = WalletImagesManager.shared.image(named: .vaccinCertificateFull)!
        case .sanitary:
            documentImage = WalletImagesManager.shared.image(named: .testCertificateFull)!
        case .sanitaryEurope:
            documentImage = WalletImagesManager.shared.image(named: .testEuropeCertificateFull)!
        case .vaccinationEurope:
            documentImage = WalletImagesManager.shared.image(named: .vaccinEuropeCertificateFull)!
        case .recoveryEurope:
            documentImage = WalletImagesManager.shared.image(named: .recoveryEuropeCertificateFull)!
        case .activityEurope:
            documentImage = WalletImagesManager.shared.image(named: .vaccinEuropeCertificateFull)!
        case .exemptionEurope:
            documentImage = WalletImagesManager.shared.image(named: .vaccinEuropeCertificateFull)!
        case .unknown:
            documentImage = UIImage()
        }
        let ratioHeight: CGFloat = (documentImage.size.height / documentImage.size.width) * UIScreen.main.bounds.width
        return CVRow(image: documentImage,
              xibName: .zoomableImageCell,
              theme: CVRow.Theme(topInset: Appearance.Cell.Inset.normal,
                                 leftInset: .zero,
                                 rightInset: .zero,
                                 imageSize: CGSize(width: UIScreen.main.bounds.width, height: ratioHeight)))
    }

}

extension DocumentExplanationViewController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}
