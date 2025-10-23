//
//  HabitsRepository.swift
//  Sherpa
//
//  Defines a SwiftData-backed repository seam so persistence can evolve
//  without forcing the view model to depend directly on SwiftData APIs.
//

import Foundation
import SwiftData

@MainActor
protocol HabitsRepository {
    /// Persist progress hook. Current model is not storing numeric progress; keep as no-op seam.
    func saveProgress(for instance: HabitInstance, value: Double, goal: Double, unit: String) async throws
}

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
