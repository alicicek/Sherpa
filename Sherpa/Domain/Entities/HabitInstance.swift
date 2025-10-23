import Foundation
import SwiftData

/// Completion state for an instance.
enum CompletionState: String, Codable, CaseIterable {
    case pending
    case completed
    case skipped
    case skippedWithNote

    var isCompleted: Bool {
        self == .completed
    }

    var isSkippedWithNote: Bool {
        self == .skippedWithNote
    }
}

/// Represents a scheduled occurrence for either a habit or a task.
@Model
final class HabitInstance {
    var date: Date
    var status: CompletionState
    var note: String?
    var completedAt: Date?

    @Relationship var habit: Habit?
    @Relationship var task: Task?

    init(date: Date, status: CompletionState = .pending, note: String? = nil, habit: Habit? = nil, task: Task? = nil) {
        self.date = date.startOfDay
        self.status = status
        self.note = note
        self.completedAt = nil
        self.habit = habit
        self.task = task
    }

    var displayName: String {
        habit?.title ?? task?.title ?? "Untitled"
    }

    var isHabit: Bool {
        habit != nil
    }
}
