# Sherpa Demo Codebase Overview

## High-Level Structure
- `SherpaApp.swift` bootstraps SwiftData models (`Habit`, `Task`, `HabitInstance`, `RecurrenceRule`) into a shared `ModelContainer` and sets `ContentView` as the root scene. 【F:Sherpa/SherpaApp.swift†L11-L31】
- `ContentView` hosts the primary `TabView` with the Habits feature and placeholder tabs for future Focus, AI Coach, Insights, and Leaderboard modules. 【F:Sherpa/ContentView.swift†L11-L130】
- Feature-specific SwiftUI views live under `Sherpa/Features`. The Habits module is the most complete implementation today. 【F:Sherpa/Features/Habits/HabitsHomeView.swift†L11-L107】

## Data & Domain Models
- Core habit entities are defined in `Models/HabitModels.swift` with SwiftData annotations, covering recurrence rules, habits, tasks, and scheduled instances. 【F:Sherpa/Models/HabitModels.swift†L10-L190】
- `StreakCalculator` derives streak eligibility based on a 40% completion rule while ignoring skip-with-note instances. 【F:Sherpa/Models/HabitModels.swift†L193-L223】
- `ScheduleService` materializes `HabitInstance` rows for a given date range so the UI always has concrete items to display. 【F:Sherpa/Services/ScheduleService.swift†L10-L57】

## UI Layer
- `HabitsHomeView` drives the experience with a hero card, Duolingo-style calendar strip, habit cards, and modals for adding routines or logging skip notes. It queries `HabitInstance` data and reacts to user interactions by saving changes through SwiftData. 【F:Sherpa/Features/Habits/HabitsHomeView.swift†L11-L223】
- Supporting components like `HabitsHeroCard`, `CalendarStripView`, and `RoutineCard` create the playful aesthetic requested in the PRD, including placeholders for mascot and mountain artwork. 【F:Sherpa/Features/Habits/HabitsHomeView.swift†L224-L757】
- Shared styling tokens and reusable UI primitives (cards, chips, badges) live in `DesignTokens.swift` and `Utilities/SherpaUIComponents.swift`. 【F:Sherpa/DesignTokens.swift†L9-L123】【F:Sherpa/Utilities/SherpaUIComponents.swift†L9-L119】

## Utilities & Extensions
- Date helpers normalize to the start of the day and compute deltas, which underpin scheduling logic. 【F:Sherpa/Utilities/Date+Helpers.swift†L9-L29】

## Testing
- `SherpaTests` uses the Swift Testing library to verify streak calculations and ensure the scheduler avoids duplicate instances. 【F:SherpaTests/SherpaTests.swift†L13-L80】

## Next Steps for New Contributors
1. Flesh out the placeholder tabs by scaffolding their own feature folders under `Sherpa/Features` and wiring real data. The `TabPlaceholderView` pattern in `ContentView` offers a starting point for consistent visuals. 【F:Sherpa/ContentView.swift†L30-L123】
2. Replace placeholder artwork in the Habits hero with production assets and hook the league/XP stats to real analytics once available. 【F:Sherpa/Features/Habits/HabitsHomeView.swift†L224-L275】
3. Expand test coverage around `ScheduleService` edge cases (e.g., weekly/monthly recurrences) and UI logic such as streak summaries to guard future refactors. 【F:Sherpa/Services/ScheduleService.swift†L34-L57】【F:SherpaTests/SherpaTests.swift†L55-L80】
