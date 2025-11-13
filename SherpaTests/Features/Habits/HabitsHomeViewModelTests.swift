import Foundation
import SwiftData
import Testing
@testable import Sherpa

struct HabitsHomeViewModelTests {
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
    @Test
    func streakShowsGlobalValueRegardlessOfSelection() throws {
        let context = try makeInMemoryContext()
        let calendar = Calendar.current
        let today = Date().startOfDay
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today)?.startOfDay else {
            #expect(false, "Failed to derive previous day for test")
            return
        }

        let rule = RecurrenceRule(frequency: .daily, interval: 1, startDate: yesterday)
        context.insert(rule)

        let habit = Habit(title: "Read", recurrenceRule: rule)
        context.insert(habit)

        let completedYesterday = HabitInstance(date: yesterday, status: .completed, habit: habit)
        let pendingToday = HabitInstance(date: today, status: .pending, habit: habit)
        context.insert(completedYesterday)
        context.insert(pendingToday)
        try context.save()

        let viewModel = HabitsHomeViewModel(context: context)
        viewModel.reloadInstances(centeredOn: today)

        viewModel.selectedDate = today
        #expect(viewModel.currentStreakCount == 1, "Streak should persist from yesterday until today is completed")

        viewModel.selectedDate = yesterday
        #expect(viewModel.currentStreakCount == 1, "Selecting a past day should still reflect the global streak")

        pendingToday.status = .completed
        try context.save()
        viewModel.reloadInstances(centeredOn: today)

        viewModel.selectedDate = today
        #expect(viewModel.currentStreakCount == 2, "Completing today should increment the streak")

        viewModel.selectedDate = yesterday
        #expect(viewModel.currentStreakCount == 2, "Past-day selection should continue to show the global streak")
    }

    @MainActor
    @Test
    func streakRemainsWhenViewingFutureDates() throws {
        let context = try makeInMemoryContext()
        let calendar = Calendar.current
        let today = Date().startOfDay
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today)?.startOfDay else {
            #expect(false, "Failed to derive previous day for test")
            return
        }
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)?.startOfDay,
              let futureDate = calendar.date(byAdding: .day, value: 2, to: today)?.startOfDay else {
            #expect(false, "Failed to derive future dates for test")
            return
        }

        let rule = RecurrenceRule(frequency: .daily, interval: 1, startDate: yesterday)
        context.insert(rule)

        let habit = Habit(title: "Read", recurrenceRule: rule)
        context.insert(habit)

        let completedYesterday = HabitInstance(date: yesterday, status: .completed, habit: habit)
        let completedToday = HabitInstance(date: today, status: .completed, habit: habit)
        let futureInstance = HabitInstance(date: tomorrow, status: .pending, habit: habit)
        context.insert(completedYesterday)
        context.insert(completedToday)
        context.insert(futureInstance)
        try context.save()

        let viewModel = HabitsHomeViewModel(context: context)
        viewModel.reloadInstances(centeredOn: today)

        viewModel.selectedDate = today
        #expect(viewModel.currentStreakCount == 2)

        viewModel.selectedDate = futureDate
        #expect(
            viewModel.currentStreakCount == 2,
            "Selecting future dates should not reset the active streak"
        )
    }

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
}
