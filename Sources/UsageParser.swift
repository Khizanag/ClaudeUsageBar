import Foundation

actor UsageParser {
    private let claudeDir: URL
    private let projectsDir: URL
    private let sessionsDir: URL
    private let statusFilePath = "/tmp/claude-usage-status.json"

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        claudeDir = home.appendingPathComponent(".claude")
        projectsDir = claudeDir.appendingPathComponent("projects")
        sessionsDir = claudeDir.appendingPathComponent("sessions")
    }

    // MARK: - Status Line (Rate Limits)
    func parseStatusLine() -> StatusLineData {
        var data = StatusLineData()

        guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: statusFilePath)),
              let json = try? JSONSerialization.jsonObject(with: fileData) as? [String: Any]
        else { return data }

        if let rateLimits = json["rate_limits"] as? [String: Any] {
            if let fiveHour = rateLimits["five_hour"] as? [String: Any],
               let pct = fiveHour["used_percentage"] as? Double {
                let resetsAt = (fiveHour["resets_at"] as? Double).map {
                    Date(timeIntervalSince1970: $0)
                }
                data.fiveHour = RateLimitInfo(usedPercentage: pct, resetsAt: resetsAt)
            }
            if let sevenDay = rateLimits["seven_day"] as? [String: Any],
               let pct = sevenDay["used_percentage"] as? Double {
                let resetsAt = (sevenDay["resets_at"] as? Double).map {
                    Date(timeIntervalSince1970: $0)
                }
                data.sevenDay = RateLimitInfo(usedPercentage: pct, resetsAt: resetsAt)
            }
        }

        if let ctx = json["context_window"] as? [String: Any] {
            data.contextUsedPercentage = ctx["used_percentage"] as? Double
            data.contextRemainingPercentage = ctx["remaining_percentage"] as? Double
        }

        return data
    }

    // MARK: - Current Session
    func parseCurrentSession() -> SessionUsage? {
        let activeSessions = findActiveSessions()
        guard let mostRecent = activeSessions.last else { return nil }

        let jsonlFiles = findJSONLFiles(for: mostRecent.sessionId)
        guard !jsonlFiles.isEmpty else { return nil }

        var session = SessionUsage(
            sessionId: mostRecent.sessionId,
            startTime: mostRecent.startedAt
        )

        for file in jsonlFiles {
            parseJSONLFile(file, into: &session)
        }

        return session
    }

    // MARK: - Weekly Usage
    func parseWeeklyUsage() -> WeeklyUsage {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            return WeeklyUsage()
        }

        let recentFiles = findRecentJSONLFiles(since: weekAgo)
        var dailyMap: [String: DailyUsage] = [:]
        var weeklyTokensByModel: [String: TokenUsage] = [:]
        var sessionIds = Set<String>()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for file in recentFiles {
            guard let entries = readJSONLEntries(from: file) else { continue }

            for entry in entries {
                guard let timestamp = extractTimestamp(from: entry),
                      timestamp >= weekAgo else { continue }

                let dateKey = dateFormatter.string(from: timestamp)

                if let sessionId = entry["sessionId"] as? String {
                    sessionIds.insert("\(dateKey)-\(sessionId)")
                }

                guard let message = entry["message"] as? [String: Any],
                      let role = message["role"] as? String,
                      role == "assistant",
                      let usage = message["usage"] as? [String: Any] else { continue }

                let model = (message["model"] as? String) ?? "unknown"
                guard isRealModel(model) else { continue }
                let tokens = extractTokens(from: usage)
                guard tokens.totalTokens > 0 else { continue }

                if dailyMap[dateKey] == nil {
                    dailyMap[dateKey] = DailyUsage(date: dateKey)
                }
                dailyMap[dateKey]?.messageCount += 1

                var existing = dailyMap[dateKey]?.tokensByModel[model] ?? TokenUsage()
                existing.add(tokens)
                dailyMap[dateKey]?.tokensByModel[model] = existing

                var weeklyExisting = weeklyTokensByModel[model] ?? TokenUsage()
                weeklyExisting.add(tokens)
                weeklyTokensByModel[model] = weeklyExisting
            }
        }

        for dateKey in Set(sessionIds.map { s -> String in
            let parts = s.split(separator: "-", maxSplits: 3)
            return parts.prefix(3).joined(separator: "-")
        }) {
            dailyMap[dateKey]?.sessionCount = sessionIds
                .filter { $0.hasPrefix(dateKey) }
                .count
        }

        let sortedDays = dailyMap.keys.sorted().compactMap { dailyMap[$0] }

        return WeeklyUsage(
            dailyBreakdown: sortedDays,
            tokensByModel: weeklyTokensByModel
        )
    }

    // MARK: - Active Sessions
    private func findActiveSessions() -> [(sessionId: String, startedAt: Date, pid: Int)] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: sessionsDir,
            includingPropertiesForKeys: nil
        ) else { return [] }

        var sessions: [(sessionId: String, startedAt: Date, pid: Int)] = []

        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let sessionId = json["sessionId"] as? String,
                  let pid = json["pid"] as? Int,
                  let startedAtMs = json["startedAt"] as? Double else { continue }

            let isRunning = kill(Int32(pid), 0) == 0
            guard isRunning else { continue }

            let startedAt = Date(timeIntervalSince1970: startedAtMs / 1000)
            sessions.append((sessionId, startedAt, pid))
        }

        return sessions.sorted { $0.startedAt < $1.startedAt }
    }

    // MARK: - JSONL File Discovery
    private func findJSONLFiles(for sessionId: String) -> [URL] {
        let fm = FileManager.default
        guard let projectDirs = try? fm.contentsOfDirectory(
            at: projectsDir,
            includingPropertiesForKeys: nil
        ) else { return [] }

        var results: [URL] = []
        let targetFilename = "\(sessionId).jsonl"

        for projectDir in projectDirs {
            let sessionFile = projectDir.appendingPathComponent(targetFilename)
            if fm.fileExists(atPath: sessionFile.path) {
                results.append(sessionFile)
            }

            let subagentsDir = projectDir
                .appendingPathComponent(sessionId)
                .appendingPathComponent("subagents")
            if let subFiles = try? fm.contentsOfDirectory(
                at: subagentsDir,
                includingPropertiesForKeys: nil
            ) {
                results.append(contentsOf: subFiles.filter { $0.pathExtension == "jsonl" })
            }
        }

        return results
    }

    private func findRecentJSONLFiles(since date: Date) -> [URL] {
        let fm = FileManager.default
        guard let projectDirs = try? fm.contentsOfDirectory(
            at: projectsDir,
            includingPropertiesForKeys: nil
        ) else { return [] }

        var results: [URL] = []

        for projectDir in projectDirs {
            guard let files = try? fm.contentsOfDirectory(
                at: projectDir,
                includingPropertiesForKeys: [.contentModificationDateKey]
            ) else { continue }

            for file in files where file.pathExtension == "jsonl" {
                guard let attrs = try? file.resourceValues(forKeys: [.contentModificationDateKey]),
                      let modDate = attrs.contentModificationDate,
                      modDate >= date else { continue }
                results.append(file)
            }

            for file in files where file.hasDirectoryPath {
                let subagentsDir = file.appendingPathComponent("subagents")
                guard let subFiles = try? fm.contentsOfDirectory(
                    at: subagentsDir,
                    includingPropertiesForKeys: [.contentModificationDateKey]
                ) else { continue }

                for subFile in subFiles where subFile.pathExtension == "jsonl" {
                    guard let attrs = try? subFile.resourceValues(
                        forKeys: [.contentModificationDateKey]
                    ),
                          let modDate = attrs.contentModificationDate,
                          modDate >= date else { continue }
                    results.append(subFile)
                }
            }
        }

        return results
    }

    // MARK: - JSONL Parsing
    private func parseJSONLFile(_ url: URL, into session: inout SessionUsage) {
        guard let entries = readJSONLEntries(from: url) else { return }

        for entry in entries {
            guard let message = entry["message"] as? [String: Any],
                  let role = message["role"] as? String,
                  role == "assistant",
                  let usage = message["usage"] as? [String: Any] else { continue }

            let model = (message["model"] as? String) ?? "unknown"
            guard isRealModel(model) else { continue }
            let tokens = extractTokens(from: usage)
            guard tokens.totalTokens > 0 else { continue }

            session.messageCount += 1
            var existing = session.tokensByModel[model] ?? TokenUsage()
            existing.add(tokens)
            session.tokensByModel[model] = existing
        }
    }

    private func readJSONLEntries(from url: URL) -> [[String: Any]]? {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else { return nil }

        var entries: [[String: Any]] = []
        for line in content.components(separatedBy: .newlines) where !line.isEmpty {
            guard let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any]
            else { continue }
            entries.append(json)
        }
        return entries
    }

    private func extractTokens(from usage: [String: Any]) -> TokenUsage {
        TokenUsage(
            inputTokens: usage["input_tokens"] as? Int ?? 0,
            outputTokens: usage["output_tokens"] as? Int ?? 0,
            cacheCreationTokens: usage["cache_creation_input_tokens"] as? Int ?? 0,
            cacheReadTokens: usage["cache_read_input_tokens"] as? Int ?? 0
        )
    }

    private func extractTimestamp(from entry: [String: Any]) -> Date? {
        guard let timestampStr = entry["timestamp"] as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: timestampStr) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: timestampStr)
    }

    private func isRealModel(_ model: String) -> Bool {
        !model.hasPrefix("<") && model != "unknown"
    }
}
