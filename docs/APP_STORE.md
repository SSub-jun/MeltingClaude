# MeltingClaude — App Store Connect 출시 자료

마지막 갱신: 2026-05-02
복사·붙여넣기 전용 문서. 영문 코드블록은 그대로 App Store Connect 폼에 넣고, 한글은 참고만.

---

## ⚠️ 제출 전 코드 변경 필수 (선행 작업)

App Store 는 **Sandbox ON 강제**. 현재 OFF 라 그대로 제출하면 Apple Review 자동 거부.
다음 작업이 끝나야 이 메타데이터 제출 의미 있음:

1. `MeltingClaude.entitlements` 의 `com.apple.security.app-sandbox` → `true`
2. `~/.claude/projects/` 접근: 첫 실행 시 `NSOpenPanel` 으로 사용자가 폴더 선택 → security-scoped bookmark 저장 → 다음 실행 시 `startAccessingSecurityScopedResource()` / `stop...()` 로 감싸서 읽기
3. SQLite 경로: 자동으로 sandbox container (`~/Library/Containers/com.byeonjunseob.MeltingClaude/Data/Library/Application Support/MeltingClaude/`) 로 이동 — 코드 변경 없이 적용됨
4. Hardened Runtime: App Store 제출 시 자동 강제 (Xcode 설정에서 켜져 있는지 확인)

> 이 코드 작업도 도와줄 수 있음. 별도 요청 주면 진행.

---

## 1. App Information

| 필드 | 값 |
|------|------|
| **App Name** (30자) | `MeltingClaude` |
| **Subtitle** (30자) | `Claude Code rate-limit watch` |
| **Bundle ID** | `com.byeonjunseob.MeltingClaude` |
| **SKU** | `meltingclaude-001` (자유, App Store 내부 식별용) |
| **Primary Category** | Developer Tools |
| **Secondary Category** | Productivity |
| **Age Rating** | 4+ |
| **Content Rights** | "Does not contain, show, or access third-party content" |

---

## 2. Pricing & Availability

- **Price**: Free
- **Availability**: All countries and regions
- **Pre-order**: No
- **App Distribution Methods**: App Store
- **Educational Discount**: N/A (free)

---

## 3. Promotional Text (170자, 심사 없이 언제든 수정 가능)

```
Track your Claude Code usage live from the menu bar. See how close you are to the 5-hour rate limit before it cuts you off. 100% local — no servers, no API keys.
```

---

## 4. Description (최대 4000자)

```
MeltingClaude is a lightweight macOS menu bar app that shows your Claude Code rate-limit status in real time, so you stop getting cut off mid-task.

WHY IT EXISTS
Claude Code subscribers (Pro / Max) hit the 5-hour rolling rate limit constantly. The Anthropic Console shows usage after the fact — MeltingClaude shows it now, in your menu bar, while you work.

WHAT IT DOES
• Reads your local Claude Code session logs (~/.claude/projects/) every few seconds
• Aggregates token usage across the current 5-hour rate-limit window
• Shows an animated tier icon (4 states: OK / Active / Heavy / At limit) at a glance — the character starts intact and progressively melts as you approach the cap
• Click the icon for the full breakdown:
  - Current 5-hour block: progress bar + tokens used / cap + countdown to reset
  - Last 7 days: daily bar chart, color-coded by tier
  - Today: total tokens + message count
  - Recent: latest few messages (collapsible)

PLAN-AWARE THRESHOLDS
Pick your subscription (Pro / Max 5× / Max 20×) and the app applies sensible threshold estimates. Not on a standard plan? Switch to Custom and set your own Low / Mid / High caps directly in Settings.

PRIVACY-FIRST DESIGN
• 100% local — no servers, no telemetry, no analytics
• No API keys, no sign-in, no account
• Your usage data lives only on your Mac, in the app's sandbox container
• The app makes ZERO network requests, ever

WHO IT'S FOR
• Claude Code users (CLI or IDE extension — VS Code, Cursor, JetBrains)
• On a Pro / Max 5× / Max 20× subscription
• Who hit the rate limit often enough to want a heads-up

WHAT IT DOESN'T DO
• It can't predict the exact rate limit — Anthropic doesn't publish them, so thresholds are estimates you can switch by plan or override in Custom mode.
• It only sees Claude Code usage. Chat at claude.ai or the Claude desktop chat app are NOT tracked (different products, no local logs).
• Per-device tracking only. If you use Claude Code on multiple Macs with the same account, MeltingClaude on each Mac shows only that Mac's activity. Account-wide multi-device sync is being explored for a future release.
• Mac only.

REQUIREMENTS
• macOS 14 (Sonoma) or later
• Claude Code installed (so the session logs exist to read from)

NOT AFFILIATED WITH ANTHROPIC
MeltingClaude is an independent third-party tool built by a Claude Code user, for Claude Code users. "Claude" and "Claude Code" are products of Anthropic, PBC.
```

