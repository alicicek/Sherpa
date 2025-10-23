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
