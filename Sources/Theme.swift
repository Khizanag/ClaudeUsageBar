import AppKit
import SwiftUI

enum Claude {
    // MARK: - Backgrounds
    static let bg000 = Color(adaptive: (light: 0xF8F8F6, dark: 0x1A1918))
    static let bg100 = Color(adaptive: (light: 0xF5F3EC, dark: 0x242220))
    static let bg200 = Color(adaptive: (light: 0xEFEBDF, dark: 0x2E2B28))
    static let bg300 = Color(adaptive: (light: 0xE5E0D1, dark: 0x3A3633))
    static let bg400 = Color(adaptive: (light: 0xD9D2BE, dark: 0x4A4541))

    // MARK: - Text
    static let text000 = Color(adaptive: (light: 0x0F0E0D, dark: 0xF5F3EC))
    static let text200 = Color(adaptive: (light: 0x3C3229, dark: 0xDBD5C9))
    static let text300 = Color(adaptive: (light: 0x514C45, dark: 0xB5AFA6))
    static let text400 = Color(adaptive: (light: 0x655F57, dark: 0x918A82))
    static let text500 = Color(adaptive: (light: 0x736C63, dark: 0x736C63))

    // MARK: - Accent (Terracotta)
    static let accent = Color(adaptive: (light: 0xD97757, dark: 0xE08B6E))
    static let accentDark = Color(adaptive: (light: 0xAB5535, dark: 0xC96B45))
    static let accentTint = Color(adaptive: (light: 0xF0D8CE, dark: 0x3D2A22))

    // MARK: - Secondary (Blue)
    static let blue = Color(adaptive: (light: 0x2080DE, dark: 0x5AA3E8))
    static let blueTint = Color(adaptive: (light: 0xD8EAFA, dark: 0x1A2E42))

    // MARK: - Pro (Purple)
    static let pro = Color(adaptive: (light: 0x5145A1, dark: 0x7B6FCF))
    static let proTint = Color(adaptive: (light: 0xDED8F0, dark: 0x2A2540))

    // MARK: - Danger
    static let danger = Color(adaptive: (light: 0xA72418, dark: 0xE04A3C))
    static let dangerTint = Color(adaptive: (light: 0xEBD5D5, dark: 0x3D1F1C))

    // MARK: - Success
    static let success = Color(adaptive: (light: 0x788C5D, dark: 0x96AD78))
    static let successTint = Color(adaptive: (light: 0xE2EAD5, dark: 0x263020))

    // MARK: - Warning
    static let warning = Color(adaptive: (light: 0xCC8800, dark: 0xE0A630))
    static let warningTint = Color(adaptive: (light: 0xFAECD8, dark: 0x3D3018))

    // MARK: - Model Colors
    static let opus = pro
    static let sonnet = accent
    static let haiku = success

    // MARK: - Usage Bar Colors
    static func usageColor(for percentage: Double) -> Color {
        if percentage >= 90 {
            danger
        } else if percentage >= 75 {
            warning
        } else {
            accent
        }
    }

    static func usageTint(for percentage: Double) -> Color {
        if percentage >= 90 {
            dangerTint
        } else if percentage >= 75 {
            warningTint
        } else {
            accentTint
        }
    }
}

// MARK: - Adaptive Color
extension Color {
    init(adaptive pair: (light: UInt, dark: UInt)) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let hex = isDark ? pair.dark : pair.light
            let r = CGFloat((hex >> 16) & 0xFF) / 255.0
            let g = CGFloat((hex >> 8) & 0xFF) / 255.0
            let b = CGFloat(hex & 0xFF) / 255.0
            return NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
        })
    }
}
