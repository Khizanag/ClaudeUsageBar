# ClaudeUsageBar

A lightweight macOS menu bar app that shows your Claude Code token usage at a glance — current session stats and a 7-day weekly breakdown, parsed entirely from local data.

## What It Shows

**Menu Bar Icon** — A sparkle icon with a compact token count (e.g. `12.4K`, `1.2M`) for the active session.

**Popover (click the icon):**

| Section | Details |
|---------|---------|
| **Current Session** | Total tokens, input/output/cache breakdown, per-model split, message count |
| **Weekly — All Models** | 7-day totals, messages, sessions, per-model breakdown |
| **Weekly Details** (tap "Details") | Day-by-day breakdown with per-model usage and session counts |

Models are color-coded: purple = Opus, orange = Sonnet, green = Haiku.

## Requirements

- macOS 14.0+
- Swift 6.3+ (Xcode 16+)
- An active `~/.claude/` directory (created by Claude Code or Claude Desktop)

## Installation

### Build

```bash
git clone https://github.com/Khizanag/ClaudeUsageBar.git
cd ClaudeUsageBar
swift build -c release
```

The binary is at `.build/release/ClaudeUsageBar`.

### Run manually

```bash
.build/release/ClaudeUsageBar &
```

### Auto-start on login (LaunchAgent)

1. Create the plist:

```bash
cat > ~/Library/LaunchAgents/com.khizanag.claudeusagebar.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.khizanag.claudeusagebar</string>
    <key>ProgramArguments</key>
    <array>
        <string>FULL_PATH_TO/.build/release/ClaudeUsageBar</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>/tmp/claudeusagebar.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/claudeusagebar.err</string>
</dict>
</plist>
EOF
```

Replace `FULL_PATH_TO` with the actual path to the repo (e.g. `/Users/you/GitHub/ClaudeUsageBar`).

2. Load it:

```bash
launchctl load ~/Library/LaunchAgents/com.khizanag.claudeusagebar.plist
```

### Managing the LaunchAgent

```bash
# Stop
launchctl unload ~/Library/LaunchAgents/com.khizanag.claudeusagebar.plist

# Start
launchctl load ~/Library/LaunchAgents/com.khizanag.claudeusagebar.plist

# Rebuild & restart
swift build -c release \
  && launchctl unload ~/Library/LaunchAgents/com.khizanag.claudeusagebar.plist \
  && launchctl load ~/Library/LaunchAgents/com.khizanag.claudeusagebar.plist

# Check status
launchctl list | grep claudeusagebar

# View logs
cat /tmp/claudeusagebar.log
cat /tmp/claudeusagebar.err
```

### Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.khizanag.claudeusagebar.plist
rm ~/Library/LaunchAgents/com.khizanag.claudeusagebar.plist
```

## How It Works

The app reads Claude Code's local data — no API keys or network access required.

| Data Source | Purpose |
|-------------|---------|
| `~/.claude/sessions/*.json` | Detect active sessions (checks if PID is still running) |
| `~/.claude/projects/**/*.jsonl` | Parse token usage from conversation logs |

Each JSONL entry for an assistant message contains a `usage` object with `input_tokens`, `output_tokens`, `cache_creation_input_tokens`, and `cache_read_input_tokens`, plus the `model` name and `sessionId`.

**Refresh behavior:**
- Auto-refreshes every 30 seconds in the background
- Menu bar title updates every 5 seconds
- Manual refresh via the reload button in the popover

## Limitations

- **No subscription limit percentages** — Claude Max/Pro weekly limit bars (the ones on claude.ai/settings/billing) are tracked server-side only. There is no public API to access them. This app shows raw token consumption from local logs instead. See [anthropics/claude-code#32796](https://github.com/anthropics/claude-code/issues/32796) for the feature request.
- **Subagent tokens are included** — tokens from spawned subagents (worktrees, parallel agents) are counted when their JSONL files fall within the date range.
- **Cache stats** — `stats-cache.json` is only updated periodically by Claude Code itself; this app parses the raw JSONL files for real-time accuracy.

## Project Structure

```
Sources/
  main.swift            — App entry, NSStatusBar + NSPopover setup
  Models.swift          — TokenUsage, SessionUsage, DailyUsage, WeeklyUsage
  UsageParser.swift     — JSONL file discovery and parsing (actor-isolated)
  UsageViewModel.swift  — Observable view model with auto-refresh
  PopoverView.swift     — SwiftUI popover UI
```

## License

MIT
