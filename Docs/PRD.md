Here’s your updated **pre.md** with the new Tasks, suggestions, scheduling/recurrence, units, gestures, timer/notes/stats modal, skip-with-note + AI, and the swipeable top calendar — all integrated in place and only changing what was necessary.

---

# Sherpa — iOS Habit App PRD (v1.1)

> A fun, modern, HIG-compliant habit app with gamification, Focus, AI Coach, and weekly mountain-themed leagues.

---

## 1) Product Overview

**Problem**: People start habit apps and churn because they feel lonely, unmotivated, and overwhelmed.
**Solution**: Sherpa uses *gamified leagues + Focus sessions + a friendly AI Coach* to keep users progressing.
**Platforms**: iOS (iPhone first).
**Business model**: Freemium with **Sherpa Pro** subscription (£5.99/mo, £49.99/yr, free trial).

[Assumption] iOS 17+ target; iOS 18+ optimisations where available.

---

## 2) Brand & Tone (Foundations the AI coder should encode)

* **Adjectives**: soft, fun, modern, friendly, interactive.
* **Mascot**: Sherpa Goat appears in empty states, success, coach avatar, onboarding.
* **Typography**: SF Pro; Headlines (Bold/Semibold), Body (Regular).
* **Color tokens (hex)**

  * `--color-primary: #58B62F`
  * `--color-accent-1: #46A8E0`
  * `--color-accent-2: #F5C34D`
  * `--color-success: #2FAE60`
  * `--color-warning: #E85C4A`
  * **Neutral 9-step** (light → dark): `#F6F7F8, #EDEFF1, #DFE3E6, #CBD2D8, #B1BAC2, #939EA8, #707C87, #4F5963, #2C343B`
* **Shapes**: 20–24pt corner radii; soft shadows; generous spacing.
* **Accessibility**: Dynamic Type; 44pt min targets; contrast ≥ 4.5:1; VoiceOver labels.
* **Motion**: gentle, respect Reduce Motion; confetti on day-complete (particles in `#F5C34D`).

---

## 3) Users & Value

* **Audience**: Gen Z (14–30), tried tracking before and quit.
* **Outcome**: Build routines, uncover self-sabotage patterns, feel happier.
* **Differentiator**: **Leagues + Focus + AI Coach** tightly integrated.

---

## 4) Information Architecture & Navigation

* **Tab bar (5)**:

  1. **Habits** (Home, cabin icon)
  2. **Focus** (binoculars)
  3. **AI Coach** (center): chat bubble with Sherpa peeking over it
  4. **Insights** (chart)
  5. **Leaderboard** (mountain/trophy)
* **Home top bar**: left avatar → Profile/Settings; right streak flame + count.
* **Top calendar**: a **swipeable calendar strip** above the list shows recent days with a clear **completed-day** indicator (filled when the day qualifies; see Streaks).

  * Tapping a day focuses the list to that date’s items.
* **Global FAB**: “+” to add **habit or task** (safe-area aware).
* **HIG**: Safe areas; Auto Layout; Dynamic Type; conservative tap targets.

[Assumption] Use SF Symbols initially; custom iconography later.

---

## 5) Core Game & Progression Rules

### 5.1 Streaks

* A day **counts toward streak** if **≥ 40%** of *scheduled habits* for that day are completed. (Tasks do **not** affect streak credit.)
* **Skip with note rule**: if a habit instance is explicitly **skipped with a note**, it is excluded from both the numerator and denominator for that day’s 40% check. Skipping **without** a note does **not** exclude it.

### 5.2 XP

* Earn XP for:

  * Completing a **full qualifying day** (≥ 40%) → **+50 XP**
  * Completing an individual **habit** instance → **+10 XP**
  * Completing an individual **task** instance → **+10 XP**
  * Morning reflection → **+10 XP**
  * Night reflection → **+10 XP**
  * Completing a Focus session (≥ 25 min) → **+20 XP**
    [Assumption] Values above; tune via remote config later.

### 5.3 Leagues (weekly “seasons” reset Mondays 00:00 local)

* Tiers: **Hilltop → Base Camp → Mont Blanc → K2 → Everest**.
* Weekly ladder per league using **total XP** earned that week.
* **Promotion**: ranks **1–12** move up one tier next week.
* **Stay**: ranks **13–15** remain.
* **Demotion**: ranks **≥16** move down one tier.
* Ties broken by **(1) days with streak credit, (2) total Focus minutes, (3) join time**.
* Home header art & background vary by current league.

