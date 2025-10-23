import Foundation
import SwiftData

/// Default SwiftData-backed repository (no-op until progress is modeled).
@MainActor
struct SwiftDataHabitsRepository: HabitsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func saveProgress(for instance: HabitInstance, value: Double, goal: Double, unit: String) async throws {
        if context.hasChanges {
            try? context.save()
        }
    }
}
