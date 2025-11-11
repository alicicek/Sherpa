import Foundation
import SwiftUI

struct HabitColorOption: Identifiable, Hashable {
    let id: String
    let color: Color
    let hex: String
}

enum HabitColorPalette {
    static let options: [HabitColorOption] = [
        HabitColorOption(id: "mint", color: DesignTokens.Colors.accentMint, hex: "#7AE0B8"),
        HabitColorOption(id: "purple", color: DesignTokens.Colors.accentPurple, hex: "#7869FF"),
        HabitColorOption(id: "gold", color: DesignTokens.Colors.accentGold, hex: "#F5C34D"),
        HabitColorOption(id: "pink", color: DesignTokens.Colors.accentPink, hex: "#FF90C2"),
        HabitColorOption(id: "blue", color: DesignTokens.Colors.accentBlue, hex: "#46A8E0"),
        HabitColorOption(id: "orange", color: DesignTokens.Colors.accentOrange, hex: "#FF9E5A")
    ]

    static var defaultOption: HabitColorOption {
        options.first ?? HabitColorOption(id: "mint", color: DesignTokens.Colors.accentMint, hex: "#7AE0B8")
    }
}

struct HabitAreaOption: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
}

enum HabitAreaCatalog {
    static let options: [HabitAreaOption] = [
        HabitAreaOption(id: "health", name: "Health", symbol: "heart.fill"),
        HabitAreaOption(id: "mindfulness", name: "Mindfulness", symbol: "sparkles"),
        HabitAreaOption(id: "learning", name: "Learning", symbol: "book.fill"),
        HabitAreaOption(id: "career", name: "Career", symbol: "briefcase.fill"),
        HabitAreaOption(id: "finance", name: "Finance", symbol: "dollarsign.circle.fill")
    ]
}

enum HabitRepeatPattern: Equatable {
    case none
    case daily(interval: Int)
    case weekly(interval: Int, weekdays: Set<Weekday>)
    case monthly(interval: Int, day: Int)
}

enum HabitRepeatEnd: Equatable {
    case never
    case onDate(Date)
    case afterOccurrences(Int)

    var summary: String {
        switch self {
        case .never:
            return "Never"
        case .onDate(let date):
            return "On \(HabitScheduleConfiguration.dateFormatter.string(from: date))"
        case .afterOccurrences(let count):
            return "After \(count) time\(count == 1 ? "" : "s")"
        }
    }

    func endDate(from startDate: Date) -> Date? {
        switch self {
        case .never, .afterOccurrences:
            return nil
        case .onDate(let date):
            let normalized = date.startOfDay
            return max(normalized, startDate.startOfDay)
        }
    }

    func occurrenceLimit() -> Int? {
        switch self {
        case .afterOccurrences(let count):
            return max(1, count)
        case .never, .onDate:
            return nil
        }
    }
}

struct HabitRepeatConfiguration: Equatable {
    var pattern: HabitRepeatPattern
    var end: HabitRepeatEnd

    static func `default`() -> HabitRepeatConfiguration {
        HabitRepeatConfiguration(pattern: .none, end: .never)
    }

    func summary(startDate: Date) -> String {
        switch pattern {
        case .none:
            return "Does not repeat"
        case .daily(let interval):
            return interval == 1 ? "Every day" : "Every \(interval) days"
        case .weekly(let interval, let weekdays):
            let sorted = weekdays.sorted { $0.rawValue < $1.rawValue }
            if weekdays.count == 5, weekdays == Set([.monday, .tuesday, .wednesday, .thursday, .friday]) {
                return interval == 1 ? "Weekdays" : "Weekdays every \(interval) weeks"
            }
            if weekdays.count == 1, let day = sorted.first {
                return interval == 1 ? "Every \(day.longName)" : "Every \(interval) weeks on \(day.longName)"
            }
            let labels = sorted.map(\.shortSymbol).joined(separator: ", ")
            return interval == 1 ? "Weekly on \(labels)" : "Every \(interval) weeks (\(labels))"
        case .monthly(let interval, let day):
            let suffix = ordinalSuffix(for: day)
            return interval == 1 ? "Monthly on the \(day)\(suffix)" : "Every \(interval) months on the \(day)\(suffix)"
        }
    }

    func recurrenceRule(startDate: Date) -> RecurrenceRule {
        let normalizedStart = startDate.startOfDay
        switch pattern {
        case .none:
            return RecurrenceRule(frequency: .once, interval: 1, startDate: normalizedStart)
        case .daily(let interval):
            return RecurrenceRule(
                frequency: .daily,
                interval: max(1, interval),
                startDate: normalizedStart,
                weekdays: [],
                dayOfMonthOverride: nil,
                endDate: end.endDate(from: normalizedStart),
                occurrenceLimit: end.occurrenceLimit()
            )
        case .weekly(let interval, let weekdays):
            let sanitizedDays = sanitizeWeekdays(weekdays, fallback: normalizedStart)
            return RecurrenceRule(
                frequency: .weekly,
                interval: max(1, interval),
                startDate: normalizedStart,
                weekdays: sanitizedDays.map(\.rawValue),
                dayOfMonthOverride: nil,
                endDate: end.endDate(from: normalizedStart),
                occurrenceLimit: end.occurrenceLimit()
            )
        case .monthly(let interval, let day):
            let firstOccurrence = adjustedMonthlyStart(from: normalizedStart, desiredDay: day)
            let targetDay = min(max(1, day), 31)
            return RecurrenceRule(
                frequency: .monthly,
                interval: max(1, interval),
                startDate: firstOccurrence,
                weekdays: [],
                dayOfMonthOverride: targetDay,
                endDate: end.endDate(from: normalizedStart),
                occurrenceLimit: end.occurrenceLimit()
            )
        }
    }

