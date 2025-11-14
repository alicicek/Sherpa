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
    /// Optional override for monthly schedules when the selected day differs from the start date's day.
    var dayOfMonthOverride: Int?
    /// Optional end date after which the rule stops producing occurrences.
    var endDate: Date?
    /// Optional cap on the total number of occurrences the rule should generate.
    var occurrenceLimit: Int?

    init(
        frequency: RecurrenceFrequency = .daily,
        interval: Int = 1,
        startDate: Date = .now,
        weekdays: [Int] = [],
        dayOfMonthOverride: Int? = nil,
        endDate: Date? = nil,
        occurrenceLimit: Int? = nil
    ) {
        self.frequency = frequency
        self.interval = max(1, interval)
        self.startDate = startDate.startOfDay
        self.weekdays = Array(Set(weekdays)).sorted()
        if let day = dayOfMonthOverride {
            self.dayOfMonthOverride = min(max(1, day), 31)
        } else {
            self.dayOfMonthOverride = nil
        }
        self.endDate = endDate?.startOfDay
        if let limit = occurrenceLimit, limit > 0 {
            self.occurrenceLimit = limit
        } else {
            self.occurrenceLimit = nil
        }
    }

    /// Returns true if the rule results in an occurrence for the supplied date.
    func occurs(on date: Date) -> Bool {
        let normalizedDate = date.startOfDay
        guard normalizedDate >= startDate else { return false }

        if let cappedEnd = endDate, normalizedDate > cappedEnd.startOfDay {
            return false
        }

        let daysFromStart = normalizedDate.days(since: startDate.startOfDay)

        switch frequency {
        case .once:
            return normalizedDate == startDate.startOfDay
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
            let targetDaySeed = dayOfMonthOverride ?? startComponents.day
            guard let targetDay = targetDaySeed,
                  let currentDay = currentComponents.day,
                  let month = currentComponents.month,
                  let year = currentComponents.year
            else {
                return false
            }

            let monthsFromStart = calendar.dateComponents([.month], from: startDate, to: normalizedDate).month ?? 0
            guard monthsFromStart % interval == 0 else { return false }

            let daysInCurrentMonth = daysInMonth(year: year, month: month)
            let desiredDay = min(targetDay, daysInCurrentMonth)
            return currentDay == desiredDay
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
