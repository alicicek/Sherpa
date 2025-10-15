//
//  HabitsHomeView.swift
//  sherpademo
//
//  Created by Codex on 15/10/2025.
//

import SwiftData
import SwiftUI

struct HabitsHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate: Date = Date().startOfDay
    @State private var showingAddSheet = false
    @State private var skipNoteTarget: HabitInstance?

    private let calendarSpan: Int = 14

    @Query private var instances: [HabitInstance]

    init() {
        let now = Date().startOfDay
        let start = now.adding(days: -21)
        let end = now.adding(days: 21)
        _instances = Query(
            filter: #Predicate { instance in
                instance.date >= start && instance.date <= end
            },
            sort: [SortDescriptor(\HabitInstance.date, order: .forward)]
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.99, green: 0.96, blue: 0.91)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        HabitsHeroCard(
                            date: selectedDate,
                            leagueName: leagueTitle,
                            xpValue: totalXP,
                            message: motivationMessage
                        )

                        CalendarStripView(
                            dates: calendarDates,
                            selectedDate: $selectedDate,
                            daySummaries: daySummaries
                        )

                        if todaysItems.isEmpty {
                            EmptyStateView()
                        } else {
                            VStack(spacing: DesignTokens.Spacing.md) {
                                ForEach(todaysItems.enumerated().map({ $0 }), id: \.element.id) { index, instance in
                                    RoutineCard(
                                        instance: instance,
                                        colorIndex: index,
                                        qualifiesForStreak: daySummaries[selectedDate.startOfDay] ?? false,
                                        onToggleComplete: {
                                            let newStatus: CompletionState = instance.status == .completed ? .pending : .completed
                                            update(instance: instance, status: newStatus, note: instance.note)
                                        },
                                        onSkip: {
                                            update(instance: instance, status: .skipped, note: nil)
                                        },
                                        onSkipWithNote: {
                                            skipNoteTarget = instance
                                        }
                                    )
                                }
                            }
                        }

                        AddHabitsButton {
                            showingAddSheet = true
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.vertical, DesignTokens.Spacing.xl)
                }
            }
            .task {
                await ensureScheduleForVisibleRange()
            }
            .onChange(of: selectedDate) { newValue in
                _Concurrency.Task {
                    await ensureScheduleForVisibleRange(centeredOn: newValue)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddRoutineSheet(isPresented: $showingAddSheet, onComplete: handleAddItem)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $skipNoteTarget) { target in
                SkipNoteSheet(instance: target) { note in
                    update(instance: target, status: .skippedWithNote, note: note)
                }
                .presentationDetents([.fraction(0.35)])
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Derived Values

private extension HabitsHomeView {
    var todaysItems: [HabitInstance] {
        let grouped = Dictionary(grouping: instances) { $0.date.startOfDay }
        return (grouped[selectedDate.startOfDay] ?? [])
            .sorted { lhs, rhs in
                if lhs.isHabit == rhs.isHabit {
                    return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
                }
                return lhs.isHabit && !rhs.isHabit
            }
    }

    var eligibleHabitInstances: [HabitInstance] {
        todaysItems.filter { instance in
            instance.isHabit && instance.status != .skippedWithNote
        }
    }

    var completedCount: Int {
        todaysItems.filter { $0.status == .completed }.count
    }

    var eligibleHabitCount: Int {
        eligibleHabitInstances.count
    }

    var completionProgress: Double {
        guard eligibleHabitCount > 0 else { return 0 }
        return Double(completedCount) / Double(eligibleHabitCount)
    }

    var motivationMessage: String {
        if eligibleHabitCount == 0 {
            return "Take a moment to breathe or plan ahead in the calendar."
        }

        if daySummaries[selectedDate.startOfDay] == true {
            return "Streak secured – everything else is bonus sparkle."
        }

        if completionProgress >= 0.4 {
            return "One more habit locks in today's streak."
        }

        if completedCount == 0 {
            return "Start with the easiest win and keep the energy playful."
        }

        return "Sherpa Goat is cheering for a couple more taps."
    }

    var leagueTitle: String {
        switch completionProgress {
        case 0.75...:
            return "Summit League"
        case 0.4...:
            return "Hilltop League"
        default:
            return "Trailhead League"
        }
    }

    var totalXP: Int {
        todaysItems.reduce(0) { total, instance in
            let baseXP = instance.isHabit ? 25 : 15
            return total + (instance.status == .completed ? baseXP : baseXP / 2)
        }
    }

    var calendarDates: [Date] {
        let base = selectedDate
        return (-3...3).map { base.adding(days: $0) }
    }

    var daySummaries: [Date: Bool] {
        Dictionary(grouping: instances) { $0.date.startOfDay }
            .mapValues { StreakCalculator.qualifiesForStreak(instances: $0) }
    }
}

// MARK: - Behaviours

private extension HabitsHomeView {
    func ensureScheduleForVisibleRange(centeredOn date: Date? = nil) async {
        let center = date?.startOfDay ?? selectedDate
        let start = center.adding(days: -calendarSpan)
        let end = center.adding(days: calendarSpan)
        do {
            try ScheduleService(context: modelContext).ensureSchedule(from: start, to: end)
        } catch {
            print("Failed to ensure schedule: \(error)")
        }
    }

    func update(instance: HabitInstance, status: CompletionState, note: String?) {
        instance.status = status
        instance.note = note
        instance.completedAt = status == .completed ? Date() : nil
        do {
            try modelContext.save()
        } catch {
            print("Failed to update instance: \(error)")
        }
    }

    func handleAddItem() {
        _Concurrency.Task {
            await ensureScheduleForVisibleRange()
        }
    }

}

// MARK: - Header

private struct HabitsHeroCard: View {
    let date: Date
    let leagueName: String
    let xpValue: Int
    let message: String

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MountainIllustration()
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 16, y: 10)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text(leagueName)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.sherpaTextPrimary)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(DesignTokens.Colors.accentGold)
                    Text("\(xpValue) XP")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.sherpaTextPrimary)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(date.formatted(.dateTime.weekday(.wide)))
                        .font(.system(.callout, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.sherpaTextPrimary)
                    Text(message)
                        .font(DesignTokens.Fonts.body())
                        .foregroundStyle(Color.sherpaTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(DesignTokens.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)

            SherpaMascotPlaceholder()
                .frame(width: 120, height: 140)
                .offset(x: -DesignTokens.Spacing.lg, y: DesignTokens.Spacing.md)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(leagueName) with \(xpValue) XP on \(date.formatted(date: .complete, time: .omitted))")
    }
}

