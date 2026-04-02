import SwiftUI

struct UsagePopoverView: View {
    @Bindable var viewModel: UsageViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Claude.bg300)

            if viewModel.showWeeklyDetail {
                weeklyDetailView
            } else {
                mainContent
            }

            Divider().overlay(Claude.bg300)
            footer
        }
        .frame(width: 340)
        .background(Claude.bg000)
    }
}

// MARK: - Header
private extension UsagePopoverView {
    var header: some View {
        HStack(spacing: 10) {
            ClaudeIcon.swiftUIImage(size: 20)
                .foregroundStyle(Claude.accent)

            Text("Claude Usage")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Claude.text000)

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 14, height: 14)
            }

            Button {
                viewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Claude.text400)
            }
            .buttonStyle(.plain)
            .help("Refresh")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Claude.bg100)
    }
}

// MARK: - Main Content
private extension UsagePopoverView {
    var mainContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                rateLimitsSection
                contextWindowSection
                sessionSection
                weeklySection
            }
            .padding(14)
        }
        .frame(maxHeight: 440)
    }
}

// MARK: - Rate Limits
private extension UsagePopoverView {
    @ViewBuilder
    var rateLimitsSection: some View {
        if viewModel.hasLiveRateLimits {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("Rate Limits", icon: "gauge.with.dots.needle.33percent")

                if let fiveHour = viewModel.statusLine.fiveHour {
                    usageBar(
                        label: "Session (5h)",
                        percentage: fiveHour.usedPercentage,
                        resetInfo: viewModel.formatTimeRemaining(until: fiveHour.resetsAt)
                    )
                }

                if let sevenDay = viewModel.statusLine.sevenDay {
                    usageBar(
                        label: "Weekly — All Models",
                        percentage: sevenDay.usedPercentage,
                        resetInfo: viewModel.formatTimeRemaining(until: sevenDay.resetsAt)
                    )
                }
            }
            .cardStyle()
        }
    }
}

// MARK: - Context Window
private extension UsagePopoverView {
    @ViewBuilder
    var contextWindowSection: some View {
        if let used = viewModel.statusLine.contextUsedPercentage {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("Context Window", icon: "text.page")

                usageBar(
                    label: "Tokens Used",
                    percentage: used,
                    resetInfo: nil,
                    color: Claude.blue,
                    trackColor: Claude.blueTint
                )
            }
            .cardStyle()
        }
    }
}

// MARK: - Current Session
private extension UsagePopoverView {
    var sessionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Current Session", icon: "bolt.fill")

            if let session = viewModel.currentSession {
                let total = session.totalTokens

                // Stats row
                HStack(spacing: 0) {
                    statCell(viewModel.formatCompact(total.totalTokens), label: "Tokens")
                    dividerLine
                    statCell("\(session.messageCount)", label: "Messages")
                    dividerLine
                    statCell(modelSummary(session.tokensByModel), label: "Models")
                }
                .padding(.vertical, 6)
                .background(Claude.bg200, in: RoundedRectangle(cornerRadius: 8))

                // Token breakdown
                VStack(spacing: 3) {
                    tokenRow("Input", value: total.inputTokens)
                    tokenRow("Output", value: total.outputTokens)
                    if total.cacheReadTokens > 0 {
                        tokenRow("Cache Read", value: total.cacheReadTokens)
                    }
                    if total.cacheCreationTokens > 0 {
                        tokenRow("Cache Write", value: total.cacheCreationTokens)
                    }
                }

                // Model breakdown
                if session.tokensByModel.count > 1 {
                    modelBreakdown(session.tokensByModel)
                }
            } else {
                emptyState("No active session detected", icon: "bolt.slash")
            }
        }
        .cardStyle()
    }
}

// MARK: - Weekly Overview
private extension UsagePopoverView {
    var weeklySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionHeader("Past 7 Days", icon: "calendar")
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.showWeeklyDetail = true
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text("Details")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Claude.accent)
                }
                .buttonStyle(.plain)
            }

            let weekly = viewModel.weeklyUsage
            let total = weekly.totalTokens

            if total.totalTokens > 0 {
                HStack(spacing: 0) {
                    statCell(viewModel.formatCompact(total.totalTokens), label: "Tokens")
                    dividerLine
                    statCell("\(weekly.totalMessages)", label: "Messages")
                    dividerLine
                    statCell("\(weekly.totalSessions)", label: "Sessions")
                }
                .padding(.vertical, 6)
                .background(Claude.bg200, in: RoundedRectangle(cornerRadius: 8))

                if !weekly.tokensByModel.isEmpty {
                    modelBreakdown(weekly.tokensByModel)
                }
            } else {
                emptyState("No usage in the past 7 days", icon: "calendar.badge.minus")
            }
        }
        .cardStyle()
    }
}

