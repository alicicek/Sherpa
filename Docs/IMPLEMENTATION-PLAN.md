# Implementation Plan

## M1 — Foundations & Theme
- Objective: Establish SwiftUI app shell with tab navigation, design tokens, and shared styling.
### Acceptance Criteria
- App launches to TabView containing placeholders for Habits, Focus, AI Coach, Insights, Leaderboard tabs with SF Symbols per PRD.
- Global theme (colors, corner radii, spacing) implemented via shared structs/constants referenced by views.
- UI respects safe areas, Dynamic Type, and ≥44pt tap targets per Apple HIG.
- Project builds and runs on iPhone 17 Pro simulator without runtime warnings.
### Build & Run
- `build_sim({ projectPath: "/Users/alicicek/Dev/sherpademo/sherpademo.xcodeproj", scheme: "sherpademo", simulatorName: "iPhone 17 Pro" })`
- `test_sim({ projectPath: "/Users/alicicek/Dev/sherpademo/sherpademo.xcodeproj", scheme: "sherpademo", simulatorName: "iPhone 17 Pro", extraArgs: ["-only-testing:sherpademoTests"] })`
- (Optional full sweep) drop `extraArgs` to include UI regression pass.
### Context7
- None required; rely on existing HIG references.

## M2 — Habit & Task Core
- Objective: Model habits/tasks with SwiftData and render Today list with swipeable calendar strip.
### Acceptance Criteria
- SwiftData models for Habit, HabitInstance, Task, RecurrenceRule with schedule generation logic aligned to PRD streak rules.
- Today screen displays combined list of scheduled habit/task instances with completion, skip-with-note, and add FAB entry points.
- Swipeable top calendar strip filters list by day and indicates completion status using 40% streak rule.
- Unit tests cover streak calculation, skip-with-note exclusion, and schedule edge cases.
- UI honors safe areas, Dynamic Type, ≥44pt tap targets per Apple HIG.
### Build & Run
- `build_sim({ projectPath: "/Users/alicicek/Dev/sherpademo/sherpademo.xcodeproj", scheme: "sherpademo", simulatorName: "iPhone 17 Pro" })`
- `test_sim({ projectPath: "/Users/alicicek/Dev/sherpademo/sherpademo.xcodeproj", scheme: "sherpademo", simulatorName: "iPhone 17 Pro", extraArgs: ["-only-testing:sherpademoTests"] })`
- (Optional full sweep) drop `extraArgs` to include UI regression pass.
### Context7
- None required; PRD defines behavior.

## M3 — Focus Sessions
- Objective: Implement Focus session timer with Live Activity stub and XP integration.
### Acceptance Criteria
- Focus tab presents session templates, start/stop controls, and session summary using SwiftUI animations respecting Reduce Motion.
- Timer continues across background, logs duration, and awards XP (+20 for ≥25 min) per PRD.
- Live Activity placeholder updates elapsed time; handles fallback if activity unavailable.
- Unit tests validate XP accrual and timer data persistence in SwiftData.
- UI adheres to Apple HIG safe areas, Dynamic Type, ≥44pt tap targets.
### Build & Run
- `build_sim({ projectPath: "/Users/alicicek/Dev/sherpademo/sherpademo.xcodeproj", scheme: "sherpademo", simulatorName: "iPhone 17 Pro" })`
- `test_sim({ projectPath: "/Users/alicicek/Dev/sherpademo/sherpademo.xcodeproj", scheme: "sherpademo", simulatorName: "iPhone 17 Pro", extraArgs: ["-only-testing:sherpademoTests"] })`
- (Optional full sweep) drop `extraArgs` to include UI regression pass.
### Context7
- None required; existing developer knowledge.

## M4 — AI Coach Experience
- Objective: Deliver AI Coach chat UI with suggestion chips and integration hooks.
### Acceptance Criteria
- AI Coach tab shows conversation timeline, typing indicator, quick-reply chips, and ability to insert/update habits/tasks per PRD.
- Stubbed CoachService abstracts network/API; handles optimistic updates and error fallbacks.
- Daily check-in flow triggers suggestions and XP (+10 for reflections) with data saved via SwiftData.
- UI follows Apple HIG for accessibility (Dynamic Type, VoiceOver labels, ≥44pt targets).
- Snapshot/unit tests validate CoachService adapter behavior and state updates.
### Build & Run
- `build_sim({ projectPath: "/Users/alicicek/Dev/sherpademo/sherpademo.xcodeproj", scheme: "sherpademo", simulatorName: "iPhone 17 Pro" })`
- `test_sim({ projectPath: "/Users/alicicek/Dev/sherpademo/sherpademo.xcodeproj", scheme: "sherpademo", simulatorName: "iPhone 17 Pro", extraArgs: ["-only-testing:sherpademoTests"] })`
- (Optional full sweep) drop `extraArgs` to include UI regression pass.
### Context7
- None required; future API specifics TBD.

