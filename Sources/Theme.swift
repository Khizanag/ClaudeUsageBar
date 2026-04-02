import AppKit
import SwiftUI

enum Claude {
    // MARK: - Backgrounds
    static let bg000 = Color(adaptive: (light: 0xFAF9F5, dark: 0x1A1918))
    static let bg100 = Color(adaptive: (light: 0xF3F1E8, dark: 0x242220))
    static let bg200 = Color(adaptive: (light: 0xEBE7DA, dark: 0x2E2B28))
    static let bg300 = Color(adaptive: (light: 0xE0DBCC, dark: 0x3A3633))
    static let bg400 = Color(adaptive: (light: 0xD4CEBC, dark: 0x4A4541))

    // MARK: - Text
    static let text000 = Color(adaptive: (light: 0x191918, dark: 0xF3F1E8))
    static let text200 = Color(adaptive: (light: 0x3D3929, dark: 0xD8D2C4))
    static let text300 = Color(adaptive: (light: 0x5D5847, dark: 0xB0A998))
    static let text400 = Color(adaptive: (light: 0x78725F, dark: 0x8E877A))
    static let text500 = Color(adaptive: (light: 0x9B9484, dark: 0x6E6860))

    // MARK: - Accent (Claude Terracotta)
    static let accent = Color(adaptive: (light: 0xDA7756, dark: 0xE58E71))
    static let accentHover = Color(adaptive: (light: 0xC4623F, dark: 0xDA7756))
    static let accentTint = Color(adaptive: (light: 0xFAE8E0, dark: 0x3D2A22))

    // MARK: - Secondary (Blue)
    static let blue = Color(adaptive: (light: 0x4A90D9, dark: 0x6BA8E8))
    static let blueTint = Color(adaptive: (light: 0xE0EEFA, dark: 0x1C2E40))

    // MARK: - Pro (Purple / Opus)
    static let pro = Color(adaptive: (light: 0x6B5CE7, dark: 0x8B7EF0))
    static let proTint = Color(adaptive: (light: 0xEAE6FC, dark: 0x28234A))

    // MARK: - Danger
    static let danger = Color(adaptive: (light: 0xC2392A, dark: 0xE04F42))
    static let dangerTint = Color(adaptive: (light: 0xFCE4E1, dark: 0x3D201C))

    // MARK: - Success
    static let success = Color(adaptive: (light: 0x5E8C3D, dark: 0x7EAD5E))
    static let successTint = Color(adaptive: (light: 0xE2EED5, dark: 0x243020))

    // MARK: - Warning
    static let warning = Color(adaptive: (light: 0xD4920A, dark: 0xE8AD38))
    static let warningTint = Color(adaptive: (light: 0xFDF0D0, dark: 0x3D3018))

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
