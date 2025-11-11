import Foundation
import SwiftData

/// Represents a habit definition.
@Model
final class Habit {
    var title: String
    var detail: String?
    var createdAt: Date
    var colorHex: String?
    var iconSymbolName: String = "flame.fill"
    var targetValue: Double = 1
    var targetUnitRawValue: String = HabitTargetUnit.count.rawValue
    var reminderTimeSeconds: Double?
    var shouldNotify: Bool = false
    var areaIdentifier: String?
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
        iconSymbolName: String = "flame.fill",
        targetValue: Double = 1,
        targetUnit: HabitTargetUnit = .count,
        reminderTimeSeconds: Double? = nil,
        shouldNotify: Bool = false,
        areaIdentifier: String? = nil,
        isArchived: Bool = false,
        recurrenceRule: RecurrenceRule,
        paletteIdentifier: Int = 0
    ) {
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
        self.colorHex = colorHex
        self.iconSymbolName = iconSymbolName
        self.targetValue = targetUnit.sanitizedValue(targetValue)
        self.targetUnitRawValue = targetUnit.rawValue
        self.reminderTimeSeconds = reminderTimeSeconds
        self.shouldNotify = shouldNotify
        self.areaIdentifier = areaIdentifier
        self.paletteIdentifier = paletteIdentifier
        self.isArchived = isArchived
        self.instances = []
        self.recurrenceRule = recurrenceRule
    }

    var targetUnit: HabitTargetUnit {
        HabitTargetUnit(rawValue: targetUnitRawValue) ?? .count
    }

    func updateTarget(value: Double, unit: HabitTargetUnit) {
        targetUnitRawValue = unit.rawValue
        targetValue = unit.sanitizedValue(value)
    }
}
