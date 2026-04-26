# MeltingClaude

A lightweight macOS menu bar app that tracks your **Claude Code** rate-limit status in real time, so you stop getting cut off mid-task.

> Reads your local Claude Code session logs (`~/.claude/projects/`) and aggregates token usage across the current 5-hour rate-limit window. **100% local — no servers, no API keys, no telemetry.**

---

## Why

Claude Code subscribers (Pro / Max) hit the 5-hour rolling rate limit constantly. The Anthropic Console shows usage *after the fact* — MeltingClaude shows it **now**, in your menu bar, while you work.

## What it shows

- **Menu bar icon** — 4-state tier (`OK / Active / Heavy / At limit`), changes automatically as you accumulate tokens in the current 5-hour block.
- **Popover** (click the icon):
  - Current 5h block: progress bar + tokens / cap + reset countdown
  - Last 7 days: daily bar chart (color-coded by tier)
  - Today: token total + message count
  - Recent: last few messages (collapsible)

## Who it's for

- Claude Code users (CLI, or IDE extensions for VS Code / Cursor / JetBrains)
- On a Pro / Max 5× / Max 20× subscription
- macOS 14+ (Sonoma or later)

## What it can't do

- It can't predict the **exact** rate limit — Anthropic doesn't publish them. Thresholds are estimates per plan and you can switch the plan in Settings.
- It only tracks **Claude Code**. Chat at claude.ai or the Claude desktop chat app are not tracked (different product, no local logs).
- macOS only.

## Privacy

Zero network. Zero accounts. Your usage data lives in a local SQLite database on your Mac. See [Privacy Policy](docs/APP_STORE.md#7-privacy-policy-그대로-호스팅).

## Build from source

```bash
git clone git@github.com:SSub-jun/MeltingClaude.git
cd MeltingClaude
open ClaudeUsage.xcodeproj
```

Requires Xcode 16+, macOS 14+ deployment target.

## License

TBD
