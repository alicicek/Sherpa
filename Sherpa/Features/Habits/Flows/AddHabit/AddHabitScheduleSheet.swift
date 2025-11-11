import SwiftUI

struct AddHabitScheduleSheet: View {
    @Binding var schedule: HabitScheduleConfiguration

    @Environment(\.dismiss) private var dismiss
    @State private var quickDateSelection: QuickDate = .today
    @State private var customDate: Date = Date()
    @State private var timeMode: TimeMode = .any
    @State private var customTime: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        quickDateButton(.today, label: "Today")
                        quickDateButton(.tomorrow, label: "Tomorrow")
                        quickDateButton(.custom, label: "On a date…")
                    }
                    .listRowInsets(.init())
                    .padding(.vertical, DesignTokens.Spacing.xs)

                    if quickDateSelection == .custom {
                        DatePicker(
                            "Select date",
                            selection: $customDate,
                            in: Date().startOfDay...,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .onChange(of: customDate) { _, newValue in
                            schedule.updateStartDate(newValue)
                        }
                    }
                }

                Section("Time") {
                    Picker("Reminder time", selection: $timeMode) {
                        Text("Any time").tag(TimeMode.any)
                        Text("At time…").tag(TimeMode.at)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: timeMode) { _, newValue in
                        switch newValue {
                        case .any:
                            schedule.setTimeSelection(.anytime)
                        case .at:
                            let components = Calendar.current.dateComponents([.hour, .minute], from: customTime)
                            schedule.setTimeSelection(.at(components))
                        }
                    }

                    if timeMode == .at {
                        DatePicker(
                            "Choose time",
                            selection: $customTime,
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(.wheel)
                        .onChange(of: customTime) { _, newValue in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            schedule.setTimeSelection(.at(components))
                        }
                    }
                }

                Section("Notifications") {
                    Toggle(isOn: Binding(get: {
                        schedule.notify
                    }, set: { newValue in
                        schedule.notify = newValue
                        if newValue == false {
                            schedule.setTimeSelection(.anytime)
                            timeMode = .any
                        } else if timeMode == .any {
                            timeMode = .at
                            let components = Calendar.current.dateComponents([.hour, .minute], from: customTime)
                            schedule.setTimeSelection(.at(components))
                        }
                    })) {
                        Text("Notify me")
                    }
                }
            }
            .navigationTitle("Date & time")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear(perform: configureInitialState)
        }
    }

    private func quickDateButton(_ option: QuickDate, label: String) -> some View {
        Button {
            quickDateSelection = option
            switch option {
            case .today:
                schedule.updateStartDate(Date())
            case .tomorrow:
                schedule.updateStartDate(Date().adding(days: 1))
            case .custom:
                customDate = schedule.startDate
            }
        } label: {
            Text(label)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(
                    Capsule()
                        .fill(quickDateSelection == option ? Color.sherpaPrimary.opacity(0.15) : Color(.secondarySystemBackground))
                )
        }
        .buttonStyle(.plain)
    }
}

private extension AddHabitScheduleSheet {
    enum QuickDate {
        case today
        case tomorrow
        case custom
    }

    enum TimeMode {
        case any
        case at
    }

    func configureInitialState() {
        if Calendar.current.isDateInToday(schedule.startDate) {
            quickDateSelection = .today
        } else if Calendar.current.isDateInTomorrow(schedule.startDate) {
            quickDateSelection = .tomorrow
        } else {
            quickDateSelection = .custom
            customDate = schedule.startDate
        }

        switch schedule.timeSelection {
        case .anytime:
            timeMode = .any
        case .at(let components):
            timeMode = .at
            if let date = Calendar.current.date(from: components) {
                customTime = date
            }
        }
    }
}