private struct MountainIllustration: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                LinearGradient(
                    colors: [DesignTokens.Colors.primary.opacity(0.25), DesignTokens.Colors.accentMint.opacity(0.4), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 0) {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: height * 0.25, style: .continuous)
                            .fill(DesignTokens.Colors.accentMint.opacity(0.9))
                            .frame(width: width * 1.1, height: height * 0.75)
                            .offset(y: height * 0.2)

                        RoundedRectangle(cornerRadius: height * 0.22, style: .continuous)
                            .fill(DesignTokens.Colors.primary)
                            .frame(width: width * 1.05, height: height * 0.7)
                            .overlay(
                                Path { path in
                                    let baseY = height * 0.55
                                    path.move(to: CGPoint(x: width * 0.05, y: baseY))
                                    path.addQuadCurve(
                                        to: CGPoint(x: width * 0.45, y: height * 0.2),
                                        control: CGPoint(x: width * 0.2, y: height * 0.3)
                                    )
                                    path.addQuadCurve(
                                        to: CGPoint(x: width * 0.95, y: baseY + height * 0.05),
                                        control: CGPoint(x: width * 0.75, y: height * 0.25)
                                    )
                                }
                                .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: max(4, height * 0.03), lineCap: .round))
                            )
                    }
                    .padding(.bottom, -height * 0.1)
                }
            }
        }
    }
}

