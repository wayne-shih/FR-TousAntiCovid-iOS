// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ScreenshotViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 22/10/2021 - for the TousAntiCovid project.
//

import UIKit

final class ScreenshotViewController: UIViewController {

    override var modalPresentationStyle: UIModalPresentationStyle {
        get { .overFullScreen }
        set { }
    }
    override var prefersStatusBarHidden: Bool {
        get {
            if #available(iOS 13, *) {
                return true
            } else {
                return false
            }
        }
        set { }
    }

    private let containerView: UIView = UIView()
    private let imageView: UIImageView = UIImageView()
    private let flashView: UIView = UIView()
    private let screenshot: UIImage
    private let didFinishAnimating: () -> ()
    private let borderWidth: CGFloat = 8.0
    private let miniScreenshotMargin: CGFloat = 30.0

    private var widthConstraint: NSLayoutConstraint!
    private var horizontalConstraint: NSLayoutConstraint!
    private var verticalConstraint: NSLayoutConstraint!
    private let outerRadius: CGFloat = 16.0
    private var innerRadius: CGFloat { max(4.0, outerRadius - 4.0) }

    init(screenshot: UIImage, didFinishAnimating: @escaping () -> ()) {
        self.screenshot = screenshot
        self.didFinishAnimating = didFinishAnimating
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateScreenshot()
    }

    private func initUI() {
        initView()
        initImageView()
        initContainerView()
        initFlashView()
    }

    private func initView() {
        view.backgroundColor = .clear
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 1.0
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 4.0
    }

    private func initImageView() {
        imageView.image = screenshot
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = innerRadius
        imageView.layer.masksToBounds = true
        widthConstraint = imageView.widthAnchor.constraint(equalToConstant: view.bounds.width)
        widthConstraint.isActive = true
        let pointSize: CGSize = CGSize(width: screenshot.size.width / UIScreen.main.scale, height: screenshot.size.height / UIScreen.main.scale)
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: pointSize.height / pointSize.width).isActive = true
    }

    private func initContainerView() {
        containerView.backgroundColor = .white
        containerView.layer.borderWidth = 1.0
        containerView.layer.borderColor = UIColor(white: 0.8, alpha: 1.0).cgColor
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        horizontalConstraint = containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -borderWidth)
        horizontalConstraint.isActive = true
        verticalConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: borderWidth)
        verticalConstraint.isActive = true
        containerView.layer.cornerRadius = outerRadius
        containerView.layer.masksToBounds = true
        containerView.addConstrainedSubview(imageView, insets: UIEdgeInsets(top: borderWidth, left: borderWidth, bottom: -borderWidth, right: -borderWidth))
    }

    private func initFlashView() {
        flashView.backgroundColor = .white
        flashView.layer.cornerRadius = innerRadius
        flashView.layer.masksToBounds = true
        view.addSubview(flashView)
        flashView.translatesAutoresizingMaskIntoConstraints = false
        flashView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: borderWidth).isActive = true
        flashView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -borderWidth).isActive = true
        flashView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: borderWidth).isActive = true
        flashView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -borderWidth).isActive = true
    }

    private func animateScreenshot() {
        UIView.animate(withDuration: 0.5, delay: 0.3, animations: {
            self.flashView.backgroundColor = .clear
            self.flashView.layer.borderWidth = 1.0
            self.flashView.layer.borderColor = UIColor.black.cgColor
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let newWidth: CGFloat = self.view.bounds.width / 5.0
            self.widthConstraint.constant = newWidth
            self.horizontalConstraint.constant = self.miniScreenshotMargin
            self.verticalConstraint.constant = -self.miniScreenshotMargin

            UIView.animate(withDuration: 0.8, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.curveEaseOut]) {
                self.view.layoutIfNeeded()
            } completion: { _ in
                let newHeight: CGFloat = newWidth * self.containerView.frame.height / self.containerView.frame.width
                self.verticalConstraint.constant = newHeight + self.miniScreenshotMargin
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [.curveEaseIn], animations: {
                    self.view.layoutIfNeeded()
                }) { _ in
                    self.didFinishAnimating()
                }
            }
        }
    }

}
