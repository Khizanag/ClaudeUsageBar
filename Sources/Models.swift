import Foundation

struct TokenUsage: Sendable {
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    var cacheCreationTokens: Int = 0
    var cacheReadTokens: Int = 0

    var totalTokens: Int {
        inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
    }

    mutating func add(_ other: TokenUsage) {
        inputTokens += other.inputTokens
        outputTokens += other.outputTokens
        cacheCreationTokens += other.cacheCreationTokens
        cacheReadTokens += other.cacheReadTokens
    }
}

struct RateLimitInfo: Sendable {
    let usedPercentage: Double
    let resetsAt: Date?
}

struct StatusLineData: Sendable {
    var fiveHour: RateLimitInfo?
    var sevenDay: RateLimitInfo?
    var contextUsedPercentage: Double?
    var contextRemainingPercentage: Double?
}

struct SessionUsage: Sendable {
    let sessionId: String
    let startTime: Date
    var tokensByModel: [String: TokenUsage] = [:]
    var messageCount: Int = 0

    var totalTokens: TokenUsage {
        var total = TokenUsage()
        for usage in tokensByModel.values {
            total.add(usage)
        }
        return total
    }
}

struct DailyUsage: Sendable {
    let date: String
    var tokensByModel: [String: TokenUsage] = [:]
    var messageCount: Int = 0
    var sessionCount: Int = 0

    var totalTokens: TokenUsage {
        var total = TokenUsage()
        for usage in tokensByModel.values {
            total.add(usage)
        }
        return total
    }
}

struct WeeklyUsage: Sendable {
    var dailyBreakdown: [DailyUsage] = []
    var tokensByModel: [String: TokenUsage] = [:]

    var totalTokens: TokenUsage {
        var total = TokenUsage()
        for usage in tokensByModel.values {
            total.add(usage)
        }
        return total
    }

    var totalMessages: Int {
        dailyBreakdown.reduce(0) { $0 + $1.messageCount }
    }

    var totalSessions: Int {
        dailyBreakdown.reduce(0) { $0 + $1.sessionCount }
    }
}