[Assumption] New users start at **Base Camp**.

---

## 6) Key Features & Flows (MVP)

### 6.1 Onboarding (5–7 screens, fast)

1. **Benefit carousel** (3 slides, swipe)
2. **Name entry & avatar pick** (first name only)
3. **Quick quiz** (goal focus: sleep, fitness, study, wellness)
4. **Notifications opt-in priming** → system prompt
5. **Paywall**: value props + **trial** or continue **Freemium**
6. **Commit screen**: **sign your name** to commit (draw signature)
7. **Create first habit/task** (wizard entry point)

> Best practices: minimal fields; clear progress; skip options; ethical paywall; restore purchases.

### 6.2 Create Habit/Task Wizard (3–4 steps)

Users can add either a **Habit** or a **Task**. A **Suggestions** step appears first with editable presets.

**Flow**

1. **Choose type**: Habit ▸ Task (with brief tooltip explaining difference).
2. **Suggestions** (chips/list; e.g., “Brush teeth 2×/day”, “Read 10 pages”, “Submit assignment”). Selecting one **pre-fills** fields; user can edit.
3. **Basics**: name, icon, color, **unit** (see Units below).
4. **Schedule & Start** (sheet/modal):

   * **Start**: **Today** (default) / **Tomorrow** / **On a date…**
   * **Time**: time picker (optional).
   * **Notify**: toggle.
   * **Repeat**:

     * **Tasks** default: **Does not repeat**.
     * **Habits** default: **Daily**.
     * Presets: **Every day**, **Every weekday (Mon–Fri)**, **Every week on Wed**, **Every month on the 15th**, **Custom…**
   * **Ends**: Never / On date / After N occurrences.
   * **Custom…** opens a **recurrence sheet** (see below).
5. **Review** → Confirm; creates initial schedule instances for the next 14 days.

**Units (per item)**

* **count, sec, min, hours, km, steps, kcal, g, ml, oz**

  * Example: “Run **10,000 steps** **weekly** on Mon/Wed/Fri.”
  * Display rules ensure correct per-day/per-period aggregation.

**Custom Recurrence Sheet (slides up)**

* **Tabs**: Daily | Weekly | Monthly

  * **Daily**: “Every **__** day(s)” (swipe/stepper to choose interval).
  * **Weekly**: “Every **__** week(s) on [Mon…Sun]” (multi-select days).
  * **Monthly**: “Every **__** month(s) on [1…31]” (multi-select days).
* Footer shows a **human-readable summary** (e.g., “Every 2 weeks on Tue & Thu, ends on 30 Nov”).

### 6.3 Home / Today

* **Top**: league art, XP bar, streak flame + count. **Below**: **swipeable calendar strip** showing recent days with a completed-day indicator (qualifies when ≥40% habits completed).
* **List**: combined **Habits and Tasks** for the selected day (Habits shown first by default).
* **Gestures & interactions**:

  * **Hold & swipe right** on an item to **increment** value continuously (haptic ticks).
  * **Tap “+”** increments by the item’s step (e.g., +1, +5min; configurable per item).
  * **Multi-times-per-day** habits (e.g., “Brush teeth 2×”): tap the check multiple times or swipe to fill required count.
  * **Tap the row (not the +)** to open the **Item Detail Modal**:

    * If **time-based unit** (sec/min/hours): show **Start Timer** (mini timer/stopwatch). Stopping saves the logged time to the instance.
    * Otherwise show **+ / –** stepper for precise adjustments.
    * **Actions**: **Add note**, **View statistics** (mini chart: last 7/30 days), **⋯** (Edit, Archive, Delete).
    * **Skip today**: prompts for an optional note and offers **“Talk to AI Coach”** to replan or suggest a lighter alternative.
* **Reflection cards**: Morning/Night (optional).
* **Celebration**: When the day qualifies for streak, show particles + haptics.

### 6.4 Daily Check-In (AI-assisted)

* Coach greets with contextual prompt e.g. (“How did you sleep?”).
* Quick-reply chips: Sleep quality / Focus area / Tasks.
* Coach can surface **suggested habits/tasks** from the same **Suggestions** library; tapping quick-adds (opens Review).
* Coach proposes **today’s plan re-ordering**; user confirms.

### 6.5 Focus Sessions

* Pomodoro defaults: 25/5; custom allowed.
* Start, pause, end; haptics at transitions.
* **App blocking** (Screen Time API) during session.
* Summary: total focus minutes, suggested next session.