private struct SherpaMascotPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.1), radius: 12, y: 8)

            VStack(spacing: DesignTokens.Spacing.sm) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Horn()
                    Horn(flip: true)
                }
                .frame(width: 80)

                Circle()
                    .fill(DesignTokens.Colors.accentMint)
                    .frame(width: 80, height: 80)
                    .overlay(
                        VStack(spacing: DesignTokens.Spacing.xs) {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                Eye()
                                Eye()
                            }
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.sherpaTextPrimary)
                                .frame(width: 22, height: 6)
                        }
                    )

                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignTokens.Colors.primary)
                    .frame(width: 70, height: 26)
            }
            .padding(DesignTokens.Spacing.md)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private struct Horn: View {
        var flip: Bool = false

        var body: some View {
            Capsule(style: .continuous)
                .fill(DesignTokens.Colors.accentOrange.opacity(0.8))
                .frame(width: 22, height: 48)
                .rotationEffect(.degrees(flip ? 25 : -25))
        }
    }

    private struct Eye: View {
        var body: some View {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                Circle()
                    .fill(Color.sherpaTextPrimary)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Calendar Strip

private struct CalendarStripView: View {
    let dates: [Date]
    @Binding var selectedDate: Date
    let daySummaries: [Date: Bool]

    private let calendar = Calendar.current
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        SherpaCard(
            backgroundStyle: .solid(Color.white),
            strokeColor: Color.white,
            strokeOpacity: 0.7,
            padding: DesignTokens.Spacing.lg,
            shadowColor: Color.black.opacity(0.05)
        ) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(dates, id: \.self) { date in
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let qualifies = daySummaries[date.startOfDay] ?? false
                        CalendarStripCell(
                            date: date,
                            isSelected: isSelected,
                            qualifies: qualifies
                        )
                        .onTapGesture {
                            if reduceMotion {
                                selectedDate = date.startOfDay
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    selectedDate = date.startOfDay
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sm)
            }
        }
    }
}

private struct CalendarStripCell: View {
    let date: Date
    let isSelected: Bool
    let qualifies: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Text(weekday)
                .font(.system(.caption, design: .rounded).weight(isSelected ? .heavy : .medium))
                .foregroundStyle(isSelected ? Color.white : Color.sherpaTextSecondary)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? DesignTokens.Colors.primary : Color.clear)
                )

            Text(dayString)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.sherpaTextPrimary)

            Circle()
                .fill(qualifies ? DesignTokens.Colors.accentGold : Color.sherpaTextSecondary.opacity(0.2))
                .frame(width: qualifies ? 10 : 6, height: qualifies ? 10 : 6)
                .opacity(qualifies ? 1 : 0.6)
        }
        .frame(width: 58)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous)
                .fill(isSelected ? Color.white.opacity(0.65) : Color.clear)
        )
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }

    private var weekday: String {
        date.formatted(.dateTime.weekday(.short)).uppercased()
    }

    private var dayString: String {
        date.formatted(.dateTime.day())
    }
}

// MARK: - Routine Cards

private struct RoutineCard: View {
    let instance: HabitInstance
    let colorIndex: Int
    let qualifiesForStreak: Bool
    let onToggleComplete: () -> Void
    let onSkip: () -> Void
    let onSkipWithNote: () -> Void

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    private var subtitle: String? {
        if let note = instance.note, instance.status == .skippedWithNote {
            return "Skipped · \(note)"
        }
        return nil
    }

    private var paletteColors: [Color] {
        DesignTokens.cardPalettes[colorIndex % DesignTokens.cardPalettes.count]
    }

    private var icon: String {
        instance.isHabit ? "🧗" : "📝"
    }