---

## 5. Keywords (100자, 콤마 구분, 공백 X)

```
claude,claudecode,anthropic,ai,llm,usage,ratelimit,menubar,developer,productivity,tokens,monitor
```

(현재 96자 — 여유 4자)

---

## 6. URLs (3개 필수/선택)

| 필드 | 필수 | 추천 값 |
|------|------|---------|
| **Support URL** | 필수 | `https://github.com/SSub-jun/MeltingClaude/issues` |
| **Marketing URL** | 선택 | `https://github.com/SSub-jun/MeltingClaude` |
| **Privacy Policy URL** | 필수 | (아래 7번 텍스트를 GitHub Pages 또는 Notion 공개 페이지에 호스팅 후 그 URL) |

### Privacy Policy 호스팅 빠른 옵션
- **GitHub Pages**: repo Settings → Pages → Branch `main` → `/docs` 폴더 활성화. 그러면 `https://ssub-jun.github.io/MeltingClaude/PRIVACY.html` 같은 URL 자동 생성. (PRIVACY.md 파일을 docs/에 추가)
- **Notion 공개 페이지**: 새 페이지 → 아래 텍스트 붙이고 "Publish to web" → 생성된 URL 사용

---

## 7. Privacy Policy (그대로 호스팅)

```markdown
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
```

---

## 8. App Privacy 설문 (App Store Connect → App Privacy)

- **Q: Do you or your third-party partners collect data from this app?**
  → **No**
- 후속 질문 자동 스킵
- 결과 표기: **Data Not Collected**

---

## 9. Export Compliance (App Store Connect → App Information)

- **Q: Does your app use encryption?**
  → **No**

(앱이 네트워크 요청도 안 하고, 표준 OS encryption (HTTPS, FileVault 등) 외에 암호화 라이브러리도 안 씀. → 수출 규제 무관)

---

## 10. App Review Information

| 필드 | 값 |
|------|------|
| **First Name** | 변 (또는 영문 이름) |
| **Last Name** | 준섭 (또는 영문 성) |
| **Phone Number** | (본인 번호) |
| **Email Address** | quswnstjq93@gmail.com |
| **Sign-in required** | No |
| **Demo Account** | (비워둠) |
| **Attachment** | (없음) |

### Notes for Reviewer (그대로 붙여넣기)

```
MeltingClaude reads JSONL session log files that Claude Code (an AI coding tool by Anthropic, https://claude.com/code) writes locally to ~/.claude/projects/. It aggregates token counts and visualizes them in a menu-bar UI.

The app makes ZERO network requests — please verify with Network Link Conditioner or by inspecting it with `nettop`. There are no accounts, sign-ins, APIs, or remote servers involved.

Sandbox: enabled. On first run the app shows an onboarding window. After the user clicks "Connect Claude Code" an NSOpenPanel prompts them to grant access to the ~/.claude/ folder. The app stores a security-scoped bookmark and from that point only reads files inside that folder.

To test:
1. Install Claude Code from https://claude.com/code and run it once to create a sample session at ~/.claude/projects/. (Or copy any sample .jsonl file into ~/.claude/projects/test/.)
2. Launch MeltingClaude. Onboarding will detect Claude Code and prompt for the ~/.claude/ folder.
3. Click "Connect Claude Code", select the folder in the NSOpenPanel — the menu bar icon updates within seconds.

If the reviewer's machine doesn't have Claude Code, the onboarding "Skip for now" button still allows entering the app, where the menu bar will show the OK state (empty data).

Thank you!
```