[Assumption] If Screen Time entitlement not approved, ship with “soft block” (full-screen blocker + reminders).

### 6.6 Insights

* Weekly summary cards, calendar heatmap, adherence %, focus minutes, screen time (if permissioned).
* AI pattern card: “We noticed you… try …”.

### 6.7 Leaderboard

* Weekly season board within current league: user rank, promotion/demotion rules visible.
* Toggle: Friends / Global.
  [Assumption] “Friends” via contacts or share code in v1 (simple code share).

### 6.8 Profile / Settings

* Account, Notifications, Theme (Light/Dark/System), Data Export (CSV), Delete Account.
* Social/Leaderboard opt-in; anonymous by default.

### 6.9 Paywall

* Clear features grid; prices; free trial; restore purchases; link to Terms/Privacy.
* Optional “Chat to AI Coach” when user taps “Why cancel?”

---

## 7) Non-Goals (MVP)

* Multi-device sync beyond iPhone (iPad/Mac later).
* Complex social graphs (followers, DMs).
* Custom automation/integrations (Shortcuts, HealthKit except steps if easy).
* Web client.
* Streak freezes/“vacation mode”.

---

## 8) Architecture & Tech

* **Language/UI**: Swift + **SwiftUI**; MVVM; async/await.
* **Local data**: **SwiftData** models + background context for writes.
  [Assumption] Enable iCloud sync via CloudKit containers in v1.1; MVP ships local with export.
* **Purchases**: StoreKit 2 (subscriptions + introductory offer/free trial).
* **Push**: Local notifications at first; remote optional later.
* **Screen Time / App Blocking**: FamilyControls + DeviceActivity + ManagedSettings with required entitlements; fallback soft block.
* **AI Coach**: abstraction `CoachService` with `generateReply(context:)` + `proposePlan(today:)`.
  [Assumption] Use hosted LLM API; prompts constrained to non-clinical guidance.
* **Theming/Tokens**: central `DesignTokens.swift` for colors, spacing, radii, typography.
* **Analytics**: light-weight event logger with batch upload (background task) or deferred.
* **Feature flags/Remote config**: simple JSON fetched at launch + cached.
* **SuggestionsService** (MVP local JSON): suggested templates (name, unit, sample schedule) used in onboarding, wizard, and coach.
* **Recurrence engine**: supports **Daily/Weekly/Monthly** with **intervals**, **selected days**, and **end conditions** (never / on date / after N).

---

## 9) Data Model (SwiftData sketch)

```swift
@Model final class User {
  @Attribute(.unique) var id: UUID
  var firstName: String
  var avatarIndex: Int
  var currentLeague: LeagueTier
  var createdAt: Date
  var proEntitlement: ProEntitlement? // optional
}

enum LeagueTier: Int, Codable { case hilltop, baseCamp, montBlanc, k2, everest }

enum TrackableKind: String, Codable { case habit, task }

enum GoalPeriod: String, Codable { case day, week, month }

enum GoalUnit: String, Codable {
  case count, sec, min, hours, km, steps, kcal, g, ml, oz
}

struct RecurrenceRule: Codable {
  enum Freq: String, Codable { case none, daily, weekly, monthly }
  var freq: Freq                  // tasks default .none; habits default .daily
  var interval: Int?              // e.g., every 2 weeks
  var byWeekdays: [Int]?          // 1=Mon ... 7=Sun
  var byMonthDays: [Int]?         // 1...31
  enum End: Codable { case never, onDate(Date), afterCount(Int) }
  var end: End
}

@Model final class Habit { // kept name for minimal change; represents habit or task via `kind`
  @Attribute(.unique) var id: UUID
  var userId: UUID
  var kind: TrackableKind         // .habit or .task
  var name: String
  var icon: String                // SF Symbol name
  var colorHex: String
  var goalPeriod: GoalPeriod      // day/week/month
  var unit: GoalUnit
  var target: Double              // per period (e.g., 2 checks/day; 10 pages/day)
  var recurrence: RecurrenceRule  // see above
  var startDate: Date
  var startTime: Date?            // time-of-day
  var notify: Bool
  var isArchived: Bool
  var createdAt: Date
}

@Model final class HabitInstance {
  @Attribute(.unique) var id: UUID
  var habitId: UUID
  var date: Date                  // local day
  var progress: Double            // 0..target
  var completed: Bool
  var skipped: Bool               // true if explicitly skipped
  var note: String?               // optional note for this instance
}

@Model final class FocusSession {
  @Attribute(.unique) var id: UUID
  var userId: UUID
  var startedAt: Date
  var endedAt: Date?
  var intendedMinutes: Int
  var actualMinutes: Int
  var appBlockingEnabled: Bool
}

@Model final class XPEvent {
  @Attribute(.unique) var id: UUID
  var userId: UUID
  var date: Date
  var points: Int
  var reason: XPReason // dayComplete, habitComplete, taskComplete, reflection, focus
}

enum XPReason: String, Codable {
  case dayComplete, habitComplete, taskComplete, reflectionMorning, reflectionNight, focus
}

@Model final class LeagueWeeklyStanding {
  @Attribute(.unique) var id: UUID
  var userId: UUID
  var league: LeagueTier
  var weekOf: Date // Monday
  var totalXP: Int
  var rank: Int?
}

@Model final class Reflection {
  @Attribute(.unique) var id: UUID
  var userId: UUID
  var date: Date
  var kind: ReflectionKind // morning/night
  var note: String?
  var sleepQuality: Int? // 1..5
}
enum ReflectionKind: String, Codable { case morning, night }
```

