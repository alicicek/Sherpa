import Foundation
import Testing
@testable import Sherpa

struct StreakCalculatorTests {
    @Test
    func streakRequiresFortyPercentCompletion() {
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
    func skipWithNoteExcludesFromStreakCalculation() {
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
}
