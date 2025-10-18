//
//  SherpaTests.swift
//  SherpaTests
//
//  Created by Ali Cicek on 15/10/2025.
//

import Foundation
import SwiftData
import Testing
@testable import Sherpa

struct SherpaTests {
    private func makeInMemoryContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Habit.self,
            Task.self,
            HabitInstance.self,
            RecurrenceRule.self,
            configurations: configuration
        )
        return ModelContext(container)
    }

    @Test
    func streakRequiresFortyPercentCompletion() throws {
        let rule = RecurrenceRule(frequency: .daily, interval: 1, startDate: .now)
        let habit = Habit(title: "Read", recurrenceRule: rule)
        let today = Date().startOfDay

        let completedA = HabitInstance(date: today, status: .completed, habit: habit)
        let completedB = HabitInstance(date: today, status: .completed, habit: habit)
        let pending = HabitInstance(date: today, status: .pending, habit: habit)

        let qualifies = StreakCalculator.qualifiesForStreak(instances: [completedA, completedB, pending])
        #expect(qualifies == true)
    }

    @Test
    func skipWithNoteExcludesFromStreakCalculation() throws {
        let rule = RecurrenceRule(frequency: .daily, interval: 1, startDate: .now)
        let habit = Habit(title: "Run", recurrenceRule: rule)
        let today = Date().startOfDay

        let completed = HabitInstance(date: today, status: .completed, habit: habit)
        let skippedWithNote = HabitInstance(date: today, status: .skippedWithNote, note: "Injured", habit: habit)
        let pending = HabitInstance(date: today, status: .pending, habit: habit)

        let qualifies = StreakCalculator.qualifiesForStreak(instances: [completed, skippedWithNote, pending])
        #expect(qualifies == true, "Skip-with-note should be excluded from streak threshold calculation.")
    }

    @Test
    func scheduleServiceGeneratesInstancesWithoutDuplicates() throws {
        let context = try makeInMemoryContext()
        let rule = RecurrenceRule(frequency: .daily, interval: 1, startDate: Date().startOfDay)
        context.insert(rule)

        let habit = Habit(title: "Meditate", recurrenceRule: rule)
        context.insert(habit)
        try context.save()

        let targetDate = Date().startOfDay
        try ScheduleService(context: context).ensureSchedule(from: targetDate, to: targetDate)

        let descriptor = FetchDescriptor<HabitInstance>(
            predicate: #Predicate { $0.date == targetDate },
            sortBy: [SortDescriptor(\HabitInstance.date)]
        )
        let instancesAfterFirstPass = try context.fetch(descriptor)
        #expect(instancesAfterFirstPass.count == 1)
        #expect(instancesAfterFirstPass.first?.habit === habit)

        // Call ensureSchedule again to ensure duplicates are not created.
        try ScheduleService(context: context).ensureSchedule(from: targetDate, to: targetDate)
        let instancesAfterSecondPass = try context.fetch(descriptor)
        #expect(instancesAfterSecondPass.count == 1)
    }
}
