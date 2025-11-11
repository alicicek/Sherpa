//
//  ScheduleService.swift
//  Sherpa
//
//  Created by Codex on 15/10/2025.
//

import Foundation
import SwiftData

/// Generates HabitInstance rows for the supplied date range ensuring the UI has concrete items to display.
@MainActor
struct ScheduleService {
    let context: ModelContext

    func ensureSchedule(from startDate: Date, to endDate: Date) throws {
        let normalizedStart = startDate.startOfDay
        let normalizedEnd = endDate.startOfDay
        guard normalizedEnd >= normalizedStart else { return }

        let scheduleDays = Self.scheduleDays(from: normalizedStart, to: normalizedEnd)
        guard scheduleDays.isEmpty == false else { return }

        let habitsDescriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\Habit.createdAt, order: .forward)]
        )
        let taskDescriptor = FetchDescriptor<Task>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\Task.createdAt, order: .forward)]
        )

        let habits = try context.fetch(habitsDescriptor)
        let tasks = try context.fetch(taskDescriptor)

        ensureHabitInstances(for: habits, on: scheduleDays)
        ensureTaskInstances(for: tasks, on: scheduleDays)

        if context.hasChanges {
            try context.save()
        }
    }

    private func ensureHabitInstances(for habits: [Habit], on scheduleDays: [Date]) {
        for habit in habits {
            let recurrence = habit.recurrenceRule
            var scheduledDates = Set(habit.instances.map(\.date).map(\.startOfDay))
            var remainingOccurrences = Self.remainingOccurrences(for: recurrence, existingCount: habit.instances.count)

            for day in scheduleDays where recurrence.occurs(on: day) {
                guard remainingOccurrences ?? 1 > 0 else { break }
                if scheduledDates.insert(day).inserted {
                    let instance = HabitInstance(date: day, habit: habit, task: nil)
                    context.insert(instance)
                    habit.instances.append(instance)
                    remainingOccurrences = remainingOccurrences.map { max(0, $0 - 1) }
                }
            }
        }
    }

    private func ensureTaskInstances(for tasks: [Task], on scheduleDays: [Date]) {
        for task in tasks {
            var scheduledDates = Set(task.instances.map(\.date).map(\.startOfDay))
            var remainingOccurrences = Self.remainingOccurrences(for: task.recurrenceRule, existingCount: task.instances.count)

            for day in scheduleDays {
                var shouldCreate = false
                if let recurrence = task.recurrenceRule {
                    guard remainingOccurrences ?? 1 > 0 else { break }
                    shouldCreate = recurrence.occurs(on: day)
                } else if let dueDate = task.dueDate {
                    shouldCreate = dueDate == day
                }

                guard shouldCreate else { continue }

                if scheduledDates.insert(day).inserted {
                    let instance = HabitInstance(date: day, habit: nil, task: task)
                    context.insert(instance)
                    task.instances.append(instance)
                    remainingOccurrences = remainingOccurrences.map { max(0, $0 - 1) }
                }
            }
        }
    }

    private static func scheduleDays(from start: Date, to end: Date) -> [Date] {
        var cursor = start
        var result: [Date] = []
        while cursor <= end {
            result.append(cursor)
            cursor = cursor.adding(days: 1)
        }
        return result
    }

    private static func remainingOccurrences(for rule: RecurrenceRule?, existingCount: Int) -> Int? {
        guard let limit = rule?.occurrenceLimit else { return nil }
        return max(0, limit - existingCount)
    }
}