---

## 10) Business Logic (Deterministic Functions)

* **`qualifiesForStreak(day:)`**

  * Let `scheduled = count(HabitInstance where date==day AND parent.kind==.habit)`
  * Let `completed = count(where completed==true AND parent.kind==.habit)`
  * Let `excluded = count(where skipped==true AND note != nil AND parent.kind==.habit)`
  * Return `(completed) / max(1, scheduled - excluded) >= 0.4`.

* **`computeXP(eventsForDay:)`** sum `XPEvent.points`.

* **Weekly ladder job (runs Monday 00:05)**

  * Group users by `LeagueTier`; sort by total XP that week; assign ranks; write promotion/demotion for next week; move users’ league; reset `totalXP` counters.

[Assumption] Ladder job is local client-side for MVP (deterministic) with global board simulated via “global sample”. Real backend later.

---

## 11) Monetisation

* **Products**:

  * `pro.monthly` £5.99/month (7-day trial)
  * `pro.yearly` £49.99/year (14-day trial)
* **Pro unlocks**: unlimited habits, full AI Coach, app blocking, AI Insights.
* **Freemium limits**: up to 3 habits, 1 Focus template, 3 AI messages/day.
* **StoreKit 2** flows: purchase, restore, subscription status, intro eligibility.

[Assumption] Trial lengths as above; can be tuned later.

---

## 12) Privacy, Security, Offline

* **Offline-first**: all core actions work offline; sync when online.
* **Export**: CSV for habits, focus sessions, reflections, XP.
* **Delete Account**: wipes local data; if cloud later, purge remote.
* **AI guardrails**: non-clinical; include canned “seek professional help” responses for red-flag keywords.

---

## 13) Notifications & Widgets

* **Local notifications**: per-item reminders honour **start date/time**, **recurrence**, and the **notify** toggle; gentle tone; smart nudge windows (morning/evening).
* **Focus Live Activity**: timer countdown on Lock Screen / Dynamic Island.
* **Weekly digest**: “Season ending in 24h—push for promotion.”

[Assumption] Widgets (Medium) for today’s habits + streak shown in v1.1.

---

## 14) Analytics (MVP)

Events (string IDs):

* `onboarding_complete`, `paywall_view`, `purchase_success`, `habit_create`, `habit_complete`, `day_streak_credit`, `focus_start`, `focus_complete`, `ai_message_sent`, `ai_suggestion_applied`, `season_rank_assigned`.
* **Added for tasks & interactions**: `item_create` (props: kind, unit, recurrence), `item_increment` (delta, via: tap_plus | hold_swipe | timer), `item_skip` (has_note), `item_note_add`, `suggestion_tapped`, `timer_start`, `timer_complete`.

Properties: user_id (anon), league, counts, durations, free/pro flag.
[Assumption] Store locally + batched upload; respect “Limit Ad Tracking”.

---

## 15) Design System Deliverables (to build in Figma and mirror in code)

