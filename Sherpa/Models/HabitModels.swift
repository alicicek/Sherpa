//
//  HabitModels.swift
//  Sherpa
//
//  Created by Codex on 15/10/2025.
//

import Foundation
import SwiftData

/// Supported recurrence frequencies for habits/tasks.
enum RecurrenceFrequency: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

/// Represents a day of week using Calendar weekday index semantics (Sunday = 1).
enum Weekday: Int, CaseIterable, Identifiable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var id: Int { rawValue }

    var shortSymbol: String {
        switch self {
        case .sunday: return "Su"
        case .monday: return "Mo"
        case .tuesday: return "Tu"
        case .wednesday: return "We"
        case .thursday: return "Th"
        case .friday: return "Fr"
        case .saturday: return "Sa"
        }
    }

    var longName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

/// Represents a rule describing when an item should be scheduled.
@Model
final class RecurrenceRule {
    var frequency: RecurrenceFrequency
    var interval: Int
    var startDate: Date
    /// Weekday values 1...7 (Calendar weekday index). Used for weekly rules.
    var weekdays: [Int]

    @MainActor
    init(
        frequency: RecurrenceFrequency = .daily,
        interval: Int = 1,
        startDate: Date = .now,
        weekdays: [Int] = []
    ) {
        self.frequency = frequency
        self.interval = max(1, interval)
        self.startDate = startDate.startOfDay
        self.weekdays = weekdays.sorted()
    }

    /// Returns true if the rule results in an occurrence for the supplied date.
    @MainActor
    func occurs(on date: Date) -> Bool {
        let normalizedDate = date.startOfDay
        guard normalizedDate >= startDate else { return false }

        let daysFromStart = normalizedDate.days(since: startDate)

        switch frequency {
        case .daily:
            return daysFromStart % interval == 0
        case .weekly:
            guard weekdays.isEmpty == false else {
                return daysFromStart % (interval * 7) == 0
            }
            let calendar = Calendar.current
            let startWeek = calendar.component(.weekOfYear, from: startDate)
            let currentWeek = calendar.component(.weekOfYear, from: normalizedDate)
            let weekDelta = (currentWeek - startWeek + 5200) % 52 // Keep positive
            guard weekDelta % interval == 0 else { return false }
            return weekdays.contains(normalizedDate.weekdayIndex)
        case .monthly:
            let calendar = Calendar.current
            let startComponents = calendar.dateComponents([.day], from: startDate)
            let currentComponents = calendar.dateComponents([.month, .year, .day], from: normalizedDate)
            guard let targetDay = startComponents.day,
                  let currentDay = currentComponents.day,
                  let month = currentComponents.month,
                  let year = currentComponents.year
            else {
                return false
            }

            let monthsFromStart = calendar.dateComponents([.month], from: startDate, to: normalizedDate).month ?? 0
            guard monthsFromStart % interval == 0 else { return false }

            if targetDay <= daysInMonth(year: year, month: month) {
                return currentDay == targetDay
            }

            // If the start day is beyond the number of days in the month, schedule on the last day.
            return currentDay == daysInMonth(year: year, month: month)
        }
    }

    private func daysInMonth(year: Int, month: Int) -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month
        let calendar = Calendar.current
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }
}

/// Represents a habit definition.
@Model
final class Habit {
    var title: String
    var detail: String?
    var createdAt: Date
    var colorHex: String?
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \HabitInstance.habit)
    var instances: [HabitInstance]

    @Relationship(deleteRule: .nullify)
    var recurrenceRule: RecurrenceRule

    init(
        title: String,
        detail: String? = nil,
        createdAt: Date = .now,
        colorHex: String? = nil,
        isArchived: Bool = false,
        recurrenceRule: RecurrenceRule
    ) {
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
        self.colorHex = colorHex
        self.isArchived = isArchived
        instances = []
        self.recurrenceRule = recurrenceRule
    }
}

/// Represents a task definition (non-streak affecting).
@Model
final class Task {
    var title: String
    var detail: String?
    var createdAt: Date
    var dueDate: Date?
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \HabitInstance.task)
    var instances: [HabitInstance]

    @Relationship(deleteRule: .nullify)
    var recurrenceRule: RecurrenceRule?

    @MainActor
    init(
        title: String,
        detail: String? = nil,
        createdAt: Date = .now,
        dueDate: Date? = nil,
        isArchived: Bool = false,
        recurrenceRule: RecurrenceRule? = nil
    ) {
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
        self.dueDate = dueDate?.startOfDay
        self.isArchived = isArchived
        instances = []
        self.recurrenceRule = recurrenceRule
    }
}

/// Completion state for an instance.
enum CompletionState: String, Codable, CaseIterable {
    case pending
    case completed
    case skipped
    case skippedWithNote

    var isCompleted: Bool {
        self == .completed
    }

    var isSkippedWithNote: Bool {
        self == .skippedWithNote
    }
}

/// Represents a scheduled occurrence for either a habit or a task.
@Model
final class HabitInstance {
    var date: Date
    var status: CompletionState
    var note: String?
    var completedAt: Date?

    @Relationship var habit: Habit?
    @Relationship var task: Task?

    @MainActor
    init(date: Date, status: CompletionState = .pending, note: String? = nil, habit: Habit? = nil, task: Task? = nil) {
        self.date = date.startOfDay
        self.status = status
        self.note = note
        completedAt = nil
        self.habit = habit
        self.task = task
    }

    var displayName: String {
        habit?.title ?? task?.title ?? "Untitled"
    }

    var isHabit: Bool {
        habit != nil
    }
}

/// Simple utility responsible for determining streak eligibility.
enum StreakCalculator {
    /// Returns whether the provided set of instances qualifies for streak credit.
    static func qualifiesForStreak(instances: [HabitInstance]) -> Bool {
        let eligibleInstances = instances.filter { instance in
            guard instance.isHabit else { return false }
            return instance.status != .skippedWithNote
        }
        guard eligibleInstances.isEmpty == false else { return false }

        let completedCount = eligibleInstances.filter { $0.status == .completed }.count
        let threshold = max(1, Int(ceil(Double(eligibleInstances.count) * 0.4)))
        return completedCount >= threshold
    }
}
