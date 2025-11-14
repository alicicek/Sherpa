import SwiftUI

struct AddHabitRepeatSheet: View {
    @Binding var configuration: HabitRepeatConfiguration
    let startDate: Date

    @Environment(\.dismiss) private var dismiss
    @State private var showingCustomSheet = false
    @State private var showingEndsSheet = false

    private var startWeekday: Weekday {
        Weekday(rawValue: startDate.weekdayIndex) ?? .monday
    }

    private var startDayOfMonth: Int {
        Calendar.current.component(.day, from: startDate)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Repeat") {
                    repeatOption(
                        title: "Does not repeat",
                        subtitle: "Creates a single occurrence",
                        isSelected: configuration.pattern == .none
                    ) {
                        configuration.pattern = .none
                    }

                    repeatOption(
                        title: "Every day",
                        subtitle: "Repeats daily",
                        isSelected: configuration.pattern == .daily(interval: 1)
                    ) {
                        configuration.pattern = .daily(interval: 1)
                    }

                    repeatOption(
                        title: "Every weekday",
                        subtitle: "Mon–Fri",
                        isSelected: configuration.pattern == .weekly(interval: 1, weekdays: Weekday.weekdaySet)
                    ) {
                        configuration.pattern = .weekly(interval: 1, weekdays: Weekday.weekdaySet)
                    }

                    repeatOption(
                        title: "Every week on \(startWeekday.longName)",
                        subtitle: "Repeats weekly",
                        isSelected: configuration.pattern == .weekly(interval: 1, weekdays: [startWeekday])
                    ) {
                        configuration.pattern = .weekly(interval: 1, weekdays: [startWeekday])
                    }

                    let suffix = ordinalSuffix(for: startDayOfMonth)
                    repeatOption(
                        title: "Every month on the \(startDayOfMonth)\(suffix)",
                        subtitle: "Repeats monthly",
                        isSelected: configuration.pattern == .monthly(interval: 1, day: startDayOfMonth)
                    ) {
                        configuration.pattern = .monthly(interval: 1, day: startDayOfMonth)
                    }
                }