* **Pages**: Cover, Foundations, Components, Patterns, Screens, Prototype, README.
* **Tokens**: colors, radii (8/12/20/24), spacing (4/8 grid), shadows, opacity, borders, type scale.
* **Components (variants)**:

  * Tab bar (5 icons as above, center chat bubble smaller with mascot peeking)
  * Nav bars, Buttons (primary/secondary/ghost/loading/disabled)
  * **Top Swipeable Calendar** (day chips with completed indicator)
  * **Suggestions List/Chips**
  * **Schedule & Start Sheet** (Today/Tomorrow/On a date…, Time, Notify, Repeat, Ends)
  * **Custom Recurrence Sheet** (Daily/Weekly/Monthly with interval & selectors + summary)
  * Cards: Habit/Task, Insight, Leaderboard row
  * Inputs: text, pickers, **unit selector**, stepper
  * Toggles/segmented/pills
  * Progress/XP bar + streak flame
  * Toasts/banners/modals/sheets
  * Coach chat bubbles + chips + typing indicator
  * **Item Detail Modal** (timer/stepper, notes, stats, ⋯ menu incl. Archive/Delete/Skip)
  * Timer module (start/pause/complete)
  * Paywall module (pricing, bullet points, CTA)
  * Empty/loading/error with mascot

---

## 16) Screens (Artboards 2556×1179 @460ppi)

1. Welcome carousel
2. Name & avatar
3. Quick quiz (goals)
4. Notification priming
5. Paywall (trial + freemium)
6. **Home (Today)** with league header, streak, XP, **swipeable calendar**, combined Habits/Tasks list, FAB
7. **Create Habit/Task** (stepper with Suggestions → Basics → Schedule & Start → Review)
8. Daily Check-In (AI Coach proposal; can add suggested habits/tasks)
9. Focus Timer (active) — also used when starting a time-based item from its modal
10. Focus Complete (summary)
11. Insights (week + heatmap + AI pattern)
12. Leaderboard (weekly season + rules)
13. Profile/Settings (export/delete/account)
14. Day Complete Celebration (particles → XP bar; streak +1)

**Micro-interactions**: button spring on primary CTAs; XP particles; typing indicator in coach; haptics on focus start/end; haptic ticks during hold-to-increment.

---

## 17) Icons (SF Symbols for MVP)

* Home: `house.fill` (style rounded via mask) → visually a **cabin** later.
* Focus: `binoculars.fill`
* AI Coach: `ellipsis.bubble.fill` (with custom overlay of mascot peeking)
* Insights: `chart.bar.fill`
* Leaderboard: `mountain.2.fill` (or `trophy.fill` if mountain unavailable)
* Streak flame: `flame.fill`
* FAB: `plus`

---

## 18) Acceptance Criteria (per feature)

**Onboarding**

* Completing onboarding stores `User.firstName`, creates `onboarding_complete` event, optionally schedules default reminders.
* Signature captured as vector or PNG; stored locally.

**Create Habit/Task**

* Defaults: Task = **Does not repeat**; Habit = **Daily**; **Today** preselected; **Notify** off by default.
* Custom recurrence (Daily/Weekly/Monthly with intervals and day selectors) produces the correct next **14** instances and a human-readable summary.
* Units include: count, sec, min, hours, km, steps, kcal, g, ml, oz.

**Home**

* **Top calendar** shows completed-day state based on **≥40% of scheduled habits**.
* Hold & swipe increments value with haptics; releasing commits.
* Tapping + adds exactly one unit step; multi-tap handles multi-times-per-day habits.
* Tapping row opens modal; time-based items show **Start Timer**; saving logs to `HabitInstance`.
* “Skip” sets `skipped=true`, prompts for note, offers AI Coach; day-complete calculation updates immediately.

**Focus**

* Timer continues in background; Live Activity shows remaining time.
* On completion, `FocusSession` saved; XP added if ≥25 min.

**AI Coach**

* Sends prompt with context (today’s schedule, streak, last focus); returns reply under 2s (show typing indicator until in).
* Applying a suggestion (e.g., reorder plan or quick-add from suggestions) updates Home immediately.

**Leaderboard**

* Weekly rank visible; promotion/demotion labels shown Sun 23:00–Mon 00:00 (local).
* After reset, user’s league adjusts as per rules.

**Paywall**

* Purchases succeed; subscription state reflected within 3s; restore works.

---

## 19) QA Test Plan (high-level)

* **Unit**: streak calculation (incl. skip-with-note exclusion), XP accrual, scheduling edge cases (no habits today; timezone changes).
* **Recurrence**: daily/weekly/monthly with intervals; ends on date/after N.
* **UI**: Dynamic Type sizes; RTL mirroring; VoiceOver labels read sensible text.
* **Gestures**: hold-to-increment vs tap + parity; haptic ticks.
* **Timer**: start/stop logs correctly; no double-count when combined with manual increments.
* **App Lifecycle**: Focus timer across background/kill/relaunch; Live Activity consistency.
* **Purchases**: sandbox testers for monthly/yearly, intro eligibility, restore on new device.
* **Notifications**: permission denied path; per-item reminders fire at local time boundaries; updates after edits.
* **Screen Time**: with and without entitlement; fallback soft block.
* **Leagues**: simulate end-of-week reset; tie-breakers.

