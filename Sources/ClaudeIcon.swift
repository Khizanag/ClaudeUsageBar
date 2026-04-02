import AppKit
import SwiftUI

enum ClaudeIcon {
    static func loadTrayIcon(size: CGFloat = 18) -> NSImage? {
        let claudeAppIcon = "/Applications/Claude.app/Contents/Resources/TrayIconTemplate@2x.png"

        let executableURL = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
        let bundledIcon = executableURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/TrayIconTemplate@2x.png")
            .path

        let path = FileManager.default.fileExists(atPath: claudeAppIcon) ? claudeAppIcon : bundledIcon

        guard let image = NSImage(contentsOfFile: path) else { return nil }
        image.isTemplate = true
        image.size = NSSize(width: size, height: size)
        return image
    }

    static func swiftUIImage(size: CGFloat = 16) -> some View {
        Group {
            if let nsImage = loadTrayIcon(size: size) {
                Image(nsImage: nsImage)
                    .renderingMode(.template)
            } else {
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.7, weight: .bold))
            }
        }
    }
}
