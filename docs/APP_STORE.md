# ClaudesUsage — App Store Connect 등록 자료

App Store Connect 각 필드에 그대로 붙여넣을 수 있게 정리. URL 3개와 스크린샷만 직접 만들면 됨.

---

## 1. App Information

| 필드 | 값 |
|---|---|
| **Name** | `ClaudesUsage` |
| **Subtitle** (30자) | `Claude Code rate-limit watch` |
| **Bundle ID** | `com.byeonjunseob.ClaudesUsage` (예시 — 본인 도메인으로) |
| **Primary Category** | Developer Tools |
| **Secondary Category** | Productivity |
| **Age Rating** | 4+ |

---

## 2. Pricing & Availability

- **Price**: Free 권장 (시장 좁음 + OSS 대체재 존재 → free가 채택률↑)
- **Availability**: All countries
- **Pre-order**: No

---

## 3. Promotional Text (170자, 심사 없이 수정 가능)

```
Track your Claude Code usage live from the menu bar. See how close you are to the 5-hour rate limit before it cuts you off. 100% local — no servers, no API keys.
```

---

## 4. Description (4000자)

```
ClaudesUsage is a lightweight macOS menu bar app that shows your Claude Code rate-limit status in real time, so you stop getting cut off mid-task.

WHY IT EXISTS
Claude Code subscribers (Pro / Max) hit the 5-hour rolling rate limit constantly. The Anthropic Console shows usage after the fact — ClaudesUsage shows it now, in your menu bar, while you work.

WHAT IT DOES
• Reads your local Claude Code session logs (~/.claude/projects/) every few seconds
• Aggregates token usage across the current 5-hour rate-limit window
• Shows a tier icon (4 states: OK / Active / Heavy / At limit) at a glance
• Click for the full breakdown: 5-hour progress bar, last 7 days as a chart, today's totals, recent messages

WHO IT'S FOR
• Claude Code users (CLI or IDE extension — VS Code, Cursor, JetBrains)
• On a Pro / Max 5× / Max 20× subscription
• Who hit the rate limit often enough to want a heads-up

PRIVACY-FIRST DESIGN
• 100% local — no servers, no telemetry, no analytics
• No API keys, no sign-in, no account
• Your usage data lives only on your Mac, in the app's container
• No network requests are made by this app, ever

WHAT IT DOESN'T DO
• It can't predict the exact rate limit (Anthropic doesn't publish them) — thresholds are estimates you can switch by plan
• It only sees Claude Code usage — chat at claude.ai or the Claude desktop chat app are NOT tracked
• Mac only

REQUIREMENTS
• macOS 14 (Sonoma) or later
• Claude Code installed (so the session logs exist to read from)
```

---

## 5. Keywords (100자, 콤마 구분, 공백 없이)

```
claude,claudecode,anthropic,ai,llm,usage,ratelimit,menubar,developer,productivity,tokens,monitor
```

---

## 6. URLs (필수)

직접 만들어야 할 3개:

| 필드 | 용도 | 추천 |
|---|---|---|
| **Support URL** (필수) | 사용자 문의 / 이슈 | GitHub Issues 페이지 |
| **Marketing URL** (선택) | 랜딩 | GitHub repo README 또는 Notion 공개 페이지 |
| **Privacy Policy URL** (필수) | 개인정보 처리방침 | 아래 텍스트를 GitHub Pages 또는 Notion에 호스팅 |

---

## 7. Privacy Policy (그대로 호스팅)

```markdown
# Privacy Policy — ClaudesUsage

Last updated: 2026-04-26

ClaudesUsage is a macOS menu-bar app that visualizes your local Claude Code usage. This document explains exactly what the app does and does not do with your data.

## Data we collect

**None.** The app does not collect, transmit, or share any data with us or any third party.

## Data we read locally

The app reads session log files that Claude Code stores at:
- `~/.claude/projects/<project-hash>/<session-id>.jsonl`

These files are created by Claude Code (a separate product by Anthropic), not by us. We extract only the token-usage fields (`input_tokens`, `output_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`), the timestamp, the model name, and the project working directory.

## Data we store locally

The aggregated token data is saved to a local SQLite database inside the app's sandbox container on your Mac. This file never leaves your device. Uninstalling the app removes it.

## Network access

The app does not make any network requests. There are no analytics, crash reporters, update checkers, or telemetry services.

## Contact

For questions or issues: <YOUR_SUPPORT_URL>
```

