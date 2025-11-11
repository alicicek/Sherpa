import OSLog
import SwiftData
import SwiftUI

private enum AddHabitSheetLayout {
    static let rowCornerRadius: CGFloat = 20
}

struct AddHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Binding var isPresented: Bool
    let onComplete: () -> Void

    @State private var form = AddHabitFormState()
    @State private var showingIconSheet = false
    @State private var showingTargetSheet = false
    @State private var showingRepeatSheet = false
    @State private var showingScheduleSheet = false
    @State private var showingAreaSheet = false
    @State private var saveErrorMessage: String?

    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.md) {
                    nameField
                    actionRow(
                        title: "Icon & Color",
                        detail: form.iconOption.label,
                        accessory: form.selectedColor.color
                    ) {
                        showingIconSheet = true
                    }
                    actionRow(
                        title: "Target per day",
                        detail: form.targetPreview
                    ) {
                        showingTargetSheet = true
                    }
                    actionRow(
                        title: "Repeat",
                        detail: form.repeatSummary
                    ) {
                        showingRepeatSheet = true
                    }
                    actionRow(
                        title: "Date & time",
                        detail: form.dateSummary
                    ) {
                        showingScheduleSheet = true
                    }
                    actionRow(
                        title: form.selectedArea == nil ? "Add to an area" : "Area",
                        detail: form.selectedArea?.name ?? "Optional"
                    ) {
                        showingAreaSheet = true
                    }

                    if form.hasDraftChanges {
                        Button(role: .destructive) {
                            form.reset()
                        } label: {
                            Text("Delete draft")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: AddHabitSheetLayout.rowCornerRadius, style: .continuous)
                                        .fill(Color(.secondarySystemBackground))
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, DesignTokens.Spacing.lg)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.lg)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("New habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(form.isSavable == false)
                }
            }
            .alert("Couldn’t save habit", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { newValue in
                    if newValue == false { saveErrorMessage = nil }
                }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "Unknown error")
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    nameFocused = true
                }
            }
        }
        .sheet(isPresented: $showingIconSheet) {
            AddHabitIconPickerView(selectedIconId: $form.selectedIconId, selectedColor: $form.selectedColor)
        }
        .sheet(isPresented: $showingTargetSheet) {
            AddHabitTargetSheet(value: $form.targetValue, unit: $form.targetUnit)
        }
        .sheet(isPresented: $showingRepeatSheet) {
            AddHabitRepeatSheet(configuration: $form.repeatConfiguration, startDate: form.schedule.startDate)
        }
        .sheet(isPresented: $showingScheduleSheet) {
            AddHabitScheduleSheet(schedule: $form.schedule)
        }
        .sheet(isPresented: $showingAreaSheet) {
            HabitAreaPickerSheet(selection: $form.selectedArea)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("Name")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.sherpaTextSecondary)
            TextField("Enter a habit name…", text: $form.name)
                .focused($nameFocused)
                .textInputAutocapitalization(.words)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AddHabitSheetLayout.rowCornerRadius, style: .continuous)
                        .fill(Color.white)
                )
                .onChange(of: form.name) { _, newValue in
                    if newValue.count > 60 {
                        form.name = String(newValue.prefix(60))
                    }
                }
            Text("\(form.trimmedName.count)/60")
                .font(.caption)
                .foregroundStyle(Color.sherpaTextSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func actionRow(title: String, detail: String, accessory: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.sherpaTextPrimary)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Color.sherpaTextSecondary)
                        .lineLimit(1)
                }
                Spacer()
                if let accessory {
                    Circle()
                        .fill(accessory)
                        .frame(width: 24, height: 24)
                }
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.sherpaTextSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AddHabitSheetLayout.rowCornerRadius, style: .continuous)
                    .fill(Color.white)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens \(title.lowercased()) options")
    }

    private func saveHabit() {
        guard form.isSavable else { return }
        let trimmedTitle = form.trimmedName
        let recurrence = form.repeatConfiguration.recurrenceRule(startDate: form.schedule.startDate)
        modelContext.insert(recurrence)

        let habit = Habit(
            title: trimmedTitle,
            detail: nil,
            colorHex: form.colorHex,
            iconSymbolName: form.iconOption.systemName,
            targetValue: form.targetValue,
            targetUnit: form.targetUnit,
            reminderTimeSeconds: form.reminderSeconds,
            shouldNotify: form.shouldNotify,
            areaIdentifier: form.selectedArea?.id,
            recurrenceRule: recurrence,
            paletteIdentifier: 0
        )

        modelContext.insert(habit)

        do {
            try modelContext.save()
            try ScheduleService(context: modelContext).ensureSchedule(
                from: form.schedule.startDate,
                to: form.schedule.startDate.adding(days: 30)
            )
            onComplete()
            isPresented = false
        } catch {
            Logger.habits.error("Failed to save habit: \(error.localizedDescription, privacy: .public)")
            saveErrorMessage = "Please try again. \(error.localizedDescription)"
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
