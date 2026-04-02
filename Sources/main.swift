import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let viewModel = UsageViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = loadClaudeIcon()
            button.imagePosition = .imageLeading
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 500)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: UsagePopoverView(viewModel: viewModel)
        )

        viewModel.startAutoRefresh()

        Task {
            while true {
                try? await Task.sleep(for: .seconds(5))
                updateMenuBarTitle()
            }
        }
    }

    private func updateMenuBarTitle() {
        guard let button = statusItem.button else { return }
        let title = viewModel.menuBarTitle
        if !title.isEmpty {
            button.title = " \(title)"
        }
    }

    private func loadClaudeIcon() -> NSImage? {
        // Use Claude.app's template icon (auto-tints for light/dark menu bar)
        let claudeAppIcon = "/Applications/Claude.app/Contents/Resources/TrayIconTemplate@2x.png"

        // Fallback: icon bundled next to the executable
        let executableURL = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
        let bundledIcon = executableURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/TrayIconTemplate@2x.png")
            .path

        let path = FileManager.default.fileExists(atPath: claudeAppIcon) ? claudeAppIcon : bundledIcon

        guard let image = NSImage(contentsOfFile: path) else { return nil }
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            viewModel.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

@MainActor
func runApp() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}

runApp()
