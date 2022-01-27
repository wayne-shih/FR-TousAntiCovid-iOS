// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal enum Colors {
    internal static let cardTableViewBackground = ColorAsset(name: "cardTableViewBackground")
    internal static let cardTableViewCellBackground = ColorAsset(name: "cardTableViewCellBackground")
    internal static let separator = ColorAsset(name: "separator")
    internal static let gradientEndBlue = ColorAsset(name: "gradientEndBlue")
    internal static let gradientEndGreen = ColorAsset(name: "gradientEndGreen")
    internal static let gradientStartBlue = ColorAsset(name: "gradientStartBlue")
    internal static let gradientStartGreen = ColorAsset(name: "gradientStartGreen")
    internal static let notificationCellBackground = ColorAsset(name: "notificationCellBackground")
    internal static let notificationRiskCellBackground = ColorAsset(name: "notificationRiskCellBackground")
    internal static let background = ColorAsset(name: "background")
    internal static let barBackground = ColorAsset(name: "barBackground")
    internal static let bottomSheetDimmingBackground = ColorAsset(name: "bottomSheetDimmingBackground")
    internal static let bottomWarning = ColorAsset(name: "bottomWarning")
    internal static let bottomWarningSeparator = ColorAsset(name: "bottomWarningSeparator")
    internal static let buttonBackground = ColorAsset(name: "buttonBackground")
    internal static let buttonLabel = ColorAsset(name: "buttonLabel")
    internal static let captionTitle = ColorAsset(name: "captionTitle")
    internal static let error = ColorAsset(name: "error")
    internal static let extraLightTint = ColorAsset(name: "extraLightTint")
    internal static let isolationAction = ColorAsset(name: "isolationAction")
    internal static let lightSeparator = ColorAsset(name: "lightSeparator")
    internal static let secondaryButtonBackground = ColorAsset(name: "secondaryButtonBackground")
    internal static let secondaryButtonLabel = ColorAsset(name: "secondaryButtonLabel")
    internal static let smartWalletInfo = ColorAsset(name: "smartWalletInfo")
    internal static let success = ColorAsset(name: "success")
    internal static let tacBlue = ColorAsset(name: "tacBlue")
    internal static let tint = ColorAsset(name: "tint")
    internal static let urgent = ColorAsset(name: "urgent")
    internal static let walletCellHeader = ColorAsset(name: "walletCellHeader")
  }
  internal enum Images {
    internal static let shops = ImageAsset(name: "Shops")
    internal static let walletCard = ImageAsset(name: "WalletCard")
    internal static let attestationCard = ImageAsset(name: "attestationCard")
    internal static let declareCard = ImageAsset(name: "declareCard")
    internal static let doctorCard = ImageAsset(name: "doctorCard")
    internal static let healthCard = ImageAsset(name: "healthCard")
    internal static let homeNotifCard = ImageAsset(name: "homeNotifCard")
    internal static let airCheck = ImageAsset(name: "AirCheck")
    internal static let airRecycling = ImageAsset(name: "AirRecycling")
    internal static let cough = ImageAsset(name: "Cough")
    internal static let distance = ImageAsset(name: "Distance")
    internal static let hands = ImageAsset(name: "Hands")
    internal static let mask = ImageAsset(name: "Mask")
    internal static let tissues = ImageAsset(name: "Tissues")
    internal static let compare = ImageAsset(name: "Compare")
    internal static let icon1 = ImageAsset(name: "Icon1")
    internal static let icon2 = ImageAsset(name: "Icon2")
    internal static let `import` = ImageAsset(name: "Import")
    internal static let add = ImageAsset(name: "Add")
    internal static let audio = ImageAsset(name: "Audio")
    internal static let badge = ImageAsset(name: "Badge")
    internal static let contact = ImageAsset(name: "Contact")
    internal static let document = ImageAsset(name: "Document")
    internal static let emptyHeart = ImageAsset(name: "EmptyHeart")
    internal static let faq = ImageAsset(name: "FAQ")
    internal static let filledHeart = ImageAsset(name: "FilledHeart")
    internal static let hand = ImageAsset(name: "Hand")
    internal static let manageData = ImageAsset(name: "ManageData")
    internal static let moreInfo = ImageAsset(name: "MoreInfo")
    internal static let opinion = ImageAsset(name: "Opinion")
    internal static let privacy = ImageAsset(name: "Privacy")
    internal static let qrCodePlaceholder = ImageAsset(name: "QRCodePlaceholder")
    internal static let replay = ImageAsset(name: "Replay")
    internal static let visual = ImageAsset(name: "Visual")
    internal static let web = ImageAsset(name: "Web")
    internal static let chartLegend = ImageAsset(name: "chartLegend")
    internal static let chevron = ImageAsset(name: "chevron")
    internal static let cloudDownload = ImageAsset(name: "cloud-download")
    internal static let cloudUpload = ImageAsset(name: "cloud-upload")
    internal static let compassToured = ImageAsset(name: "compassToured")
    internal static let conditions = ImageAsset(name: "conditions")
    internal static let confetti = ImageAsset(name: "confetti")
    internal static let gradient = ImageAsset(name: "gradient")
    internal static let help = ImageAsset(name: "help")
    internal static let info = ImageAsset(name: "info")
    internal static let invertedGradient = ImageAsset(name: "invertedGradient")
    internal static let moreAlpha = ImageAsset(name: "more-alpha")
    internal static let moreColored = ImageAsset(name: "more-colored")
    internal static let more = ImageAsset(name: "more")
    internal static let pause = ImageAsset(name: "pause")
    internal static let phone = ImageAsset(name: "phone")
    internal static let play = ImageAsset(name: "play")
    internal static let refresh = ImageAsset(name: "refresh")
    internal static let shareIcon = ImageAsset(name: "shareIcon")
    internal static let trash = ImageAsset(name: "trash")
    internal static let trendDown = ImageAsset(name: "trendDown")
    internal static let trendSteady = ImageAsset(name: "trendSteady")
    internal static let trendUp = ImageAsset(name: "trendUp")
    internal static let webSync = ImageAsset(name: "web-sync")
    internal static let bluetooth = ImageAsset(name: "Bluetooth")
    internal static let logo = ImageAsset(name: "Logo")
    internal static let notification = ImageAsset(name: "Notification")
    internal static let splash = ImageAsset(name: "Splash")
    internal static let support = ImageAsset(name: "Support")
    internal static let passInfo = ImageAsset(name: "PassInfo")
    internal static let passWarning = ImageAsset(name: "PassWarning")
    internal static let republicFrLogo = ImageAsset(name: "RepublicFrLogo")
    internal static let santePubliqueLogo = ImageAsset(name: "SantePubliqueLogo")
    internal static let attestation = ImageAsset(name: "Attestation")
    internal static let declare = ImageAsset(name: "Declare")
    internal static let diagnosis = ImageAsset(name: "Diagnosis")
    internal static let envoiData = ImageAsset(name: "EnvoiData")
    internal static let health = ImageAsset(name: "Health")
    internal static let maintenance = ImageAsset(name: "Maintenance")
    internal static let proximity = ImageAsset(name: "Proximity")
    internal static let proximityOff = ImageAsset(name: "ProximityOff")
    internal static let share = ImageAsset(name: "Share")
    internal static let sick = ImageAsset(name: "Sick")
    internal static let thumbsup = ImageAsset(name: "Thumbsup")
    internal static let venuesRecording = ImageAsset(name: "VenuesRecording")
    internal static let wallet = ImageAsset(name: "Wallet")
    internal static let screenshotLogo = ImageAsset(name: "ScreenshotLogo")
    internal static let tabBarDeclareNormal = ImageAsset(name: "TabBarDeclare-Normal")
    internal static let tabBarInfoNormal = ImageAsset(name: "TabBarInfo-Normal")
    internal static let tabBarProximityNormal = ImageAsset(name: "TabBarProximity-Normal")
    internal static let tabBarSharingNormal = ImageAsset(name: "TabBarSharing-Normal")
    internal static let tabBarSickNormal = ImageAsset(name: "TabBarSick-Normal")
    internal static let tabBarSupportNormal = ImageAsset(name: "TabBarSupport-Normal")
    internal static let tabBarDeclareSelected = ImageAsset(name: "TabBarDeclare-Selected")
    internal static let tabBarInfoSelected = ImageAsset(name: "TabBarInfo-Selected")
    internal static let tabBarProximitySelected = ImageAsset(name: "TabBarProximity-Selected")
    internal static let tabBarSharingSelected = ImageAsset(name: "TabBarSharing-Selected")
    internal static let tabBarSickSelected = ImageAsset(name: "TabBarSick-Selected")
    internal static let tabBarSupportSelected = ImageAsset(name: "TabBarSupport-Selected")
    internal static let brightnessOff = ImageAsset(name: "BrightnessOff")
    internal static let brightnessOn = ImageAsset(name: "BrightnessOn")
    internal static let logosPasseport = ImageAsset(name: "LogosPasseport")
    internal static let selectorListOFF = ImageAsset(name: "SelectorListOFF")
    internal static let selectorListON = ImageAsset(name: "SelectorListON")
    internal static let shareItem = ImageAsset(name: "ShareItem")
    internal static let walletPhone = ImageAsset(name: "WalletPhone")
    internal static let eligible = ImageAsset(name: "eligible")
    internal static let expired = ImageAsset(name: "expired")
    internal static let expiredSoon = ImageAsset(name: "expiredSoon")
    internal static let logoPS = ImageAsset(name: "logoPS")
    internal static let tacHorizontalAlert = ImageAsset(name: "TACHorizontalAlert")
    internal static let usefulLinks = ImageAsset(name: "UsefulLinks")
    internal static let about = ImageAsset(name: "about")
    internal static let bubble = ImageAsset(name: "bubble")
    internal static let centresvaxx = ImageAsset(name: "centresvaxx")
    internal static let close = ImageAsset(name: "close")
    internal static let compass = ImageAsset(name: "compass")
    internal static let dataMatrix = ImageAsset(name: "dataMatrix")
    internal static let dgsurgent = ImageAsset(name: "dgsurgent")
    internal static let flag = ImageAsset(name: "flag")
    internal static let history = ImageAsset(name: "history")
    internal static let homeRing = ImageAsset(name: "homeRing")
    internal static let location = ImageAsset(name: "location")
    internal static let parallaxEffect = ImageAsset(name: "parallaxEffect")
    internal static let pharmacy = ImageAsset(name: "pharmacy")
    internal static let qrScan = ImageAsset(name: "qrScan")
    internal static let qrScanItem = ImageAsset(name: "qrScanItem")
    internal static let search = ImageAsset(name: "search")
    internal static let updateApp = ImageAsset(name: "updateApp")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var color: Color = Color(asset: self)

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init!(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image named \(name).")
    }
    return result
  }
}

internal extension ImageAsset.Image {
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init!(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    Bundle(for: BundleToken.self)
  }()
}
// swiftlint:enable convenience_type
