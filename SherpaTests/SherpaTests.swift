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
    @MainActor
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
    @MainActor
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

    @Test
    func weeklyRecurrenceHandlesYearTransition() {
        let calendar = Calendar(identifier: .gregorian)
        let startComponents = DateComponents(year: 2020, month: 12, day: 28)
        let targetComponents = DateComponents(year: 2021, month: 1, day: 4)

        let startDate = calendar.date(from: startComponents)
        let targetDate = calendar.date(from: targetComponents)

        #expect(startDate != nil)
        #expect(targetDate != nil)
        guard let startDate, let targetDate else { return }

        let weekday = startDate.weekdayIndex
        let rule = RecurrenceRule(
            frequency: .weekly,
            interval: 1,
            startDate: startDate,
            weekdays: [weekday]
        )

        #expect(rule.occurs(on: targetDate))
    }

    @MainActor
    @Test
    func focusTimerTransitionsToShortBreakAfterFocus() {
        let viewModel = FocusTimerViewModel()
        viewModel.startSession()

        let focusDuration = viewModel.currentPhaseDuration
        fastForward(viewModel, seconds: focusDuration)

        #expect(viewModel.phase == .shortBreak)
        #expect(viewModel.totalFocusSessions == 1)
        #expect(viewModel.completedSessionsInCycle == 1)
        #expect(viewModel.remainingSeconds == viewModel.currentPhaseDuration)
    }

    @MainActor
    @Test
    func focusTimerPromotesToLongBreakAfterCycle() {
        let viewModel = FocusTimerViewModel()
        viewModel.startSession()

        for session in 1...4 {
            let focusDuration = viewModel.currentPhaseDuration
            fastForward(viewModel, seconds: focusDuration)

            if session < 4 {
                #expect(viewModel.phase == .shortBreak)
                let breakDuration = viewModel.currentPhaseDuration
                fastForward(viewModel, seconds: breakDuration)
                #expect(viewModel.phase == .focus)
            }
        }

        #expect(viewModel.phase == .longBreak)
        #expect(viewModel.totalFocusSessions == 4)
        #expect(viewModel.completedSessionsInCycle == 4)
    }

    @MainActor
    @Test
    func focusTimerSkipBreakResumesFocus() {
        let viewModel = FocusTimerViewModel()
        viewModel.startSession()

        let focusDuration = viewModel.currentPhaseDuration
        fastForward(viewModel, seconds: focusDuration)

        #expect(viewModel.phase == .shortBreak)
        viewModel.skipBreak()
        #expect(viewModel.phase == .focus)
        #expect(viewModel.isRunning)
    }

    @MainActor
    @Test
    func habitTileUsesStoredPaletteIdentifier() throws {
        let context = try makeInMemoryContext()
        let rule = RecurrenceRule(frequency: .daily, interval: 1, startDate: Date().startOfDay)
        context.insert(rule)

        let paletteCount = max(1, DesignTokens.cardPalettes.count)
        let storedIndex = min(3, paletteCount - 1)
        let habit = Habit(title: "Stretch", recurrenceRule: rule, paletteIdentifier: storedIndex)
        context.insert(habit)

        let instance = HabitInstance(date: Date().startOfDay, habit: habit)
        context.insert(instance)
        try context.save()

        let viewModel = HabitsHomeViewModel()
        viewModel.configureIfNeeded(modelContext: context)
        let selectedIndex = viewModel.stableColorIndex(for: instance)
        #expect(selectedIndex == storedIndex)
    }

    @MainActor
    private func fastForward(_ viewModel: FocusTimerViewModel, seconds: Int) {
        for _ in 0..<seconds {
            viewModel.tick()
        }
    }
}