## M5 — Leagues & Leaderboard
- Objective: Implement weekly league progression and leaderboard UI.
### Acceptance Criteria
- SwiftData aggregates weekly XP, focus minutes, and streak credit to determine ranks and resolve tie-breakers as per PRD.
- League tiers (Hilltop → Everest) displayed with contextual art/background adjustments.
- Leaderboard tab shows global sample plus friend list placeholder with promotion/demotion indicators.
- Weekly reset logic transitions tiers correctly and awards XP/streak bonuses.
- Unit tests cover tier transitions, tie-breakers, and weekly reset behavior.
- UI complies with Apple HIG safe areas, Dynamic Type, ≥44pt tap targets.
### Build & Run
- `build_sim({ projectPath: "/Users/alicicek/Dev/sherpademo/sherpademo.xcodeproj", scheme: "sherpademo", simulatorName: "iPhone 17 Pro" })`
- `test_sim({ projectPath: "/Users/alicicek/Dev/sherpademo/sherpademo.xcodeproj", scheme: "sherpademo", simulatorName: "iPhone 17 Pro", extraArgs: ["-only-testing:sherpademoTests"] })`
- (Optional full sweep) drop `extraArgs` to include UI regression pass.
### Context7
- None required; PRD specifies logic.

## M6 — Onboarding & Paywall
- Objective: Build onboarding flow, notification priming, and StoreKit paywall for Sherpa Pro.
### Acceptance Criteria
- Onboarding captures name, avatar, goal quiz, notification priming, signature, and initial habit/task creation with progress indicators.
- Paywall screen presents freemium vs Sherpa Pro pricing, supports purchase, restore, and free trial via StoreKit 2.
- Notification prompts follow Apple HIG timing guidance; fallback paths for denied permissions handled.
- Subscription state updates across app within 3s, reflecting limitations for freemium users.
- UI respects safe areas, Dynamic Type, ≥44pt touch targets; VoiceOver labels present.
- Integration tests (or unit tests with StoreKitTest) cover purchase, restore, and entitlement gating.
### Build & Run
- `build_sim({ projectPath: "/Users/alicicek/Dev/sherpademo/sherpademo.xcodeproj", scheme: "sherpademo", simulatorName: "iPhone 17 Pro" })`
- `test_sim({ projectPath: "/Users/alicicek/Dev/sherpademo/sherpademo.xcodeproj", scheme: "sherpademo", simulatorName: "iPhone 17 Pro", extraArgs: ["-only-testing:sherpademoTests"] })`
- (Optional full sweep) drop `extraArgs` to include UI regression pass.
### Context7
- Potentially reference StoreKit 2 docs if API changes; fetch via Context7 when implementing.

## M7 — Insights, Polish & QA
- Objective: Deliver insights dashboard, accessibility polish, and QA hardening.
### Acceptance Criteria
- Insights tab displays weekly heatmap, trend charts, and AI pattern card sourced from SwiftData aggregates.
- Accessibility sweep completed: VoiceOver, Dynamic Type XL, Reduce Motion, color contrast ≥4.5:1 documented.
- Confetti and animations respect Reduce Motion setting per HIG.
- Automated tests expanded to cover insights calculations, notification scheduling, and critical navigation flows.
- App passes manual QA checklist from PRD section 19, including streak edge cases and purchase scenarios.
### Build & Run
- `build_sim({ projectPath: "/Users/alicicek/Dev/sherpademo/sherpademo.xcodeproj", scheme: "sherpademo", simulatorName: "iPhone 17 Pro" })`
- `test_sim({ projectPath: "/Users/alicicek/Dev/sherpademo/sherpademo.xcodeproj", scheme: "sherpademo", simulatorName: "iPhone 17 Pro", extraArgs: ["-only-testing:sherpademoTests"] })`
- (Optional full sweep) drop `extraArgs` to include UI regression pass.
### Context7
- None required; use HIG and PRD guidance already cited.