---

## 8. App Privacy (App Store Connect → App Privacy 설문)

- **Do you or your third-party partners collect data from this app?**
  → **No**
- 후속 질문 자동 스킵
- 결과 표기: *Data Not Collected*

---

## 9. App Review Information

| 필드 | 값 |
|---|---|
| First Name / Last Name | (본인) |
| Phone | (본인) |
| Email | (본인) |
| **Sign-in required** | No |
| Demo Account | (비워둠) |

### Notes for Reviewer (그대로)

```
ClaudesUsage reads JSONL session log files that Claude Code (an AI coding tool by
Anthropic, https://claude.com/code) writes locally to ~/.claude/projects/.
It aggregates token counts for visualization in a menu-bar UI.

The app makes ZERO network requests — please verify with Network Link Conditioner
or by inspecting it with `nettop`. There are no accounts, sign-ins, APIs, or
servers involved.

Sandbox: enabled. On first run, the app prompts the reviewer to grant access to
~/.claude/ via an NSOpenPanel (security-scoped bookmark). After the folder is
selected once, the app reads only that folder.

To test:
1. Install Claude Code from https://claude.com/code and run it once to create
   a sample session at ~/.claude/projects/. (Or copy any sample .jsonl file into
   ~/.claude/projects/test/.)
2. Launch ClaudesUsage. Onboarding will detect Claude Code and prompt for the
   ~/.claude/ folder.
3. Click "Connect Claude Code" — the menu bar icon updates within seconds.

If the reviewer's machine doesn't have Claude Code, the onboarding "Skip for now"
button still allows entering the app, where the menu bar will show the OK state
(empty data).

Thank you!
```

---

## 10. Version 1.0 — What's New

```
Initial release.
• Menu-bar tier icon (4 states) driven by your current 5-hour Claude Code usage
• 7-day usage chart, today summary, recent messages
• Plan-based threshold presets (Pro / Max 5× / Max 20×)
• 100% local — no servers, no API keys
```

---

## 11. Screenshots (macOS 16:10, 최소 1, 최대 10)

권장 해상도: **2880 × 1800** (Retina 16-inch).

촬영 리스트 (5장 권장):

| # | 장면 | 캡션 후보 |
|---|---|---|
| 1 | 메뉴바 + popover (Heavy 상태) | *See your usage at a glance.* |
| 2 | Onboarding (플랜 선택) | *Pick your plan in 5 seconds.* |
| 3 | 7-day 차트 클로즈업 | *Spot your usage patterns.* |
| 4 | Settings (플랜 picker) | *Switch plans anytime.* |
| 5 | Dark mode | *Looks great day or night.* |

촬영 팁:
- 데스크톱 단색 배경 (회색 또는 그라디언트)
- 다른 메뉴바 앱 임시 숨김 (Bartender 등)
- popover 캡처: ⌘⇧5 → "Capture Selected Window"

---

## 12. App Store 진입을 위한 코드 변경 (참고만 — 본인이 처리)

App Store는 Sandbox 필수. 현재 OFF 상태이므로 출시 전:
1. `entitlements` → `com.apple.security.app-sandbox = true`
2. `~/.claude/` 접근: 첫 실행 시 NSOpenPanel 으로 사용자가 폴더 선택 → security-scoped bookmark 저장 → 다음 실행 시 `startAccessingSecurityScopedResource()` / `stop...()`
3. Bundle ID 정식화
4. Hardened Runtime ON (App Store는 자동 강제)

이 부분은 본인 경험으로 처리한다고 했으니 코드 작업 필요하면 별도 요청.
