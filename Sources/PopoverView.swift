import SwiftUI

struct UsagePopoverView: View {
    @Bindable var viewModel: UsageViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.showWeeklyDetail {
                weeklyDetailView
            } else {
                mainView
            }
        }
        .frame(width: 340)
        .background(Claude.bg000)
    }
}

// MARK: - Main View
private extension UsagePopoverView {
    var mainView: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 12) {
                    if viewModel.hasLiveRateLimits {
                        rateLimitsCard
                    }
                    contextWindowCard
                    sessionTokensCard
                    weeklyCard
                }
                .padding(16)
            }
            .frame(maxHeight: 420)
            footer
        }
    }
}

// MARK: - Header
private extension UsagePopoverView {
    var header: some View {
        HStack(spacing: 8) {
            claudeLogo
            Text("Usage")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Claude.text000)
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 16, height: 16)
            }
            Button {
                viewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
                    .foregroundStyle(Claude.text400)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Claude.bg100)
    }

    var claudeLogo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Claude.accent.gradient)
                .frame(width: 22, height: 22)
            Image(systemName: "sparkle")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Rate Limits Card
private extension UsagePopoverView {
    var rateLimitsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Rate Limits")

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

// MARK: - Context Window Card
private extension UsagePopoverView {
    var contextWindowCard: some View {
        Group {
            if let used = viewModel.statusLine.contextUsedPercentage {
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("Context Window")
                    usageBar(
                        label: "Context Used",
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
}

// MARK: - Session Tokens Card
private extension UsagePopoverView {
    var sessionTokensCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Current Session")

            if let session = viewModel.currentSession {
                let total = session.totalTokens

                HStack(spacing: 0) {
                    statPill(viewModel.formatCompact(total.totalTokens), label: "Tokens")
                    statPill("\(session.messageCount)", label: "Messages")
                    modelPills(session.tokensByModel)
                }

                tokenBreakdownRow("Input", value: total.inputTokens)
                tokenBreakdownRow("Output", value: total.outputTokens)
                if total.cacheReadTokens > 0 {
                    tokenBreakdownRow("Cache Read", value: total.cacheReadTokens)
                }
                if total.cacheCreationTokens > 0 {
                    tokenBreakdownRow("Cache Write", value: total.cacheCreationTokens)
                }
            } else {
                Text("No active session")
                    .font(.system(size: 12))
                    .foregroundStyle(Claude.text500)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }
        }
        .cardStyle()
    }
}

// MARK: - Weekly Card
private extension UsagePopoverView {
    var weeklyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionLabel("Past 7 Days")
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.showWeeklyDetail = true
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text("Details")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(Claude.accent)
                }
                .buttonStyle(.plain)
            }

            let weekly = viewModel.weeklyUsage

            HStack(spacing: 0) {
                statPill(viewModel.formatCompact(weekly.totalTokens.totalTokens), label: "Tokens")
                statPill("\(weekly.totalMessages)", label: "Messages")
                statPill("\(weekly.totalSessions)", label: "Sessions")
            }

            if !weekly.tokensByModel.isEmpty {
                VStack(spacing: 4) {
                    ForEach(
                        weekly.tokensByModel.sorted(by: { $0.value.totalTokens > $1.value.totalTokens }),
                        id: \.key
                    ) { model, usage in
                        modelUsageRow(model, tokens: usage.totalTokens)
                    }
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Weekly Detail View
private extension UsagePopoverView {
    var weeklyDetailView: some View {
        VStack(spacing: 0) {
            // Back header
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.showWeeklyDetail = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Claude.accent)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Weekly Breakdown")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Claude.text000)

                Spacer()
                    .frame(width: 50)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Claude.bg100)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.weeklyUsage.dailyBreakdown.reversed(), id: \.date) { day in
                        dayCard(day)
                    }
                }
                .padding(16)
            }
            .frame(maxHeight: 420)

            footer
        }
    }

    func dayCard(_ day: DailyUsage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(formatDayLabel(day.date))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Claude.text200)
                Spacer()
                Text(viewModel.formatCompact(day.totalTokens.totalTokens))
                    .font(.system(size: 12, weight: .bold).monospacedDigit())
                    .foregroundStyle(Claude.accent)
            }

            ForEach(
                day.tokensByModel.sorted(by: { $0.value.totalTokens > $1.value.totalTokens }),
                id: \.key
            ) { model, usage in
                modelUsageRow(model, tokens: usage.totalTokens)
            }

            HStack(spacing: 8) {
                Label("\(day.messageCount) msgs", systemImage: "bubble.left")
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
            .font(.system(size: 11))
            .buttonStyle(.plain)
            .foregroundStyle(Claude.danger)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Claude.bg100)
    }
}

// MARK: - Shared Components
private extension UsagePopoverView {
    func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Claude.text500)
            .tracking(0.5)
    }

    func usageBar(
        label: String,
        percentage: Double,
        resetInfo: String?,
        color: Color? = nil,
        trackColor: Color? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Claude.text200)
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundStyle(color ?? Claude.usageColor(for: percentage))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(trackColor ?? Claude.usageTint(for: percentage))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color ?? Claude.usageColor(for: percentage))
                        .frame(width: geometry.size.width * min(percentage / 100, 1.0))
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

    func tokenBreakdownRow(_ label: String, value: Int) -> some View {
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

    func modelUsageRow(_ model: String, tokens: Int) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.modelColor(model))
                .frame(width: 7, height: 7)
            Text(viewModel.shortModelName(model))
                .font(.system(size: 11))
                .foregroundStyle(Claude.text300)
            Spacer()
            Text(viewModel.formatTokens(tokens))
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(Claude.text400)
        }
    }

    func statPill(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .bold).monospacedDigit())
                .foregroundStyle(Claude.text200)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Claude.text500)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    func modelPills(_ tokensByModel: [String: TokenUsage]) -> some View {
        HStack(spacing: 4) {
            ForEach(
                tokensByModel.sorted(by: { $0.value.totalTokens > $1.value.totalTokens }),
                id: \.key
            ) { model, _ in
                Circle()
                    .fill(viewModel.modelColor(model))
                    .frame(width: 7, height: 7)
                    .help(viewModel.shortModelName(model))
            }
        }
        .frame(maxWidth: .infinity)
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
