//
//  HabitsHomeViewModel.swift
//  Sherpa
//
//  Centralises orchestration for the Habits home screen so the view can stay declarative.
//

import Combine
import OSLog
import SwiftData
import SwiftUI

enum HabitMetrics {
    static let completionTolerance: Double = 1e-4
}

struct HabitTileProfile {
    let goal: Double
    let step: Double
    let unit: String
    let subtitle: String
    let icon: String
    let accent: Color
    let background: Color
}

@MainActor
final class HabitsHomeViewModel: ObservableObject {
    @Published var selectedDate: Date
    @Published private(set) var instances: [HabitInstance] = []
    @Published private(set) var habitProgressValues: [PersistentIdentifier: Double] = [:]
    @Published private var calendarWindowStart: Date

    private let calendarSpan: Int = 14
    private var habitTileProfiles: [PersistentIdentifier: HabitTileProfile] = [:]
    private var modelContext: ModelContext?
    private var repo: HabitsRepository?

    init(context: ModelContext? = nil, repo: HabitsRepository? = nil) {
        let now = Date().startOfDay
        self.selectedDate = now
        self.calendarWindowStart = now.adding(days: -calendarSpan)
        self.modelContext = context
        if let repo {
            self.repo = repo
        } else if let context {
            self.repo = SwiftDataHabitsRepository(context: context)
        }
    }

    func configureIfNeeded(modelContext: ModelContext, repo: HabitsRepository? = nil) {
        if self.modelContext == nil {
            self.modelContext = modelContext
        }

        if self.repo == nil {
            if let repo {
                self.repo = repo
            } else {
                self.repo = SwiftDataHabitsRepository(context: modelContext)
            }
        }
    }

    var calendarDates: [Date] {
        let start = calendarWindowStart
        return (0...(calendarSpan * 2)).map { offset in
            start.adding(days: offset)
        }
    }

    var todaysItems: [HabitInstance] {
        let grouped = Dictionary(grouping: instances) { $0.date.startOfDay }
        return (grouped[selectedDate.startOfDay] ?? [])
            .sorted { lhs, rhs in
                if lhs.isHabit == rhs.isHabit {
                    return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
                }
                return lhs.isHabit && !rhs.isHabit
            }
    }

    var eligibleHabitInstances: [HabitInstance] {
        todaysItems.filter { instance in
            instance.isHabit && instance.status != .skippedWithNote
        }
    }

    var eligibleHabitCount: Int {
        eligibleHabitInstances.count
    }

    var completionProgress: Double {
        guard eligibleHabitCount > 0 else { return 0 }
        return Double(eligibleHabitInstances.filter { $0.status == .completed }.count) / Double(eligibleHabitCount)
    }

    var leagueTitle: String {
        switch completionProgress {
        case 0.75...:
            return "Summit League"
        case 0.4...:
            return "Hilltop League"
        default:
            return "Hilltop League"
        }
    }

    var totalXP: Int {
        todaysItems.reduce(0) { total, instance in
            let baseXP = instance.isHabit ? 25 : 15
            return total + (instance.status == .completed ? baseXP : baseXP / 2)
        }
    }

    var dayCompletionSnapshots: [Date: DayCompletionSnapshot] {
        let grouped = Dictionary(grouping: instances) { $0.date.startOfDay }
        var snapshots: [Date: DayCompletionSnapshot] = [:]

        for (date, items) in grouped {
            let eligibleItems = items.filter { $0.isHabit && $0.status != .skippedWithNote }
            let completedCount = eligibleItems.filter { $0.status == .completed }.count
            let eligibleCount = eligibleItems.count

            guard eligibleCount > 0 else {
                snapshots[date] = DayCompletionSnapshot(progress: 0, isComplete: false, hasEligibleItems: false)
                continue
            }

            let threshold = max(1, Int(ceil(Double(eligibleCount) * 0.4)))
            let progress = min(Double(completedCount) / Double(threshold), 1)
            let snapshot = DayCompletionSnapshot(
                progress: progress,
                isComplete: completedCount >= threshold,
                hasEligibleItems: true
            )
            snapshots[date] = snapshot
        }

        return snapshots
    }

    func adjustCalendarWindowIfNeeded(for date: Date) {
        let normalizedDate = date.startOfDay
        let currentStart = calendarWindowStart
        let currentEnd = currentStart.adding(days: calendarSpan * 2)

        let leadingThreshold = currentStart.adding(days: 3)
        let trailingThreshold = currentEnd.adding(days: -3)

        if normalizedDate <= leadingThreshold {
            calendarWindowStart = normalizedDate.adding(days: -calendarSpan)
        } else if normalizedDate >= trailingThreshold {
            calendarWindowStart = normalizedDate.adding(days: -calendarSpan)
        }
    }

