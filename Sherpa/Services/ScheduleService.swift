//
//  ScheduleService.swift
//  Sherpa
//
//  Created by Codex on 15/10/2025.
//

import Foundation
import SwiftData

/// Generates HabitInstance rows for the supplied date range ensuring the UI has concrete items to display.
struct ScheduleService {
    let context: ModelContext

    func ensureSchedule(from startDate: Date, to endDate: Date) throws {
        let normalizedStart = startDate.startOfDay
        let normalizedEnd = endDate.startOfDay
        guard normalizedEnd >= normalizedStart else { return }

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

        var cursor = normalizedStart
        while cursor <= normalizedEnd {
            try ensureInstances(for: habits, on: cursor)
            try ensureInstances(for: tasks, on: cursor)
            cursor = cursor.adding(days: 1)
        }

        if context.hasChanges {
            try context.save()
        }
    }

    private func ensureInstances(for habits: [Habit], on date: Date) throws {
        for habit in habits {
            guard habit.recurrenceRule.occurs(on: date) else { continue }
            if habit.instances.contains(where: { $0.date == date.startOfDay }) {
                continue
            }
            let instance = HabitInstance(date: date, habit: habit, task: nil)
            context.insert(instance)
            habit.instances.append(instance)
        }
    }

    private func ensureInstances(for tasks: [Task], on date: Date) throws {
        for task in tasks {
            let normalizedDate = date.startOfDay
            var shouldCreate = false

            if let recurrence = task.recurrenceRule {
                shouldCreate = recurrence.occurs(on: normalizedDate)
            } else if let dueDate = task.dueDate {
                shouldCreate = dueDate == normalizedDate
            }

            guard shouldCreate else { continue }

            if task.instances.contains(where: { $0.date == normalizedDate }) {
                continue
            }

            let instance = HabitInstance(date: normalizedDate, habit: nil, task: task)
            context.insert(instance)
            task.instances.append(instance)
        }
    }
}