    var body: some View {
        let palette = paletteColors

        SherpaCard(
            backgroundStyle: .solid(Color.white),
            strokeColor: Color.white,
            strokeOpacity: 0.7,
            padding: DesignTokens.Spacing.lg,
            shadowColor: Color.black.opacity(0.05)
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                PaletteAccent(colors: palette)
                    .padding(.bottom, DesignTokens.Spacing.sm)

                HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                    Text(icon)
                        .font(.system(size: 36))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(instance.displayName)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.sherpaTextPrimary)

                        Text(instance.isHabit ? "Habit" : "Task")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.sherpaTextSecondary)
                    }

                    Spacer()

                    Text(statusLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(statusColors.foreground)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(statusColors.background)
                        )
                        .accessibilityLabel(statusAccessibilityLabel)
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.sherpaTextSecondary)
                        .accessibilityLabel("Skip note: \(subtitle)")
                } else if let completionDescription {
                    Text(completionDescription)
                        .font(.footnote)
                        .foregroundStyle(Color.sherpaTextSecondary)
                } else {
                    Text(encouragementText)
                        .font(.footnote)
                        .foregroundStyle(Color.sherpaTextSecondary)
                }

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Button {
                        onToggleComplete()
                    } label: {
                        SherpaChip(
                            style: toggleChipStyle,
                            isSelected: true,
                            horizontalPadding: DesignTokens.Spacing.lg,
                            verticalPadding: DesignTokens.Spacing.sm,
                            font: DesignTokens.Fonts.button()
                        ) {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: instance.status == .completed ? "arrow.uturn.left" : "checkmark.circle")
                                    .font(.headline.weight(.bold))
                                Text(instance.status == .completed ? "Reset" : "Mark done")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(instance.status == .completed ? "Mark this routine as pending again." : "Mark this routine as completed.")

                    Menu {
                        Button("Skip today", role: .destructive) {
                            onSkip()
                        }
                        Button("Skip with note") {
                            onSkipWithNote()
                        }
                    } label: {
                        SherpaChip(
                            style: .accent(DesignTokens.Colors.accentBlue),
                            isSelected: false,
                            horizontalPadding: DesignTokens.Spacing.md,
                            verticalPadding: DesignTokens.Spacing.sm,
                            font: DesignTokens.Fonts.button()
                        ) {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: "ellipsis")
                                Text("Skip")
                            }
                        }
                    }
                    .menuOrder(.fixed)
                    .accessibilityHint("Skip options for this routine.")
                }
            }
        }
    }

    private var statusLabel: String {
        switch instance.status {
        case .completed:
            return "Completed"
        case .pending:
            return "In Progress"
        case .skipped:
            return "Skipped"
        case .skippedWithNote:
            return "Skipped · Note"
        }
    }

    private var statusAccessibilityLabel: String {
        switch instance.status {
        case .completed:
            return "Completed"
        case .pending:
            return "Pending"
        case .skipped:
            return "Skipped"
        case .skippedWithNote:
            return "Skipped with note"
        }
    }

    private var statusColors: (background: Color, foreground: Color) {
        switch instance.status {
        case .completed:
            return (DesignTokens.Colors.accentMint.opacity(0.3), DesignTokens.Colors.accentMint)
        case .pending:
            return (DesignTokens.Colors.accentBlue.opacity(0.2), DesignTokens.Colors.accentBlue)
        case .skipped:
            return (DesignTokens.Colors.accentPink.opacity(0.25), DesignTokens.Colors.accentPink)
        case .skippedWithNote:
            return (DesignTokens.Colors.accentPurple.opacity(0.25), DesignTokens.Colors.accentPurple)
        }
    }

    private var encouragementText: String {
        if qualifiesForStreak && instance.isHabit {
            return "Complete to protect today's streak."
        }
        if instance.isHabit {
            return "Tiny steps build strong habits."
        }
        return "Wrap this task to stay on track."
    }

    private var completionDescription: String? {
        guard instance.status == .completed, let completedAt = instance.completedAt else { return nil }
        let relative = RoutineCard.relativeFormatter.localizedString(for: completedAt, relativeTo: Date())
        return "Completed \(relative)"
    }

    private var toggleChipStyle: SherpaChipStyle {
        instance.status == .completed
            ? .gradient([DesignTokens.Colors.accentPink, DesignTokens.Colors.accentLavender])
            : .gradient([DesignTokens.Colors.primary, DesignTokens.Colors.accentMint])
    }
}