    private func sanitizeWeekdays(_ weekdays: Set<Weekday>, fallback startDate: Date) -> [Weekday] {
        if weekdays.isEmpty {
            let fallbackDay = Weekday(rawValue: startDate.weekdayIndex) ?? .monday
            return [fallbackDay]
        }
        return weekdays.sorted { $0.rawValue < $1.rawValue }
    }

    private func adjustedMonthlyStart(from startDate: Date, desiredDay: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: startDate)
        let clampedDay = min(max(1, desiredDay), 31)
        components.day = clampedDay

        if let sameMonth = calendar.date(from: components), sameMonth >= startDate {
            return sameMonth.startOfDay
        }

        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return startDate
        }
        var nextComponents = calendar.dateComponents([.year, .month], from: nextMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: nextMonth)?.count ?? 30
        nextComponents.day = min(clampedDay, daysInMonth)
        return calendar.date(from: nextComponents)?.startOfDay ?? startDate
    }

    private func ordinalSuffix(for value: Int) -> String {
        let ones = value % 10
        let tens = (value / 10) % 10
        if tens == 1 {
            return "th"
        }
        switch ones {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}

struct HabitScheduleConfiguration: Equatable {
    enum TimeSelection: Equatable {
        case anytime
        case at(DateComponents)

        var description: String {
            switch self {
            case .anytime:
                return "Any time"
            case .at(let components):
                guard let date = Calendar.current.date(from: components) else { return "At time" }
                return HabitScheduleConfiguration.timeFormatter.string(from: date)
            }
        }
    }

    var startDate: Date
    var timeSelection: TimeSelection
    var notify: Bool

    init(startDate: Date = Date().startOfDay, timeSelection: TimeSelection = .anytime, notify: Bool = false) {
        self.startDate = startDate.startOfDay
        self.timeSelection = timeSelection
        self.notify = notify
    }

    var summary: String {
        let normalizedDateText: String
        if Calendar.current.isDateInToday(startDate) {
            normalizedDateText = "Today"
        } else if Calendar.current.isDateInTomorrow(startDate) {
            normalizedDateText = "Tomorrow"
        } else {
            normalizedDateText = HabitScheduleConfiguration.dateFormatter.string(from: startDate)
        }

        let notifyText = notify ? "Notify On" : "Notify Off"
        return "\(normalizedDateText) • \(timeSelection.description) • \(notifyText)"
    }

    var reminderSecondsFromMidnight: Double? {
        guard case .at(let components) = timeSelection,
              let hour = components.hour
        else { return nil }
        let minutes = components.minute ?? 0
        return Double(hour * 3600 + minutes * 60)
    }

    mutating func setTimeSelection(_ selection: TimeSelection) {
        timeSelection = selection
        if case .at = selection {
            notify = true
        }
    }

    mutating func updateStartDate(_ date: Date) {
        startDate = date.startOfDay
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

}

struct AddHabitFormState {
    private(set) var baselineDate: Date
    var name: String = ""
    var selectedIconId: String
    var selectedColor: HabitColorOption
    var targetValue: Double
    var targetUnit: HabitTargetUnit
    var repeatConfiguration: HabitRepeatConfiguration
    var schedule: HabitScheduleConfiguration
    var selectedArea: HabitAreaOption?

    init(now: Date = Date()) {
        let normalized = now.startOfDay
        baselineDate = normalized
        selectedIconId = HabitIconCatalog.defaultIcon.id
        selectedColor = HabitColorPalette.defaultOption
        targetUnit = .count
        targetValue = targetUnit.defaultValue
        repeatConfiguration = .default()
        schedule = HabitScheduleConfiguration(startDate: normalized)
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasDraftChanges: Bool {
        trimmedName.isEmpty == false
            || selectedIconId != HabitIconCatalog.defaultIcon.id
            || selectedColor.id != HabitColorPalette.defaultOption.id
            || targetUnit != .count
            || targetValue != targetUnit.defaultValue
            || repeatConfiguration.pattern != .none
            || schedule.startDate != baselineDate
            || schedule.timeSelection != .anytime
            || schedule.notify
            || selectedArea != nil
    }

    var targetPreview: String {
        HabitTargetUnitFormatter.display(for: targetValue, unit: targetUnit)
    }

    var repeatSummary: String {
        repeatConfiguration.summary(startDate: schedule.startDate)
    }

    var dateSummary: String {
        schedule.summary
    }

    var isSavable: Bool {
        let count = trimmedName.count
        return count >= 1 && count <= 60 && targetValue > 0
    }

    var colorHex: String? {
        selectedColor.hex
    }

    var iconOption: HabitIconOption {
        HabitIconCatalog.icon(for: selectedIconId) ?? HabitIconCatalog.defaultIcon
    }

    var reminderSeconds: Double? {
        schedule.reminderSecondsFromMidnight
    }

    var shouldNotify: Bool {
        schedule.notify
    }

    mutating func reset(now: Date = Date()) {
        self = AddHabitFormState(now: now)
    }
}

enum HabitTargetUnitFormatter {
    static func display(for value: Double, unit: HabitTargetUnit) -> String {
        unit.formattedValue(value)
    }
}
