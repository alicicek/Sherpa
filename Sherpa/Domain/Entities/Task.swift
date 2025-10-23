import Foundation
import SwiftData

/// Represents a task definition (non-streak affecting).
@Model
final class Task {
    var title: String
    var detail: String?
    var createdAt: Date
    var dueDate: Date?
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \HabitInstance.task)
    var instances: [HabitInstance]

    @Relationship(deleteRule: .nullify)
    var recurrenceRule: RecurrenceRule?

    init(
        title: String,
        detail: String? = nil,
        createdAt: Date = .now,
        dueDate: Date? = nil,
        isArchived: Bool = false,
        recurrenceRule: RecurrenceRule? = nil
    ) {
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
        self.dueDate = dueDate?.startOfDay
        self.isArchived = isArchived
        self.instances = []
        self.recurrenceRule = recurrenceRule
    }
}
