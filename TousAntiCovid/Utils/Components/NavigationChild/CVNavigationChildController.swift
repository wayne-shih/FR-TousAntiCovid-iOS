// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVNavigationChildController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class CVNavigationChildController: UIViewController {

    override var childForStatusBarHidden: UIViewController? { embeddedController }

    var navigationBarHeight: CGFloat { navigationBar.frame.height }

    @IBOutlet private var navigationBarBackgroundView: UIVisualEffectView!
    @IBOutlet private(set) var navigationBar: UINavigationBar!
    @IBOutlet private var containerView: UIView!
    
    @IBOutlet private var fakeNavigationBar: UINavigationBar!
    @IBOutlet private var fakeNavigationItem: UINavigationItem!
    
    weak var titleLabel: UILabel?
    var rightBarButtonItemView: UIView? {
        guard let buttonItem = fakeNavigationItem.rightBarButtonItem else { return nil }
        return buttonItem.value(forKey: "view") as? UIView
    }

    private weak var titleLabelContainerView: UIView?
    private var embeddedController: UIViewController?
    private var titleLabelContainerViewIntialY: CGFloat?
    private var initialTitleLabelMinY: CGFloat?
    private var isLargeTitleVisible: Bool = true
    
    class func controller(_ embeddedController: UIViewController) -> UIViewController {
        let containerController: CVNavigationChildController = StoryboardScene.CVNavigationChild.cvNavigationChildController.instantiate()
        containerController.embeddedController = embeddedController
        return containerController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initNavigationBar()
        setupEmbeddedController()
    }
    
    func updateTitle(_ title: String?) {
        navigationBar.topItem?.title = title
    }
    
    func updateLabel(titleLabel: UILabel?, containerView: UIView?) {
        self.titleLabel = titleLabel
        self.titleLabelContainerView = containerView
        setupNavigationTitle()
    }
    
    func updateLeftBarButtonItem(_ barButtonItem: UIBarButtonItem) {
        fakeNavigationItem.leftBarButtonItem = barButtonItem
    }
    
    func updateRightBarButtonItem(_ barButtonItem: UIBarButtonItem) {
        fakeNavigationItem.rightBarButtonItem = barButtonItem
    }

    func rightBarButtonItemFrame(in view: UIView) -> CGRect? {
        guard let buttonItem = fakeNavigationItem.rightBarButtonItem else { return nil }
        guard let buttonItemView = buttonItem.value(forKey: "view") as? UIView else { return nil }
        guard let buttonItemImageView = buttonItemView.subviews.first?.subviews.first else { return nil }
        return view.convert(buttonItemImageView.frame, from: buttonItemImageView.superview)
    }
    
    private func initNavigationBar() {
        navigationBar.isAccessibilityElement = false
        navigationBar.accessibilityElementsHidden = true
        navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont]
        updateNavigationBarAlpha(0.0)
        fakeNavigationBar.tintColor = Asset.Colors.tint.color
        fakeNavigationBar.tintAdjustmentMode = .normal
        if #available(iOS 15, *) {
            let appearance: UINavigationBarAppearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            fakeNavigationBar.scrollEdgeAppearance = appearance
            fakeNavigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.standardAppearance = appearance
        } else {
            navigationBar.setBackgroundImage(UIImage(), for: .default)
            fakeNavigationBar.setBackgroundImage(UIImage(), for: .default)
            fakeNavigationBar.shadowImage = UIImage()
        }
    }
    
    private func setupEmbeddedController() {
        guard let controller = embeddedController else { return }
        addChildViewController(controller, containerView: containerView)
    }
    
    private func updateNavigationBarAlpha(_ alpha: CGFloat) {
        navigationBar.alpha = alpha
        navigationBarBackgroundView.alpha = alpha
        titleLabel?.alpha = 1.0 - alpha
    }

    private func setupNavigationTitle() {
        guard titleLabelContainerViewIntialY == nil else { return }
        titleLabelContainerViewIntialY = titleLabelContainerView?.frame.minY
        guard let titleLabel = titleLabel else { return }
        let frame: CGRect = view.convert(titleLabel.frame, from: titleLabel.superview)
        initialTitleLabelMinY = frame.midY - 40.0
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let titleLabel = titleLabel else { return }
        guard titleLabelContainerView?.frame.minY == titleLabelContainerViewIntialY else { return }
        let navigationBarFrame: CGRect = navigationBar.frame
        let titleFrame: CGRect = view.convert(titleLabel.frame, from: titleLabel.superview)
        let distance: CGFloat = titleFrame.minY - navigationBarFrame.maxY
        let willShowLargeTitle: Bool = distance > 0
        let alpha: CGFloat = willShowLargeTitle ? 0.0 : 1.0
        if willShowLargeTitle != isLargeTitleVisible {
            isLargeTitleVisible = willShowLargeTitle
            UIView.animate(withDuration: 0.2) {
                self.updateNavigationBarAlpha(alpha)
            }
        }
    }
    
}

extension UIViewController {
    
    var navigationChildController: CVNavigationChildController? {
        var parentController: UIViewController? = self
        while let controller = parentController?.parent {
            parentController = controller
            if parentController is CVNavigationChildController {
                break
            }
        }
        return parentController as? CVNavigationChildController
    }
    
}