                Section {
                    Button {
                        showingCustomSheet = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Custom…")
                                    .foregroundStyle(Color.sherpaTextPrimary)
                                Text(configuration.summary(startDate: startDate))
                                    .font(.caption)
                                    .foregroundStyle(Color.sherpaTextSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.sherpaTextSecondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Section("Ends") {
                    Button {
                        showingEndsSheet = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(configuration.end.summary)
                                    .foregroundStyle(Color.sherpaTextPrimary)
                                Text("Tap to change end conditions")
                                    .font(.caption)
                                    .foregroundStyle(Color.sherpaTextSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.sherpaTextSecondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Repeat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingCustomSheet) {
                HabitCustomRepeatView(pattern: $configuration.pattern, startDate: startDate)
            }
            .sheet(isPresented: $showingEndsSheet) {
                HabitRepeatEndsSheet(end: $configuration.end, startDate: startDate)
            }
        }
    }
}

private extension AddHabitRepeatSheet {
    func repeatOption(title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(Color.sherpaTextPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.sherpaTextSecondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.sherpaPrimary : Color.sherpaTextSecondary.opacity(0.4))
            }
            .padding(.vertical, DesignTokens.Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func ordinalSuffix(for value: Int) -> String {
        let ones = value % 10
        let tens = (value / 10) % 10
        if tens == 1 { return "th" }
        switch ones {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}

private struct HabitCustomRepeatView: View {
    @Binding var pattern: HabitRepeatPattern
    let startDate: Date

    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .daily
    @State private var dailyInterval: Int = 1
    @State private var weeklyInterval: Int = 1
    @State private var selectedWeekdays: Set<Weekday> = Weekday.weekdaySet
    @State private var monthlyInterval: Int = 1
    @State private var selectedDay: Int = 1

    private let dayRange = Array(1...31)

    var body: some View {
        NavigationStack {
            Form {
                Picker("Pattern", selection: $mode) {
                    Text("Daily").tag(Mode.daily)
                    Text("Weekly").tag(Mode.weekly)
                    Text("Monthly").tag(Mode.monthly)
                }
                .pickerStyle(.segmented)
                .onChange(of: mode) { _, _ in
                    syncPatternFromControls()
                }

                switch mode {
                case .daily:
                    Stepper("Every \(dailyInterval) day(s)", value: $dailyInterval, in: 1...30)
                        .onChange(of: dailyInterval) { _, _ in syncPatternFromControls() }
                case .weekly:
                    Stepper("Every \(weeklyInterval) week(s)", value: $weeklyInterval, in: 1...12)
                        .onChange(of: weeklyInterval) { _, _ in syncPatternFromControls() }
                    WeekdaySelectionView(selected: $selectedWeekdays)
                        .onChange(of: selectedWeekdays) { _, _ in syncPatternFromControls() }
                case .monthly:
                    Stepper("Every \(monthlyInterval) month(s)", value: $monthlyInterval, in: 1...12)
                        .onChange(of: monthlyInterval) { _, _ in syncPatternFromControls() }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                        ForEach(dayRange, id: \.self) { day in
                            let isSelected = day == selectedDay
                            Text("\(day)")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(isSelected ? Color.sherpaPrimary : Color(.tertiarySystemBackground))
                                )
                                .foregroundStyle(isSelected ? Color.white : Color.sherpaTextSecondary)
                                .onTapGesture {
                                    selectedDay = day
                                    syncPatternFromControls()
                                }
                        }
                    }
                    .padding(.vertical, DesignTokens.Spacing.sm)
                }
            }
            .navigationTitle("Custom repeat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear(perform: configureInitialState)
        }
    }

    enum Mode: Hashable {
        case daily
        case weekly
        case monthly
    }

    private func configureInitialState() {
        switch pattern {
        case .none:
            mode = .daily
        case .daily(let interval):
            mode = .daily
            dailyInterval = max(1, interval)
        case .weekly(let interval, let weekdays):
            mode = .weekly
            weeklyInterval = max(1, interval)
            selectedWeekdays = weekdays.isEmpty ? [Weekday(rawValue: startDate.weekdayIndex) ?? .monday] : weekdays
        case .monthly(let interval, let day):
            mode = .monthly
            monthlyInterval = max(1, interval)
            selectedDay = min(max(1, day), 31)
        }
        syncPatternFromControls()
    }

    private func syncPatternFromControls() {
        switch mode {
        case .daily:
            pattern = .daily(interval: dailyInterval)
        case .weekly:
            let sanitized = selectedWeekdays.isEmpty ? [Weekday(rawValue: startDate.weekdayIndex) ?? .monday] : selectedWeekdays
            pattern = .weekly(interval: weeklyInterval, weekdays: sanitized)
        case .monthly:
            pattern = .monthly(interval: monthlyInterval, day: selectedDay)
        }
    }
}

private struct HabitRepeatEndsSheet: View {
    @Binding var end: HabitRepeatEnd
    let startDate: Date

    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .never
    @State private var selectedDate: Date = Date()
    @State private var occurrenceCount: Int = 5

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("End", selection: $mode) {
                        Text("Never").tag(Mode.never)
                        Text("On date").tag(Mode.onDate)
                        Text("After occurrences").tag(Mode.after)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: mode) { _, _ in syncEndFromControls() }
                }

                if mode == .onDate {
                    DatePicker("End date", selection: $selectedDate, in: startDate...)
                        .datePickerStyle(.graphical)
                        .onChange(of: selectedDate) { _, _ in syncEndFromControls() }
                } else if mode == .after {
                    Stepper("After \(occurrenceCount) occurrence(s)", value: $occurrenceCount, in: 1...500)
                        .onChange(of: occurrenceCount) { _, _ in syncEndFromControls() }
                }
            }
            .navigationTitle("Ends")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear(perform: configureInitialState)
        }
    }

    enum Mode: Hashable {
        case never
        case onDate
        case after
    }

    private func configureInitialState() {
        switch end {
        case .never:
            mode = .never
        case .onDate(let date):
            mode = .onDate
            selectedDate = date
        case .afterOccurrences(let count):
            mode = .after
            occurrenceCount = max(1, count)
        }
    }

    private func syncEndFromControls() {
        switch mode {
        case .never:
            end = .never
        case .onDate:
            end = .onDate(selectedDate)
        case .after:
            end = .afterOccurrences(occurrenceCount)
        }
    }
}

private extension Weekday {
    static var weekdaySet: Set<Weekday> {
        [.monday, .tuesday, .wednesday, .thursday, .friday]
    }
}
