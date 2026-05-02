# Privacy Policy — MeltingClaude

Last updated: 2026-05-02

MeltingClaude is a macOS menu-bar app that visualizes your local Claude Code usage. This document explains exactly what the app does and does not do with your data.

## Data we collect

**None.** The app does not collect, transmit, or share any data with us or any third party.

## Data we read locally

The app reads session log files that Claude Code stores at:
- `~/.claude/projects/<project-hash>/<session-id>.jsonl`

These files are created by Claude Code (a separate product by Anthropic), not by us. On first launch the app prompts you to grant access to the `~/.claude/` folder via a standard macOS folder picker. The app uses a security-scoped bookmark so it only ever reads from the folder you selected.

We extract only the token-usage fields (`input_tokens`, `output_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`), the timestamp, the model name, and the project working directory.

## Data we store locally

The aggregated token data is saved to a local SQLite database inside the app's sandbox container on your Mac at:
- `~/Library/Containers/com.byeonjunseob.MeltingClaude/Data/Library/Application Support/MeltingClaude/usage.sqlite`

This file never leaves your device. Uninstalling the app removes it.

## Network access

The app does not make any network requests. There are no analytics, crash reporters, update checkers, or telemetry services.

## Children's privacy

The app is not directed at children under 13 and collects no data from any user.

## Changes to this policy

If this policy changes, the updated version will appear at the same URL with a new "Last updated" date.

## Contact

For questions or issues: https://github.com/SSub-jun/MeltingClaude/issues