    func ensureScheduleForVisibleRange(centeredOn date: Date? = nil) async {
        guard let context = modelContext else { return }

        let center = date?.startOfDay ?? selectedDate
        let start = center.adding(days: -calendarSpan)
        let end = center.adding(days: calendarSpan)
        do {
            try ScheduleService(context: context).ensureSchedule(from: start, to: end)
        } catch {
            Logger.habits.error("Failed to ensure schedule window: \(error.localizedDescription, privacy: .public)")
        }
    }

    func reloadInstances(centeredOn date: Date? = nil) {
        guard let context = modelContext else { return }

        let center = date?.startOfDay ?? selectedDate
        let start = center.adding(days: -calendarSpan)
        let end = center.adding(days: calendarSpan)

        var descriptor = FetchDescriptor<HabitInstance>(
            predicate: #Predicate { instance in
                instance.date >= start && instance.date <= end
            },
            sortBy: [SortDescriptor(\HabitInstance.date, order: .forward)]
        )
        descriptor.fetchLimit = 200

        do {
            instances = try context.fetch(descriptor)
        } catch {
            Logger.habits.error("Failed to fetch habit instances: \(error.localizedDescription, privacy: .public)")
        }
    }

    func pruneProgressCache() {
        let visibleIDs = Set(todaysItems.map(\.persistentModelID))
        habitProgressValues = habitProgressValues.filter { visibleIDs.contains($0.key) }
    }

    func handleAddItem() {
        _Concurrency.Task {
            await refreshSelection(to: selectedDate)
        }
    }

    func refreshSelection(to date: Date) async {
        adjustCalendarWindowIfNeeded(for: date)
        await ensureScheduleForVisibleRange(centeredOn: date)
        reloadInstances(centeredOn: date)
        pruneProgressCache()
    }

    func stableColorIndex(for instance: HabitInstance) -> Int {
        let palettes = DesignTokens.cardPalettes
        guard palettes.isEmpty == false else { return 0 }

        if let habit = instance.habit {
            let count = palettes.count
            if count > 0 {
                let raw = habit.paletteIdentifier
                let normalized = ((raw % count) + count) % count
                return normalized
            }
        }

        let token = stableIdentifier(for: instance.persistentModelID)
        var hash: UInt64 = 0xcbf29ce484222325 // FNV-1a offset basis
        for scalar in token.unicodeScalars {
            hash ^= UInt64(scalar.value)
            hash &*= UInt64(0x100000001b3)
        }

        return Int(hash % UInt64(palettes.count))
    }

    private func stableIdentifier(for identifier: PersistentIdentifier) -> String {
        let description = String(describing: identifier)
        guard let start = description.firstIndex(of: "<"),
              let end = description.lastIndex(of: ">"),
              start < end else {
            return description
        }
        let range = description.index(after: start)..<end
        return String(description[range])
    }

    func habitProfile(for instance: HabitInstance) -> HabitTileProfile {
        let identifier = instance.persistentModelID
        if let cached = habitTileProfiles[identifier] {
            return cached
        }

        let colorIndex = stableColorIndex(for: instance)
        let palettes = DesignTokens.cardPalettes
        let palette = palettes.isEmpty ? [DesignTokens.Colors.primary] : palettes[colorIndex % palettes.count]
        let accent = palette.first ?? DesignTokens.Colors.primary
        let background = (palette.dropFirst().first ?? accent).opacity(0.18)

        var goal: Double = instance.isHabit ? 4 : 1
        var unit: String = instance.isHabit ? "reps" : "tasks"
        var subtitle: String = instance.isHabit ? "Every day" : "Task"
        var icon: String = instance.isHabit ? "🧗" : "📝"

        let lowercasedName = instance.displayName.lowercased()
        if lowercasedName.contains("water") {
            goal = 3000
            unit = "ml"
            icon = "💧"
            subtitle = "Hydration"
        } else if lowercasedName.contains("protein") {
            goal = 400
            unit = "g"
            icon = "🍗"
            subtitle = "Nutrition"
        } else if lowercasedName.contains("walk") || lowercasedName.contains("steps") {
            goal = 8000
            unit = "steps"
            icon = "🚶"
            subtitle = "Movement"
        } else if lowercasedName.contains("meditat") {
            goal = 20
            unit = "min"
            icon = "🧘"
            subtitle = "Mindfulness"
        }

        let step = AdaptiveStepCalculator.stepSize(for: goal)

        let profile = HabitTileProfile(
            goal: goal,
            step: step,
            unit: unit,
            subtitle: subtitle,
            icon: icon,
            accent: accent,
            background: background
        )

        habitTileProfiles[identifier] = profile
        return profile
    }

    func tileModel(for instance: HabitInstance, profile: HabitTileProfile) -> HabitTileModel {
        HabitTileModel(
            title: instance.displayName,
            subtitle: profile.subtitle,
            icon: profile.icon,
            goal: profile.goal,
            unit: profile.unit,
            step: profile.step,
            accentColor: profile.accent,
            backgroundColor: profile.background
        )
    }

    func progressBinding(for instance: HabitInstance, profile: HabitTileProfile) -> Binding<Double> {
        let identifier = instance.persistentModelID
        if habitProgressValues[identifier] == nil {
            let initialValue = instance.status == .completed ? profile.goal : 0
            habitProgressValues[identifier] = initialValue
        }

        return Binding<Double>(
            get: { [weak self] in
                guard let self else { return 0 }
                return self.habitProgressValues[identifier] ?? 0
            },
            set: { [weak self] newValue in
                guard let self else { return }
                let clamped = max(0, min(profile.goal, newValue))
                self.habitProgressValues[identifier] = clamped
            }
        )
    }

    func handleProgressChange(
        for instance: HabitInstance,
        profile: HabitTileProfile,
        newValue: Double
    ) {
        let identifier = instance.persistentModelID
        let clamped = max(0, min(profile.goal, newValue))
        habitProgressValues[identifier] = clamped

        let shouldBeCompleted = clamped >= profile.goal - HabitMetrics.completionTolerance
        if shouldBeCompleted {
            if instance.status != .completed {
                update(instance: instance, status: .completed, note: instance.note)
            }
        } else if instance.status == .completed {
            update(instance: instance, status: .pending, note: instance.note)
        }

        saveProgress(for: instance, progress: clamped, profile: profile)
    }

    func resetProgress(for instance: HabitInstance, profile: HabitTileProfile) {
        let identifier = instance.persistentModelID
        habitProgressValues[identifier] = 0
        handleProgressChange(for: instance, profile: profile, newValue: 0)
    }

    func skip(instance: HabitInstance, profile: HabitTileProfile) {
        let identifier = instance.persistentModelID
        habitProgressValues[identifier] = 0
        update(instance: instance, status: .skipped, note: nil)
        saveProgress(for: instance, progress: 0, profile: profile)
    }

    func update(instance: HabitInstance, status: CompletionState, note: String?) {
        guard let context = modelContext else {
            Logger.habits.error("Attempted to update habit instance without model context")
            return
        }

        instance.status = status
        instance.note = note
        instance.completedAt = status == .completed ? Date() : nil
        do {
            try context.save()
        } catch {
            Logger.habits.error("Failed to update habit instance: \(error.localizedDescription, privacy: .public)")
        }
    }

    func saveProgress(for instance: HabitInstance, progress: Double, profile: HabitTileProfile) {
        let percent = profile.goal > 0 ? Int((progress / profile.goal) * 100) : 0
        Logger.habits.debug(
            "Saved progress for \(instance.displayName, privacy: .private): \(Int(progress), privacy: .public)/\(Int(profile.goal), privacy: .public) \(profile.unit, privacy: .private) (\(percent, privacy: .public)% done)"
        )
        saveProgress(for: instance, value: progress, goal: profile.goal, unit: profile.unit)
    }

    func saveProgress(for instance: HabitInstance, value: Double, goal: Double, unit: String) {
        _Concurrency.Task { @MainActor [weak self] in
            guard let self else { return }
            guard let repository = self.resolveRepository(using: self.modelContext) else { return }
            try? await repository.saveProgress(for: instance, value: value, goal: goal, unit: unit)
        }
    }

    private func resolveRepository(using context: ModelContext?) -> HabitsRepository? {
        if let repo {
            return repo
        }

        guard let context else { return nil }
        let repository = SwiftDataHabitsRepository(context: context)
        repo = repository
        return repository
    }
}

private enum AdaptiveStepCalculator {
    static func stepSize(for goal: Double) -> Double {
        switch goal {
        case ..<20:
            return 1
        case ..<200:
            return 5
        case ..<1000:
            return 10
        case ..<5000:
            return 50
        case ..<10000:
            return 100
        default:
            return 250
        }
    }
}