---

## 11. Version 1.0 — What's New

```
Initial release.

• Animated menu-bar tier icon — character progressively melts as you near your 5-hour rate limit
• 7-day usage chart, today summary, recent messages
• Plan-based threshold presets (Pro / Max 5× / Max 20×) plus a Custom mode for manual caps
• 100% local — no servers, no API keys, no telemetry
```

---

## 12. Screenshots (macOS, 16:10)

권장 해상도: **2880 × 1800** (Retina 16-inch). 최소 1장, 최대 10장.

촬영 리스트 (5장 권장):

| # | 장면 | 캡션 후보 (영문) |
|---|------|------------------|
| 1 | 메뉴바 + popover (Heavy 상태, 차트 잘 보임) | *See your usage at a glance.* |
| 2 | Onboarding (플랜 선택 화면) | *Pick your plan in 5 seconds.* |
| 3 | 7-day 차트 클로즈업 | *Spot your usage patterns.* |
| 4 | Settings — Custom 모드 (TextField 3개 보임) | *Set your own caps in Custom mode.* |
| 5 | Dark mode 메뉴바 + popover | *Looks great day or night.* |

촬영 팁:
- 데스크톱 단색 배경 (회색 또는 그라디언트)
- 다른 메뉴바 앱 임시 숨김 (Bartender 등)
- popover 캡처: ⌘⇧5 → "Capture Selected Window"
- 메뉴바 캐릭터 애니메이션 도중 캡처되면 어떤 프레임이든 OK (정적 스크린샷이라 움직임 안 보임 — Description 으로 보완)

---

## 13. App Icon

이미 `Assets.xcassets/AppIcon.appiconset` 에 1024 포함 10 사이즈 등록됨. 추가 작업 없음. App Store Connect 자동 추출.

---

## 14. App Store Connect 제출 흐름 (참고)

1. **Apple Developer Program 가입** ($99/yr) — 미완 상태면 선결
2. **Bundle ID 등록**: developer.apple.com → Identifiers → `com.byeonjunseob.MeltingClaude` 등록
3. **App Store Connect 에서 새 App 생성**: Name `MeltingClaude`, Bundle ID 위 ID 선택, SKU `meltingclaude-001`
4. **Sandbox 코드 변경 + 빌드** (위 ⚠️ 섹션)
5. **Xcode → Product → Archive → Distribute App → App Store Connect → Upload**
6. **App Store Connect 에서**:
   - Privacy Policy URL 등록 (호스팅 완료 후)
   - Description / Keywords / Promotional Text 입력 (위 4·5·3번)
   - Screenshots 5장 업로드
   - App Privacy 설문 = Data Not Collected
   - Export Compliance = No encryption
   - Review Information 입력 (위 10번)
   - Version 1.0 What's New 입력 (위 11번)
7. **Submit for Review** — 평균 24~48시간

---

## 15. 거부 시 자주 걸리는 포인트 (예방)

| 위험 | 대응 |
|------|------|
| "Claude" 상표 사용 | 앱 이름은 MeltingClaude. Description 끝에 "Not affiliated with Anthropic" 명시 (위 4번에 포함됨). 불안하면 keywords 에서 `claude` 빼고 `claudecode` 만 남기기 |
| 사용자 폴더 접근 (`~/.claude/`) 정당성 부족 | App Review Notes 에 NSOpenPanel 흐름 + 테스트 절차 명시 (위 10번에 포함됨) |
| Privacy Policy URL 404 | 제출 전 URL 직접 클릭해서 200 응답 확인 |
| Demo 데이터 부재로 reviewer 가 빈 화면만 봄 | Notes 에 "Skip for now" 버튼 안내 (위 10번에 포함됨) |
| 외부 결제 / 구독 / 광고 (없음) | 해당 없음 — Free, no IAP, no ads |
