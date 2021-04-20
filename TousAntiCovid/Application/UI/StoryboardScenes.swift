// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

// swiftlint:disable sorted_imports
import Foundation
import UIKit

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Storyboard Scenes

// swiftlint:disable explicit_type_interface identifier_name line_length type_body_length type_name
internal enum StoryboardScene {
  internal enum BottomButtonContainer: StoryboardType {
    internal static let storyboardName = "BottomButtonContainer"

    internal static let bottomButtonContainerController = SceneType<TousAntiCovid.BottomButtonContainerController>(storyboard: BottomButtonContainer.self, identifier: "BottomButtonContainerController")
  }
  internal enum BottomMessageContainer: StoryboardType {
    internal static let storyboardName = "BottomMessageContainer"

    internal static let bottomMessageContainerViewController = SceneType<TousAntiCovid.BottomMessageContainerViewController>(storyboard: BottomMessageContainer.self, identifier: "BottomMessageContainerViewController")
  }
  internal enum CVNavigationChild: StoryboardType {
    internal static let storyboardName = "CVNavigationChild"

    internal static let cvNavigationChildController = SceneType<TousAntiCovid.CVNavigationChildController>(storyboard: CVNavigationChild.self, identifier: "CVNavigationChildController")
  }
  internal enum CodeFullScreen: StoryboardType {
    internal static let storyboardName = "CodeFullScreen"

    internal static let codeFullScreenViewController = SceneType<TousAntiCovid.CodeFullScreenViewController>(storyboard: CodeFullScreen.self, identifier: "CodeFullScreenViewController")
  }
  internal enum FlashReportCode: StoryboardType {
    internal static let storyboardName = "FlashReportCode"

    internal static let flashCodeController = SceneType<TousAntiCovid.FlashReportCodeController>(storyboard: FlashReportCode.self, identifier: "FlashCodeController")
  }
  internal enum FlashVenueCode: StoryboardType {
    internal static let storyboardName = "FlashVenueCode"

    internal static let flashCodeController = SceneType<TousAntiCovid.FlashVenueCodeController>(storyboard: FlashVenueCode.self, identifier: "FlashCodeController")
  }
  internal enum FlashWallet2DDoc: StoryboardType {
    internal static let storyboardName = "FlashWallet2DDoc"

    internal static let flashWallet2DDocController = SceneType<TousAntiCovid.FlashWallet2DDocController>(storyboard: FlashWallet2DDoc.self, identifier: "FlashWallet2DDocController")
  }
  internal enum FlashWalletCode: StoryboardType {
    internal static let storyboardName = "FlashWalletCode"

    internal static let flashWalletCodeController = SceneType<TousAntiCovid.FlashWalletCodeController>(storyboard: FlashWalletCode.self, identifier: "FlashWalletCodeController")
  }
  internal enum ModalContainer: StoryboardType {
    internal static let storyboardName = "ModalContainer"

    internal static let modalContainerViewController = SceneType<TousAntiCovid.ModalContainerViewController>(storyboard: ModalContainer.self, identifier: "ModalContainerViewController")
  }
  internal enum WalletCertificateVerified: StoryboardType {
    internal static let storyboardName = "WalletCertificateVerified"

    internal static let walletCertificateVerifiedController = SceneType<TousAntiCovid.WalletCertificateVerifiedController>(storyboard: WalletCertificateVerified.self, identifier: "WalletCertificateVerifiedController")
  }
}
// swiftlint:enable explicit_type_interface identifier_name line_length type_body_length type_name

// MARK: - Implementation Details

internal protocol StoryboardType {
  static var storyboardName: String { get }
}

internal extension StoryboardType {
  static var storyboard: UIStoryboard {
    let name = self.storyboardName
    return UIStoryboard(name: name, bundle: BundleToken.bundle)
  }
}

internal struct SceneType<T: UIViewController> {
  internal let storyboard: StoryboardType.Type
  internal let identifier: String

  internal func instantiate() -> T {
    let identifier = self.identifier
    guard let controller = storyboard.storyboard.instantiateViewController(withIdentifier: identifier) as? T else {
      fatalError("ViewController '\(identifier)' is not of the expected class \(T.self).")
    }
    return controller
  }
}

internal struct InitialSceneType<T: UIViewController> {
  internal let storyboard: StoryboardType.Type

  internal func instantiate() -> T {
    guard let controller = storyboard.storyboard.instantiateInitialViewController() as? T else {
      fatalError("ViewController is not of the expected class \(T.self).")
    }
    return controller
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    Bundle(for: BundleToken.self)
  }()
}
// swiftlint:enable convenience_type
