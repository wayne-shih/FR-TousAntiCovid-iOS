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
import PKHUD

final class CodeFullScreenViewController: UIViewController {

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var codeBottomLabel: UILabel!
    @IBOutlet private var label: UILabel!
    @IBOutlet private var footerLabel: UILabel!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var imageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var headerImageView: UIImageView!
    @IBOutlet private var segmentedControl: UISegmentedControl!

    private var codeDetails: [CodeDetail] = []
    private var showHeaderImage: Bool = false
    private var lastBrightness: CGFloat?
    private var isFirstLoad: Bool = true
    private var footerLabelTapGesture: UITapGestureRecognizer?
    
    class func controller(codeDetails: [CodeDetail], showHeaderImage: Bool = false) -> CodeFullScreenViewController {
        let fullscreenController: CodeFullScreenViewController = StoryboardScene.CodeFullScreen.codeFullScreenViewController.instantiate()
        fullscreenController.codeDetails = codeDetails
        fullscreenController.showHeaderImage = showHeaderImage
        return fullscreenController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBottomLabelTapGesture()
        updateContent()
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

    func update(codeDetails: [CodeDetail], showHeaderImage: Bool = false) {
        self.codeDetails = codeDetails
        self.showHeaderImage = showHeaderImage
        setupUI()
        updateContent()
    }

    private func setupUI() {
        view.backgroundColor = .white
        imageLeadingConstraint.constant = 60.0
        label.textColor = .black

        closeButton.setTitle("common.close".localized, for: .normal)
        closeButton.setTitleColor(.black, for: .normal)
        label.font = .regular(size: 20.0)
        codeBottomLabel.font = Appearance.Cell.Text.headTitleFont4
        codeBottomLabel.textColor = .black

        segmentedControl.isHidden = codeDetails.count < 2
        if !segmentedControl.isHidden {
            segmentedControl.setTitleTextAttributes([.font: { Appearance.SegmentedControl.selectedFont }()], for: .selected)
            segmentedControl.setTitleTextAttributes([.font: { Appearance.SegmentedControl.normalFont }()], for: .normal)
            if #available(iOS 13.0, *) {
                segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
                segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
            }
            setupSegmentedControl()
        }
        headerImageView.isHidden = !showHeaderImage
    }

    private func setupSegmentedControl() {
        segmentedControl.removeAllSegments()
        (0..<codeDetails.count).forEach { segmentedControl.insertSegment(withTitle: codeDetails[$0].segmentedControlTitle, at: $0, animated: false) }
        segmentedControl.selectedSegmentIndex = 0

        if #available(iOS 13.0, *) {
            // We don't modify the segmented tint color for iOS 13+.
        } else {
            segmentedControl.tintColor = Appearance.tintColor
        }
        segmentedControl.isHidden = codeDetails.count < 1
    }

    private func updateContent() {
        let codeDetail: CodeDetail = codeDetails[segmentedControl.selectedSegmentIndex]
        imageView.image = codeDetail.codeImage
        label.text = codeDetail.text
        codeBottomLabel.isHidden = codeDetail.codeBottomText == nil
        codeBottomLabel.text = codeDetail.codeBottomText
        footerLabel.text = codeDetail.footerText ?? codeDetail.hash
        footerLabel.isHidden = footerLabel.text == nil
        let canDisplayHash: Bool = segmentedControl.selectedSegmentIndex > 0 || (codeDetail.footerText == nil && codeDetail.hash != nil)
        footerLabel.textAlignment = canDisplayHash ? .center : .natural
        footerLabel.textColor = canDisplayHash ? .darkGray : .black
        footerLabel.font = canDisplayHash ? .regular(size: 11.0) : .regular(size: 17.0)
        footerLabel.isAccessibilityElement = !canDisplayHash
        footerLabelTapGesture?.isEnabled = canDisplayHash
        setupAccessibility()
    }

    private func setupBottomLabelTapGesture() {
        footerLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapFooterLabel))
        footerLabel.addGestureRecognizer(footerLabelTapGesture!)
    }

    private func setupAccessibility() {
        closeButton.accessibilityHint = "accessibility.closeModal.zGesture".localized
        footerLabel.accessibilityLabel = footerLabel.text?.removingEmojis()
        label.accessibilityLabel = label.text?.removingEmojis()
    }

    @objc private func didTapFooterLabel() {
        guard let hash = codeDetails[segmentedControl.selectedSegmentIndex].hash else { return }
        UIPasteboard.general.string = hash
        HUD.flash(.labeledSuccess(title: "common.copied".localized, subtitle: nil))
    }

    @IBAction private func didSelectSegment(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        updateContent()
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updateBrightnessForQRCodeReadability() {
        if lastBrightness == nil { lastBrightness = round(UIScreen.main.brightness * 100.0) / 100.0 }
        UIScreen.main.brightness = 1.0
    }
    
    private func putBrightnessBackToOriginalValue() {
        lastBrightness.map { UIScreen.main.brightness = $0 }
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @objc private func appDidBecomeActive() {
        updateBrightnessForQRCodeReadability()
    }

    @objc private func appWillResignActive() {
        putBrightnessBackToOriginalValue()
    }

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true)
        return true
    }
    
}