private struct PaletteAccent: View {
    let colors: [Color]

    var body: some View {
        HStack(spacing: -18) {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(color.opacity(0.8))
                    .frame(width: 60, height: 22)
                    .shadow(color: color.opacity(0.25), radius: 6, y: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.45), lineWidth: 1)
                    )
                    .zIndex(Double(colors.count - index))
            }
        }
        .padding(.leading, 4)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        SherpaCard(
            backgroundStyle: .solid(Color.white),
            strokeColor: Color.white,
            strokeOpacity: 0.7,
            padding: DesignTokens.Spacing.xl,
            shadowColor: Color.black.opacity(0.05)
        ) {
            VStack(spacing: DesignTokens.Spacing.lg) {
                PaletteAccent(colors: [
                    DesignTokens.Colors.primary,
                    DesignTokens.Colors.accentMint,
                    DesignTokens.Colors.accentBlue
                ])
                .padding(.bottom, DesignTokens.Spacing.sm)

                Text("No habits scheduled today")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.sherpaTextPrimary)

                Text("Use the calendar above to jump to another day or plan ahead with your coach later.")
                    .font(DesignTokens.Fonts.body())
                    .foregroundStyle(Color.sherpaTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct AddHabitsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.white)
                Text("Add Habits")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(
                Capsule(style: .continuous)
                    .fill(DesignTokens.Colors.primary)
            )
            .shadow(color: DesignTokens.Colors.primary.opacity(0.35), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add a new habit")
    }
}

// AddRoutineSheet, WeekdaySelectionView, SkipNoteSheet remain from previous implementation

private struct AddRoutineSheet: View {
    enum ItemKind: String, CaseIterable, Identifiable {
        case habit
        case task

        var id: String { rawValue }

        var label: String {
            switch self {
            case .habit: return "Habit"
            case .task: return "Task"
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
                        Text("Suggestions")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.sherpaTextSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignTokens.Spacing.sm) {
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
                        TextField("Title", text: $title)
                            .textInputAutocapitalization(.words)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )

                        TextField("Notes (optional)", text: $detail, axis: .vertical)
                            .lineLimit(2...4)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("Schedule")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Color.sherpaTextPrimary)

                            Picker("Frequency", selection: $frequency) {
                                ForEach(RecurrenceFrequency.allCases) { freq in
                                    Text(freq.displayName).tag(freq)
                                }
                            }
                            .pickerStyle(.segmented)

                            Stepper(value: $interval, in: 1...30) {
                                Text("Every \(interval) \(frequency == .weekly ? "week(s)" : frequency == .monthly ? "month(s)" : "day(s)")")
                            }

                            if frequency == .weekly {
                                WeekdaySelectionView(selected: $selectedWeekdays)
                            }

                            if itemKind == .task && frequency == .daily {
                                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
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
            .navigationTitle(itemKind == .habit ? "New Habit" : "New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
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
            let habit = Habit(
                title: trimmedTitle,
                detail: detail.isEmpty ? nil : detail,
                recurrenceRule: recurrence
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
            print("Failed to save: \(error)")
        }
    }
}

private struct WeekdaySelectionView: View {
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

private struct SkipNoteSheet: View {
    let instance: HabitInstance
    var onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Reason for skipping") {
                    TextField("Type your note…", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Skip with note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(note.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
