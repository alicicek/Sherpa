import Foundation

/// Supported measurement units for a habit's daily target.
enum HabitTargetUnit: String, CaseIterable, Identifiable, Codable {
    case calories = "cal"
    case count
    case grams
    case seconds
    case minutes = "min"
    case hours
    case steps
    case meters = "m"
    case kilometers = "km"
    case miles = "mile"

    var id: String { rawValue }

    /// Short label surfaced in compact UI (e.g., progress counters).
    var shortLabel: String {
        switch self {
        case .calories: return "cal"
        case .count: return "times"
        case .grams: return "g"
        case .seconds: return "sec"
        case .minutes: return "min"
        case .hours: return "hr"
        case .steps: return "steps"
        case .meters: return "m"
        case .kilometers: return "km"
        case .miles: return "mi"
        }
    }

    /// Full unit name used in picker lists.
    var displayName: String {
        switch self {
        case .calories: return "Calories"
        case .count: return "Count"
        case .grams: return "Grams"
        case .seconds: return "Seconds"
        case .minutes: return "Minutes"
        case .hours: return "Hours"
        case .steps: return "Steps"
        case .meters: return "Meters"
        case .kilometers: return "Kilometers"
        case .miles: return "Miles"
        }
    }

    /// Whether the unit should allow decimal input.
    var allowsDecimalInput: Bool {
        switch self {
        case .grams, .hours, .meters, .kilometers, .miles:
            return true
        case .calories, .count, .seconds, .minutes, .steps:
            return false
        }
    }

    /// Default value suggested when a user switches to the unit.
    var defaultValue: Double {
        switch self {
        case .steps:
            return 1_000
        case .minutes:
            return 30
        case .hours:
            return 1
        case .seconds:
            return 30
        default:
            return 1
        }
    }

    /// Optional preset values that can be surfaced as quick chips.
    var presetSuggestions: [Double] {
        switch self {
        case .calories:
            return [250, 500, 750]
        case .steps:
            return [5_000, 8_000, 10_000]
        case .minutes:
            return [10, 30, 45]
        case .hours:
            return [1, 1.5, 2]
        case .grams:
            return [50, 100, 150]
        default:
            return []
        }
    }

    /// Formats a value with the correct number of fraction digits and pluralisation.
    func formattedValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = allowsDecimalInput ? 1 : 0
        formatter.minimumFractionDigits = allowsDecimalInput ? 0 : 0
        formatter.numberStyle = .decimal

        let sanitized = sanitizedValue(value)
        let numberString = formatter.string(from: NSNumber(value: sanitized)) ?? "\(sanitized)"
        let unitLabel = label(for: sanitized)
        return "\(numberString) \(unitLabel)"
    }

    /// Ensures stored values obey the unit's decimal policy.
    func sanitizedValue(_ value: Double) -> Double {
        guard allowsDecimalInput == false else {
            return max(0, value)
        }
        return max(0, round(value))
    }

    private func label(for value: Double) -> String {
        let isSingular = abs(value - 1) < 0.0001
        switch self {
        case .calories:
            return "cal"
        case .count:
            return isSingular ? "time" : "times"
        case .grams:
            return "g"
        case .seconds:
            return isSingular ? "sec" : "sec"
        case .minutes:
            return isSingular ? "min" : "min"
        case .hours:
            return isSingular ? "hour" : "hours"
        case .steps:
            return isSingular ? "step" : "steps"
        case .meters:
            return isSingular ? "meter" : "meters"
        case .kilometers:
            return isSingular ? "kilometer" : "kilometers"
        case .miles:
            return isSingular ? "mile" : "miles"
        }
    }
}
