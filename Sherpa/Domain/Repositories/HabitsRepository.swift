import Foundation
import SwiftData

/// Defines persistence hooks for habits and their instances.
@MainActor
protocol HabitsRepository {
    /// Persist progress hook. Current model is not storing numeric progress; keep as no-op seam.
    func saveProgress(for instance: HabitInstance, value: Double, goal: Double, unit: String) async throws
}
