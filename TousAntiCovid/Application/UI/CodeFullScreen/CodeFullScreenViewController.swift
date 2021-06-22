// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CodeFullScreenViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//
import UIKit

final class CodeFullScreenViewController: UIViewController {

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var codeBottomLabel: UILabel!
    @IBOutlet private var label: UILabel!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var imageLeadingConstraint: NSLayoutConstraint!
    
    private var codeImage: UIImage!
    private var codeBottomText: String?
    private var text: String!
    private var lastBrightness: CGFloat = 0.0
    private var isFirstLoad: Bool = true
    
    static func controller(codeImage: UIImage, text: String, codeBottomText: String? = nil) -> UIViewController {
        let fullscreenController: CodeFullScreenViewController = StoryboardScene.CodeFullScreen.codeFullScreenViewController.instantiate()
        fullscreenController.codeImage = codeImage
        fullscreenController.text = text
        fullscreenController.codeBottomText = codeBottomText
        return fullscreenController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstLoad {
            isFirstLoad = false
            updateBrightnessForQRCodeReadability()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        putBrightnessBackToOriginalValue()
    }
    
    deinit {
        removeObservers()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        imageView.image = codeImage
        imageLeadingConstraint.constant = 60.0
        label.text = text
        label.textColor = .black
        closeButton.setTitle("common.close".localized, for: .normal)
        closeButton.setTitleColor(.black, for: .normal)
        label.font = .regular(size: 20.0)
        codeBottomLabel.text = codeBottomText
        codeBottomLabel.font = Appearance.Cell.Text.headTitleFont4
        codeBottomLabel.textColor = .black
        codeBottomLabel.isHidden = codeBottomText == nil
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updateBrightnessForQRCodeReadability() {
        lastBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = CGFloat(1.0)
    }
    
    private func putBrightnessBackToOriginalValue() {
        UIScreen.main.brightness = lastBrightness
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @objc private func appDidBecomeActive() {
        updateBrightnessForQRCodeReadability()
    }
    
}
