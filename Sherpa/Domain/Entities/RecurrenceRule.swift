import Foundation
import SwiftData

/// Represents a rule describing when an item should be scheduled.
@Model
final class RecurrenceRule {
    var frequency: RecurrenceFrequency
    var interval: Int
    var startDate: Date
    /// Weekday values 1...7 (Calendar weekday index). Used for weekly rules.
    var weekdays: [Int]

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
    func occurs(on date: Date) -> Bool {
        let normalizedDate = date.startOfDay
        guard normalizedDate >= startDate else { return false }

        let daysFromStart = normalizedDate.days(since: startDate)

        switch frequency {
        case .daily:
            return daysFromStart % interval == 0
        case .weekly:
            let calendar = Calendar.current
            let weeksFromStart = calendar.dateComponents(
                [.weekOfYear],
                from: startDate.startOfDay,
                to: normalizedDate
            ).weekOfYear ?? 0

            guard weeksFromStart % interval == 0 else { return false }

            if weekdays.isEmpty {
                return true
            }

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
            } else {
                // If the start day is beyond the number of days in the month, schedule on the last day.
                return currentDay == daysInMonth(year: year, month: month)
            }
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
