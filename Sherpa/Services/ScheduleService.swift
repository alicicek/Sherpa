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
            var scheduledDates = Set(habit.instances.map(\.date).map(\.startOfDay))

            for day in scheduleDays where habit.recurrenceRule.occurs(on: day) {
                if scheduledDates.insert(day).inserted {
                    let instance = HabitInstance(date: day, habit: habit, task: nil)
                    context.insert(instance)
                    habit.instances.append(instance)
                }
            }
        }
    }

    private func ensureTaskInstances(for tasks: [Task], on scheduleDays: [Date]) {
        for task in tasks {
            var scheduledDates = Set(task.instances.map(\.date).map(\.startOfDay))

            for day in scheduleDays {
                let shouldCreate = if let recurrence = task.recurrenceRule {
                    recurrence.occurs(on: day)
                } else if let dueDate = task.dueDate {
                    dueDate == day
                } else {
                    false
                }

                guard shouldCreate else { continue }

                if scheduledDates.insert(day).inserted {
                    let instance = HabitInstance(date: day, habit: nil, task: task)
                    context.insert(instance)
                    task.instances.append(instance)
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
}
