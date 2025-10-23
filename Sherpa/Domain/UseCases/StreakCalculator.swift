import Foundation

/// Simple utility responsible for determining streak eligibility.
struct StreakCalculator {
    /// Returns whether the provided set of instances qualifies for streak credit.
    static func qualifiesForStreak(instances: [HabitInstance]) -> Bool {
        let eligibleInstances = instances.filter { instance in
            guard instance.isHabit else { return false }
            return instance.status != .skippedWithNote
        }
        guard eligibleInstances.isEmpty == false else { return false }

        let completedCount = eligibleInstances.filter { $0.status == .completed }.count
        let threshold = max(1, Int(ceil(Double(eligibleInstances.count) * 0.4)))
        return completedCount >= threshold
    }
}