// MARK: - Weekly Detail
private extension UsagePopoverView {
    var weeklyDetailView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.showWeeklyDetail = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                        Text("Back")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Claude.accent)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Weekly Breakdown")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Claude.text000)

                Spacer()
                    .frame(width: 50)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Claude.bg100)

            Divider().overlay(Claude.bg300)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(viewModel.weeklyUsage.dailyBreakdown.reversed(), id: \.date) { day in
                        dayCard(day)
                    }
                }
                .padding(14)
            }
            .frame(maxHeight: 400)
        }
    }

    func dayCard(_ day: DailyUsage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(formatDayLabel(day.date))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Claude.text200)
                Spacer()
                Text(viewModel.formatCompact(day.totalTokens.totalTokens) + " tokens")
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Claude.accent)
            }

            modelBreakdown(day.tokensByModel)

            HStack(spacing: 12) {
                Label("\(day.messageCount) messages", systemImage: "bubble.left")
                Label("\(day.sessionCount) sessions", systemImage: "terminal")
            }
            .font(.system(size: 10))
            .foregroundStyle(Claude.text500)
        }
        .cardStyle()
    }

    func formatDayLabel(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = inputFormatter.date(from: dateString) else { return dateString }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "EEEE, MMM d"
        return outputFormatter.string(from: date)
    }
}

// MARK: - Footer
private extension UsagePopoverView {
    var footer: some View {
        HStack {
            if let lastRefreshed = viewModel.lastRefreshed {
                Text("Updated \(lastRefreshed, style: .relative) ago")
                    .font(.system(size: 10))
                    .foregroundStyle(Claude.text500)
            }
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(size: 11, weight: .medium))
            .buttonStyle(.plain)
            .foregroundStyle(Claude.text400)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Shared Components
private extension UsagePopoverView {
    func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Claude.accent)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Claude.text400)
                .tracking(0.6)
        }
    }

    func usageBar(
        label: String,
        percentage: Double,
        resetInfo: String?,
        color: Color? = nil,
        trackColor: Color? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Claude.text200)
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.system(size: 13, weight: .bold).monospacedDigit())
                    .foregroundStyle(color ?? Claude.usageColor(for: percentage))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(trackColor ?? Claude.usageTint(for: percentage))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color ?? Claude.usageColor(for: percentage))
                        .frame(width: max(geometry.size.width * min(percentage / 100, 1.0), 2))
                }
            }
            .frame(height: 8)

            if let resetInfo {
                Text(resetInfo)
                    .font(.system(size: 10))
                    .foregroundStyle(Claude.text500)
            }
        }
    }

    func tokenRow(_ label: String, value: Int) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Claude.text400)
            Spacer()
            Text(viewModel.formatTokens(value))
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(Claude.text300)
        }
    }

    func modelBreakdown(_ tokensByModel: [String: TokenUsage]) -> some View {
        VStack(spacing: 3) {
            ForEach(
                tokensByModel.sorted(by: { $0.value.totalTokens > $1.value.totalTokens }),
                id: \.key
            ) { model, usage in
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.modelColor(model))
                        .frame(width: 7, height: 7)
                    Text(viewModel.shortModelName(model))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Claude.text300)
                    Spacer()
                    Text(viewModel.formatTokens(usage.totalTokens))
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(Claude.text400)
                }
            }
        }
    }

    func statCell(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold).monospacedDigit())
                .foregroundStyle(Claude.text200)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Claude.text500)
        }
        .frame(maxWidth: .infinity)
    }

    var dividerLine: some View {
        Rectangle()
            .fill(Claude.bg300)
            .frame(width: 1, height: 24)
    }

    func modelSummary(_ tokensByModel: [String: TokenUsage]) -> String {
        tokensByModel.keys
            .sorted { (tokensByModel[$0]?.totalTokens ?? 0) > (tokensByModel[$1]?.totalTokens ?? 0) }
            .map { viewModel.shortModelName($0) }
            .prefix(2)
            .joined(separator: ", ")
    }

    func emptyState(_ message: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Claude.text500)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Claude.text500)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

// MARK: - Card Modifier
private extension View {
    func cardStyle() -> some View {
        self
            .padding(12)
            .background(Claude.bg100, in: RoundedRectangle(cornerRadius: 10))
    }
}
