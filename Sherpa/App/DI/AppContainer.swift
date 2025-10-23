import Combine
import Foundation
import SwiftData

/// Central dependency container so view models can request collaborators explicitly.
@MainActor
final class AppContainer: ObservableObject {
    let xpStore: XPStore

    init(xpStore: XPStore? = nil) {
        if let xpStore {
            self.xpStore = xpStore
        } else {
            self.xpStore = XPStore()
        }
    }

    func makeHabitsRepository(modelContext: ModelContext) -> HabitsRepository {
        SwiftDataHabitsRepository(context: modelContext)
    }

    func makeScheduleService(modelContext: ModelContext) -> ScheduleService {
        ScheduleService(context: modelContext)
    }
}
