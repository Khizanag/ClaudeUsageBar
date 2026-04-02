import Foundation
import SwiftUI

@MainActor
@Observable
final class UsageViewModel {
    var statusLine = StatusLineData()
    var currentSession: SessionUsage?
    var weeklyUsage = WeeklyUsage()
    var isLoading = false
    var lastRefreshed: Date?
    var showWeeklyDetail = false

    private let parser = UsageParser()
    private var refreshTimer: Timer?

    func startAutoRefresh() {
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func refresh() {
        guard !isLoading else { return }
        isLoading = true

        Task {
            let status = await parser.parseStatusLine()
            let session = await parser.parseCurrentSession()
            let weekly = await parser.parseWeeklyUsage()

            statusLine = status
            currentSession = session
            weeklyUsage = weekly
            lastRefreshed = Date()
            isLoading = false
        }
    }

    // MARK: - Menu Bar Display
    var menuBarTitle: String {
        if let fiveHour = statusLine.fiveHour {
            "\(Int(fiveHour.usedPercentage))%"
        } else if let session = currentSession {
            formatCompact(session.totalTokens.totalTokens)
        } else {
            ""
        }
    }

    var hasLiveRateLimits: Bool {
        statusLine.fiveHour != nil || statusLine.sevenDay != nil
    }

    // MARK: - Formatting
    func formatCompact(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            String(format: "%.1fM", Double(tokens) / 1_000_000)
        } else if tokens >= 1_000 {
            String(format: "%.0fK", Double(tokens) / 1_000)
        } else {
            "\(tokens)"
        }
    }

    func formatTokens(_ tokens: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: tokens)) ?? "\(tokens)"
    }

    func shortModelName(_ model: String) -> String {
        if model.contains("opus") {
            "Opus"
        } else if model.contains("sonnet") {
            "Sonnet"
        } else if model.contains("haiku") {
            "Haiku"
        } else {
            model
        }
    }

    func modelColor(_ model: String) -> Color {
        if model.contains("opus") {
            Claude.opus
        } else if model.contains("sonnet") {
            Claude.sonnet
        } else if model.contains("haiku") {
            Claude.haiku
        } else {
            Claude.text400
        }
    }

    func formatTimeRemaining(until date: Date?) -> String? {
        guard let date, date > Date() else { return nil }
        let interval = date.timeIntervalSince(Date())

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "Resets in \(hours)h \(minutes)m"
        }
        return "Resets in \(minutes)m"
    }
}