---

## 20) Milestones (Build Plan for AI Coder)

**M1 — Foundations & Shell (Week 1)**

* Project scaffolding (SwiftUI, MVVM, SwiftData models).
* Design tokens/theme; tab bar; nav bars; placeholder screens.
* Local analytics stub.

**M2 — Habits/Tasks Core (Week 2)**

* Models: Habit (+`kind`), HabitInstance, RecurrenceRule; schedule generator; Today list UI with combined items; FAB flow.
* Streak logic + XP events (+10 habit/task, +50 day complete).
* Morning/Night reflections.
* SuggestionsService (local JSON).

**M3 — Focus (Week 3)**

* Timer with Live Activity; summaries; XP on completion.
* App blocking soft mode; entitlements scaffolding for Screen Time API.

**M4 — AI Coach (Week 4)**

* Chat UI (chips, typing indicator); `CoachService` adapter; apply suggestions (reorder/insert items).
* Daily check-in flow with quick-add from suggestions.

**M5 — Leagues & Leaderboard (Week 5)**

* Weekly XP aggregation; rank; promotion/demotion; league art per tier.
* Leaderboard UI (global sample + friends via share code).

**M6 — Onboarding & Paywall (Week 6)**

* Full onboarding, signature capture; StoreKit 2 purchase/restore; freemium limits.
* Notifications priming & per-item scheduling.

**M7 — Insights & Polish (Week 7)**

* Weekly insights, heatmap, AI pattern card (static template if needed).
* Accessibility sweep; crash/edge-case fixes; performance.

---

## 21) Example Design Tokens (code-ready)

```swift
enum Tokens {
  static let cornerRadiusLg: CGFloat = 24
  static let spacing4: CGFloat = 4
  static let spacing8: CGFloat = 8
  static let spacing16: CGFloat = 16
}

extension Color {
  static let brand = Color(hex: "#58B62F")
  static let accentBlue = Color(hex: "#46A8E0")
  static let accentGold = Color(hex: "#F5C34D")
  static let success = Color(hex: "#2FAE60")
  static let warning = Color(hex: "#E85C4A")
  static let gray = (
    g1: Color(hex:"#F6F7F8"), g2: Color(hex:"#EDEFF1"), g3: Color(hex:"#DFE3E6"),
    g4: Color(hex:"#CBD2D8"), g5: Color(hex:"#B1BAC2"), g6: Color(hex:"#939EA8"),
    g7: Color(hex:"#707C87"), g8: Color(hex:"#4F5963"), g9: Color(hex:"#2C343B")
  )
}
```

---

## 22) Sample Prompts (AI Coach – non-clinical, warm)

* “Morning! What one thing would make today feel successful?”
* “Want me to reorder your plan to front-load the hardest task?”
* “You focus best around 10 AM. Start a 25-minute session now?”
* “Streak’s alive 🔥 Keep it going with a 5-minute micro-win.”

---

## 23) Risks & Mitigations

* **Screen Time API entitlements**: submit request; ship with soft block fallback.
* **AI latency**: prefetch suggestions; show typing indicator; quick-reply chips.
* **Leaderboard fairness**: MVP uses local simulation; move to server later.
* **Purchase edge cases**: exhaustive StoreKit sandbox testing; receipt checks.

---

## 24) Open Assumptions (track & revisit)

* Start league = Base Camp.
* XP values as specified.
* iOS 17+ minimum; iCloud sync post-MVP.
* Freemium caps: 3 habits, 1 focus template, 3 AI messages/day.
* Weekly reset Monday 00:00 local.

---

### HIG Check (for coder)

* Safe areas respected; large titles on top bars where appropriate.
* 44pt min touch targets; Dynamic Type tested at XL.
* Tab bar center action (AI Coach) visually distinct but accessible.
* Motion subtle; Reduce Motion honoured.

---

**Deliverables**:

* Shipping app bundle (TestFlight), StoreKit configs, entitlements (requested), Figma file with tokens/components/screens, tappable prototype linking the 14 screens, and a short README for future contributors.
