import Foundation
import SwiftData
import Testing
@testable import Sherpa

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

struct ScheduleServiceTests {
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
    @MainActor
    func scheduleHonoursOccurrenceLimit() throws {
        let context = try makeInMemoryContext()
        let startDate = Date().startOfDay
        let rule = RecurrenceRule(
            frequency: .daily,
            interval: 1,
            startDate: startDate,
            occurrenceLimit: 2
        )
        context.insert(rule)

        let habit = Habit(title: "Hydrate", recurrenceRule: rule)
        context.insert(habit)
        try context.save()

        let endDate = startDate.adding(days: 5)
        try ScheduleService(context: context).ensureSchedule(from: startDate, to: endDate)

        let descriptor = FetchDescriptor<HabitInstance>(predicate: #Predicate { $0.habit == habit })
        let instances = try context.fetch(descriptor)
        #expect(instances.count == 2)
    }

    @Test
    @MainActor
    func onceFrequencySchedulesSingleOccurrence() throws {
        let context = try makeInMemoryContext()
        let startDate = Date().startOfDay
        let rule = RecurrenceRule(frequency: .once, interval: 1, startDate: startDate)
        context.insert(rule)

        let habit = Habit(title: "Doctor visit", recurrenceRule: rule)
        context.insert(habit)
        try context.save()

        let endDate = startDate.adding(days: 7)
        try ScheduleService(context: context).ensureSchedule(from: startDate, to: endDate)

        let descriptor = FetchDescriptor<HabitInstance>(predicate: #Predicate { $0.habit == habit })
        let instances = try context.fetch(descriptor)
        #expect(instances.count == 1)
        #expect(instances.first?.date == startDate)
    }
}
