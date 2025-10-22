//
//  AddRoutineSheet.swift
//  Sherpa
//
//  Extracted from HabitsHomeView to keep the main feature file focused on list display.
//

import SwiftUI
import SwiftData
import OSLog

private enum AddRoutineConstants {
    static let suggestionSpacing = DesignTokens.Spacing.sm
}

struct AddRoutineSheet: View {
    enum ItemKind: String, CaseIterable, Identifiable {
        case habit
        case task

        var id: String { rawValue }

        var label: String {
            switch self {
            case .habit: return L10n.string("addroutine.type.picker.habit")
            case .task: return L10n.string("addroutine.type.picker.task")
            }
        }

        var icon: String {
            switch self {
            case .habit: return "flame.fill"
            case .task: return "checkmark.circle.fill"
            }
        }
    }

    private struct Suggestion: Identifiable {
        let id = UUID()
        let title: String
        let detail: String?
        let frequency: RecurrenceFrequency
        let weekdays: Set<Weekday>?
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Binding var isPresented: Bool
    let onComplete: () -> Void

    @State private var itemKind: ItemKind = .habit
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var frequency: RecurrenceFrequency = .daily
    @State private var interval: Int = 1
    @State private var selectedWeekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    @State private var dueDate: Date = Date()

    private var suggestions: [Suggestion] {
        switch itemKind {
        case .habit:
            return [
                Suggestion(title: "Morning stretch", detail: "5 minute warm-up", frequency: .daily, weekdays: nil),
                Suggestion(title: "Deep tidy", detail: "30m reset", frequency: .weekly, weekdays: [.saturday]),
                Suggestion(title: "Drink water", detail: "Hydrate before coffee", frequency: .daily, weekdays: nil)
            ]
        case .task:
            return [
                Suggestion(title: "Submit assignment", detail: "Wrap before midnight", frequency: .daily, weekdays: nil),
                Suggestion(title: "Meal prep", detail: "Sunday planning", frequency: .weekly, weekdays: [.sunday]),
                Suggestion(title: "Budget review", detail: "Payday check-in", frequency: .monthly, weekdays: nil)
            ]
        }
    }

    private var cadenceLabel: String {
        switch frequency {
        case .weekly: return L10n.string("addroutine.cadence.weeks")
        case .monthly: return L10n.string("addroutine.cadence.months")
        case .daily: fallthrough
        @unknown default: return L10n.string("addroutine.cadence.days")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    Picker("Type", selection: $itemKind) {
                        ForEach(ItemKind.allCases) { kind in
                            Label(kind.label, systemImage: kind.icon).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text(L10n.string("addroutine.suggestions.heading"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.sherpaTextSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AddRoutineConstants.suggestionSpacing) {
                                ForEach(suggestions) { suggestion in
                                    Button {
                                        apply(suggestion: suggestion)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(suggestion.title)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(Color.sherpaTextPrimary)
                                            if let detail = suggestion.detail {
                                                Text(detail)
                                                    .font(.caption)
                                                    .foregroundStyle(Color.sherpaTextSecondary)
                                            }
                                        }
                                        .padding(.horizontal, DesignTokens.Spacing.md)
                                        .padding(.vertical, DesignTokens.Spacing.sm)
                                        .background(Color.white.opacity(0.9))
                                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous))
                                        .shadow(color: Color.black.opacity(0.05), radius: 6, y: 3)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    VStack(spacing: DesignTokens.Spacing.md) {
                        TextField(L10n.string("addroutine.field.title"), text: $title)
                            .textInputAutocapitalization(.words)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )

                        TextField(L10n.string("addroutine.field.notes"), text: $detail, axis: .vertical)
                            .lineLimit(2...4)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text(L10n.string("addroutine.schedule.heading"))
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Color.sherpaTextPrimary)

                            Picker("Frequency", selection: $frequency) {
                                ForEach(RecurrenceFrequency.allCases) { freq in
                                    Text(L10n.string("addroutine.frequency.\(freq.rawValue)"))
                                        .tag(freq)
                                }
                            }
                            .pickerStyle(.segmented)

                            Stepper(value: $interval, in: 1...30) {
                                let cadence = "\(interval) \(cadenceLabel)"
                                Text(L10n.string("addroutine.stepper.every", cadence))
                            }

                            if frequency == .weekly {
                                WeekdaySelectionView(selected: $selectedWeekdays)
                            }

                            if itemKind == .task && frequency == .daily {
                                DatePicker(L10n.string("addroutine.dueDate.label"), selection: $dueDate, displayedComponents: [.date])
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
            .navigationTitle(itemKind == .habit ? L10n.string("addroutine.sheet.title.habit") : L10n.string("addroutine.sheet.title.task"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("addroutine.button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("addroutine.button.save")) { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func apply(suggestion: Suggestion) {
        title = suggestion.title
        detail = suggestion.detail ?? ""
        frequency = suggestion.frequency
        interval = 1
        if let weekdays = suggestion.weekdays {
            selectedWeekdays = weekdays
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.isEmpty == false else { return }

        var recurrence: RecurrenceRule?
        let shouldCreateRecurrence = itemKind == .habit || frequency != .daily
        if shouldCreateRecurrence {
            let rule = RecurrenceRule(
                frequency: frequency,
                interval: interval,
                startDate: Date().startOfDay,
                weekdays: frequency == .weekly ? selectedWeekdays.map(\.rawValue) : []
            )
            modelContext.insert(rule)
            recurrence = rule
        }

        switch itemKind {
        case .habit:
            guard let recurrence else { return }
            let paletteCount = max(1, DesignTokens.cardPalettes.count)
            let paletteIndex = Int.random(in: 0..<paletteCount)
            let habit = Habit(
                title: trimmedTitle,
                detail: detail.isEmpty ? nil : detail,
                recurrenceRule: recurrence,
                paletteIdentifier: paletteIndex
            )
            modelContext.insert(habit)
        case .task:
            let task = Task(
                title: trimmedTitle,
                detail: detail.isEmpty ? nil : detail,
                dueDate: frequency == .daily ? dueDate.startOfDay : nil,
                recurrenceRule: recurrence
            )
            modelContext.insert(task)
        }

        do {
            try modelContext.save()
            onComplete()
            isPresented = false
        } catch {
            Logger.habits.error("Failed to save new routine: \(error.localizedDescription, privacy: .public)")
        }
    }
}

struct WeekdaySelectionView: View {
    @Binding var selected: Set<Weekday>
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.sm), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.sm) {
            ForEach(Weekday.allCases) { day in
                let isSelected = selected.contains(day)
                Text(day.shortSymbol)
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous)
                            .fill(isSelected ? Color.sherpaPrimary : Color(.tertiarySystemBackground))
                    )
                    .foregroundStyle(isSelected ? Color.white : Color.sherpaTextSecondary)
                    .onTapGesture {
                        if isSelected {
                            selected.remove(day)
                        } else {
                            selected.insert(day)
                        }
                    }
            }
        }
    }
}

struct SkipNoteSheet: View {
    let instance: HabitInstance
    var onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.string("addroutine.skip.section.title")) {
                    TextField(L10n.string("addroutine.skip.reason.placeholder"), text: $note, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle(L10n.string("addroutine.skip.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("generic.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("addroutine.button.save")) {
                        onSave(note.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
