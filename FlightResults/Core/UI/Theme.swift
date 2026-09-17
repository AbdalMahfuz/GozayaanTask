import UIKit

/// Design tokens sampled from the design PNGs (spec 05 §1, D-29). One place
/// to swap the brand font in later (D-27).
enum Theme {
    enum Colors {
        static let navy = UIColor(hex: 0x00026E)
        static let yellow = UIColor(hex: 0xFDCC02)
        static let brandBlue = UIColor(hex: 0x4073BF)
        static let textPrimary = UIColor(hex: 0x022738)
        static let textSecondary = UIColor(hex: 0x546378)
        static let separator = UIColor(hex: 0xDBDDE0)
        static let dayOffsetRed = UIColor(hex: 0xF33A3A)
        static let cardBackground = UIColor(hex: 0xFFFFFF)
        static let promoMint = UIColor(hex: 0xE5FFEC)
        static let progressOrange = UIColor(hex: 0xFF6F00)
        static let selectionTint = UIColor(hex: 0xECF3FE)
        static let sortBorder = UIColor(hex: 0xBCC9DC)
        static let chartBorderLoading = UIColor(hex: 0xA5ABB2)
        static let skeletonStart = UIColor(hex: 0x01026E)
        static let skeletonEnd = UIColor(hex: 0x1D4DA2)
        static let onNavy = UIColor.white
        static let onNavySecondary = UIColor.white.withAlphaComponent(0.8)
    }

    /// SF Pro (the system font), sizes/weights matched to Figma (D-27).
    enum Typography {
        static let headerTitle = UIFont.systemFont(ofSize: 20, weight: .bold)
        static let headerSubtitle = UIFont.systemFont(ofSize: 12, weight: .medium)
        static let chipDate = UIFont.systemFont(ofSize: 12, weight: .regular)
        static let chipPrice = UIFont.systemFont(ofSize: 14, weight: .medium)
        static let sortFilter = UIFont.systemFont(ofSize: 12, weight: .bold)
        static let button = UIFont.systemFont(ofSize: 16, weight: .semibold)
        static let loadingTitle = UIFont.systemFont(ofSize: 20, weight: .semibold)
        static let airline = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let points = UIFont.systemFont(ofSize: 14, weight: .regular)
        static let time = UIFont.systemFont(ofSize: 18, weight: .bold)
        static let airportCode = UIFont.systemFont(ofSize: 15, weight: .regular)
        static let meta = UIFont.systemFont(ofSize: 14, weight: .regular)
        static let dayOffset = UIFont.systemFont(ofSize: 11, weight: .medium)
        static let currency = UIFont.systemFont(ofSize: 13, weight: .regular)
        static let price = UIFont.systemFont(ofSize: 20, weight: .bold)
        static let promoTitle = UIFont.systemFont(ofSize: 10, weight: .semibold)
        static let promoLink = UIFont.systemFont(ofSize: 8, weight: .medium)
        static let stateTitle = UIFont.systemFont(ofSize: 20, weight: .semibold)
        static let stateMessage = UIFont.systemFont(ofSize: 15, weight: .regular)
        // Splash only — not in the Figma file, so these are our own (D-36).
        static let splashTitle = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let splashSubtitle = UIFont.systemFont(ofSize: 14, weight: .medium)
    }

    enum Spacing {
        static let screenInset: CGFloat = 16
        static let cardPadding: CGFloat = 16
        static let cardSpacing: CGFloat = 12
        static let skeletonSpacing: CGFloat = 8
        static let cardRadius: CGFloat = 12
        static let skeletonRadius: CGFloat = 16
        static let buttonRadius: CGFloat = 6
        static let chipWidth: CGFloat = 112
        static let chipHeight: CGFloat = 56
        static let chipIndicatorHeight: CGFloat = 3
        static let promoRadius: CGFloat = 8
        static let dropdownRadius: CGFloat = 12
    }
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
