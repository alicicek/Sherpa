import Foundation
import SwiftData

/// Represents a habit definition.
@Model
final class Habit {
    var title: String
    var detail: String?
    var createdAt: Date
    var colorHex: String?
    var paletteIdentifier: Int = 0
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \HabitInstance.habit)
    var instances: [HabitInstance]

    @Relationship(deleteRule: .nullify)
    var recurrenceRule: RecurrenceRule

    init(
        title: String,
        detail: String? = nil,
        createdAt: Date = .now,
        colorHex: String? = nil,
        isArchived: Bool = false,
        recurrenceRule: RecurrenceRule,
        paletteIdentifier: Int = 0
    ) {
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
        self.colorHex = colorHex
        self.paletteIdentifier = paletteIdentifier
        self.isArchived = isArchived
        self.instances = []
        self.recurrenceRule = recurrenceRule
    }
}
