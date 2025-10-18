//
//  HabitsHomeView.swift
//  Sherpa
//
//  Created by Codex on 15/10/2025.
//

import OSLog
import SwiftData
import SwiftUI
import UIKit

private struct DayCompletionSnapshot {
    let progress: Double
    let isComplete: Bool
    let hasEligibleItems: Bool

    static let empty = DayCompletionSnapshot(progress: 0, isComplete: false, hasEligibleItems: false)
}

private struct HabitTileProfile {
    let goal: Double
    let step: Double
    let unit: String
    let subtitle: String
    let icon: String
    let accent: Color
    let background: Color
}

struct HabitsHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate: Date = Date().startOfDay
    @State private var showingAddSheet = false
    @State private var skipNoteTarget: HabitInstance?
    @State private var calendarWindowStart: Date
    @State private var habitProgressValues: [PersistentIdentifier: Double] = [:]
    @State private var habitTileProfiles: [PersistentIdentifier: HabitTileProfile] = [:]

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
        _calendarWindowStart = State(initialValue: now.adding(days: -calendarSpan))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.99, green: 0.96, blue: 0.91)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        CalendarStripView(
                            dates: calendarDates,
                            dayProgress: dayCompletionSnapshots,
                            selectedDate: $selectedDate
                        )
                        .padding(.horizontal, -DesignTokens.Spacing.lg)

                        HabitsHeroCard(
                            date: selectedDate,
                            leagueName: leagueTitle,
                            xpValue: totalXP
                        )

                        if todaysItems.isEmpty {
                            EmptyStateView()
                        } else {
                            VStack(spacing: DesignTokens.Spacing.md) {
                                ForEach(todaysItems.indices, id: \.self) { index in
                                    let instance = todaysItems[index]
                                    let profile = habitProfile(for: instance, colorIndex: index)
                                    let model = tileModel(for: instance, profile: profile)
                                    HabitTile(
                                        model: model,
                                        progress: progressBinding(for: instance, profile: profile)
                                    ) { newValue in
                                        handleProgressChange(for: instance, profile: profile, newValue: newValue)
                                    }
                                    .contextMenu {
                                        Button("Reset progress", role: .destructive) {
                                            resetProgress(for: instance, profile: profile)
                                        }

                                        Divider()

                                        Button("Skip today", role: .destructive) {
                                            skip(instance: instance, profile: profile)
                                        }

                                        Button("Skip with note") {
                                            skipNoteTarget = instance
                                        }
                                    }
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
            .task(id: selectedDate) {
                adjustCalendarWindowIfNeeded(for: selectedDate)
                await ensureScheduleForVisibleRange(centeredOn: selectedDate)
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

@MainActor
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

    var leagueTitle: String {
        switch completionProgress {
        case 0.75...:
            return "Summit League"
        case 0.4...:
            return "Hilltop League"
        default:
            return "Hilltop League"
        }
    }

    var totalXP: Int {
        todaysItems.reduce(0) { total, instance in
            let baseXP = instance.isHabit ? 25 : 15
            return total + (instance.status == .completed ? baseXP : baseXP / 2)
        }
    }

    var calendarDates: [Date] {
        let start = calendarWindowStart
        return (0 ... (calendarSpan * 2)).map { offset in
            start.adding(days: offset)
        }
    }

    var daySummaries: [Date: Bool] {
        Dictionary(grouping: instances) { $0.date.startOfDay }
            .mapValues { StreakCalculator.qualifiesForStreak(instances: $0) }
    }

    var dayCompletionSnapshots: [Date: DayCompletionSnapshot] {
        let grouped = Dictionary(grouping: instances) { $0.date.startOfDay }
        var snapshots: [Date: DayCompletionSnapshot] = [:]

        for (date, items) in grouped {
            let eligibleItems = items.filter { $0.status != .skippedWithNote }
            let completedCount = eligibleItems.filter { $0.status == .completed }.count
            let eligibleCount = eligibleItems.count

            guard eligibleCount > 0 else {
                snapshots[date] = DayCompletionSnapshot(progress: 0, isComplete: false, hasEligibleItems: false)
                continue
            }

            let threshold = max(1, Int(ceil(Double(eligibleCount) * 0.4)))
            let progress = min(Double(completedCount) / Double(threshold), 1)
            let snapshot = DayCompletionSnapshot(
                progress: progress,
                isComplete: completedCount >= threshold,
                hasEligibleItems: true
            )
            snapshots[date] = snapshot
        }

        return snapshots
    }
}

// MARK: - Behaviours

@MainActor
private extension HabitsHomeView {
    func ensureScheduleForVisibleRange(centeredOn date: Date? = nil) async {
        let center = date?.startOfDay ?? selectedDate
        let start = center.adding(days: -calendarSpan)
        let end = center.adding(days: calendarSpan)
        do {
            try ScheduleService(context: modelContext).ensureSchedule(from: start, to: end)
        } catch {
            Logger.habits.error("Failed to ensure schedule: \(error.localizedDescription, privacy: .public)")
        }
    }

    func update(instance: HabitInstance, status: CompletionState, note: String?) {
        instance.status = status
        instance.note = note
        instance.completedAt = status == .completed ? Date() : nil
        do {
            try modelContext.save()
        } catch {
            Logger.habits.error("Failed to update instance: \(error.localizedDescription, privacy: .public)")
        }
    }

    func handleAddItem() {
        _Concurrency.Task { @MainActor in
            await ensureScheduleForVisibleRange()
        }
    }

    func adjustCalendarWindowIfNeeded(for date: Date) {
        let normalizedDate = date.startOfDay
        let currentStart = calendarWindowStart
        let currentEnd = currentStart.adding(days: calendarSpan * 2)

        let leadingThreshold = currentStart.adding(days: 3)
        let trailingThreshold = currentEnd.adding(days: -3)

        if normalizedDate <= leadingThreshold {
            calendarWindowStart = normalizedDate.adding(days: -calendarSpan)
        } else if normalizedDate >= trailingThreshold {
            calendarWindowStart = normalizedDate.adding(days: -calendarSpan)
        }
    }

    func habitProfile(for instance: HabitInstance, colorIndex: Int) -> HabitTileProfile {
        let identifier = instance.persistentModelID
        if let cached = habitTileProfiles[identifier] {
            return cached
        }

        let palette = DesignTokens.cardPalettes[colorIndex % DesignTokens.cardPalettes.count]
        let accent = palette.first ?? DesignTokens.Colors.primary
        let background = (palette.dropFirst().first ?? accent).opacity(0.18)

        var goal: Double = instance.isHabit ? 4 : 1
        var unit: String = instance.isHabit ? "reps" : "tasks"
        var subtitle: String = instance.isHabit ? "Every day" : "Task"
        var icon: String = instance.isHabit ? "🧗" : "📝"

        let lowercasedName = instance.displayName.lowercased()
        if lowercasedName.contains("water") {
            goal = 3000
            unit = "ml"
            icon = "💧"
            subtitle = "Hydration"
        } else if lowercasedName.contains("protein") {
            goal = 400
            unit = "g"
            icon = "🍗"
            subtitle = "Nutrition"
        } else if lowercasedName.contains("walk") || lowercasedName.contains("steps") {
            goal = 8000
            unit = "steps"
            icon = "🚶"
            subtitle = "Movement"
        } else if lowercasedName.contains("meditat") {
            goal = 20
            unit = "min"
            icon = "🧘"
            subtitle = "Mindfulness"
        }

        let step = AdaptiveStepCalculator.stepSize(for: goal)

        let profile = HabitTileProfile(
            goal: goal,
            step: step,
            unit: unit,
            subtitle: subtitle,
            icon: icon,
            accent: accent,
            background: background
        )

        habitTileProfiles[identifier] = profile
        return profile
    }

    func progressBinding(for instance: HabitInstance, profile: HabitTileProfile) -> Binding<Double> {
        let identifier = instance.persistentModelID
        if habitProgressValues[identifier] == nil {
            let initialValue = instance.status == .completed ? profile.goal : 0
            habitProgressValues[identifier] = initialValue
        }

        return Binding<Double>(
            get: {
                habitProgressValues[identifier] ?? 0
            },
            set: { newValue in
                habitProgressValues[identifier] = max(0, min(profile.goal, newValue))
            }
        )
    }

    func handleProgressChange(
        for instance: HabitInstance,
        profile: HabitTileProfile,
        newValue: Double
    ) {
        let identifier = instance.persistentModelID
        let clamped = max(0, min(profile.goal, newValue))
        habitProgressValues[identifier] = clamped

        let shouldBeCompleted = clamped >= profile.goal - 0.0001
        if shouldBeCompleted {
            if instance.status != .completed {
                update(instance: instance, status: .completed, note: instance.note)
            }
        } else if instance.status == .completed {
            update(instance: instance, status: .pending, note: instance.note)
        }

        saveProgress(for: instance, progress: clamped, profile: profile)
    }

    func saveProgress(for instance: HabitInstance, progress: Double, profile: HabitTileProfile) {
        // Placeholder persistence hook. Replace with Supabase integration.
        let percent = profile.goal > 0 ? Int((progress / profile.goal) * 100) : 0
        Logger.habits.debug(
            "Saved progress for \(instance.displayName, privacy: .private): "
                + "\(Int(progress), privacy: .public)/\(Int(profile.goal), privacy: .public) "
                + "\(profile.unit, privacy: .private) "
                + "(\(percent, privacy: .public)% done)"
        )
    }

    func resetProgress(for instance: HabitInstance, profile: HabitTileProfile) {
        let identifier = instance.persistentModelID
        habitProgressValues[identifier] = 0
        handleProgressChange(for: instance, profile: profile, newValue: 0)
    }

    func skip(instance: HabitInstance, profile: HabitTileProfile) {
        let identifier = instance.persistentModelID
        habitProgressValues[identifier] = 0
        update(instance: instance, status: .skipped, note: nil)
        saveProgress(for: instance, progress: 0, profile: profile)
    }

    func tileModel(for instance: HabitInstance, profile: HabitTileProfile) -> HabitTileModel {
        HabitTileModel(
            title: instance.displayName,
            subtitle: profile.subtitle,
            icon: profile.icon,
            goal: profile.goal,
            unit: profile.unit,
            step: profile.step,
            accentColor: profile.accent,
            backgroundColor: profile.background
        )
    }
}

private enum AdaptiveStepCalculator {
    static func stepSize(for goal: Double) -> Double {
        switch goal {
        case ..<20:
            return 1
        case ..<200:
            return 5
        case ..<1000:
            return 10
        case ..<5000:
            return 50
        case ..<10000:
            return 100
        default:
            return 250
        }
    }
}

// MARK: - Header

private struct HabitsHeroCard: View {
    let date: Date
    let leagueName: String
    let xpValue: Int

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large, style: .continuous)

        ZStack(alignment: .topLeading) {
            Image("HabitsHeroIllustration")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .accessibilityHidden(true)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.85),
                    Color.white.opacity(0.0),
                ],
                startPoint: .top,
                endPoint: .center
            )

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
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
            }
            .padding(DesignTokens.Spacing.xl)
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
        .clipShape(cardShape)
        .overlay(cardShape.stroke(Color.white.opacity(0.3), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.06), radius: 16, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(leagueName) with \(xpValue) XP on \(date.formatted(date: .complete, time: .omitted))")
    }
}

// MARK: - Calendar Strip

private struct CalendarStripView: View {
    let dates: [Date]
    let dayProgress: [Date: DayCompletionSnapshot]
    @Binding var selectedDate: Date

    private let calendar = Calendar.current
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasPerformedInitialScroll = false
    @State private var lastSelectedDate: Date = Date().startOfDay
    private let defaultAnchor = UnitPoint(x: 0.78, y: 0.5)
    private let pastAnchor = UnitPoint(x: 0.82, y: 0.5)
    private let futureAnchor = UnitPoint(x: 0.18, y: 0.5)

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(dates, id: \.self) { date in
                        let normalizedDate = date.startOfDay
                        let isSelected = calendar.isDate(normalizedDate, inSameDayAs: selectedDate)

                        CalendarStripCell(
                            date: normalizedDate,
                            isSelected: isSelected,
                            snapshot: dayProgress[normalizedDate] ?? .empty
                        )
                        .id(normalizedDate)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDate = normalizedDate
                        }
                    }
                }
                .padding(.horizontal, 0)
                .padding(.vertical, DesignTokens.Spacing.sm)
            }
            .onAppear {
                guard !hasPerformedInitialScroll else { return }
                hasPerformedInitialScroll = true
                lastSelectedDate = selectedDate
                scrollToSelected(proxy: proxy, anchor: defaultAnchor, animated: false)
            }
            .onChange(of: selectedDate) { newDate in
                let anchor = anchor(for: newDate, previous: lastSelectedDate)
                lastSelectedDate = newDate
                scrollToSelected(proxy: proxy, anchor: anchor)
            }
        }
    }

    private func scrollToSelected(
        proxy: ScrollViewProxy,
        anchor: UnitPoint,
        animated: Bool = true
    ) {
        let performScroll = {
            proxy.scrollTo(selectedDate.startOfDay, anchor: anchor)
        }

        let scrollAction = {
            if reduceMotion || !animated {
                performScroll()
            } else {
                let animation = Animation.spring(response: 0.45, dampingFraction: 0.85, blendDuration: 0.15)
                withAnimation(animation) {
                    performScroll()
                }
            }
        }

        DispatchQueue.main.async(execute: scrollAction)
    }

    private func anchor(for newDate: Date, previous oldDate: Date) -> UnitPoint {
        let normalizedDate = newDate.startOfDay

        guard let index = dates.firstIndex(of: normalizedDate) else {
            return defaultAnchor
        }

        let total = dates.count
        if total <= 1 {
            return defaultAnchor
        }

        if index <= 1 {
            return UnitPoint(x: 0.12, y: 0.5)
        }

        if index >= total - 2 {
            return UnitPoint(x: 0.88, y: 0.5)
        }

        let comparisonResult = calendar.compare(newDate, to: oldDate, toGranularity: .day)

        switch comparisonResult {
        case .orderedAscending:
            return pastAnchor
        case .orderedDescending:
            return futureAnchor
        default:
            return defaultAnchor
        }
    }
}

private struct CalendarStripCell: View {
    let date: Date
    let isSelected: Bool
    let snapshot: DayCompletionSnapshot

    private let calendar = Calendar.current

    var body: some View {
        let normalizedProgress = max(0, min(snapshot.progress, 1))
        let isCompleteDay = snapshot.isComplete
        let hasEligibleItems = snapshot.hasEligibleItems

        let futureOpacityScale: Double = isFutureDay ? 0.55 : 0.8
        let weekdayOpacity = isSelected || isCompleteDay ? 0.95 : (isFutureDay ? 0.5 : 0.65)

        let circleFill: Color = {
            if isCompleteDay { return DesignTokens.Colors.primary }
            if isSelected { return Color.sherpaTextPrimary.opacity(0.12) }
            return Color.clear
        }()

        let circleStroke = Color.sherpaTextPrimary.opacity(hasEligibleItems ? 0.18 : 0.08)
        let progressColor = isCompleteDay ? Color.white.opacity(0.9) : DesignTokens.Colors.primary

        let dayTextColor: Color = {
            if isCompleteDay { return .white }
            if isSelected { return Color.sherpaTextPrimary }
            return Color.sherpaTextPrimary.opacity(futureOpacityScale)
        }()

        VStack(spacing: 6) {
            Text(weekday)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.sherpaTextPrimary.opacity(weekdayOpacity))

            ZStack {
                Circle()
                    .fill(circleFill)

                Circle()
                    .stroke(circleStroke, lineWidth: 1.25)
                    .opacity(hasEligibleItems ? 1 : 0.4)

                Circle()
                    .trim(from: 0, to: CGFloat(normalizedProgress))
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .opacity(hasEligibleItems ? 1 : 0)

                Text(dayString)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(dayTextColor)
            }
            .frame(width: 44, height: 44)
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .frame(minWidth: 56)
        .opacity(isFutureDay && !isSelected && !isCompleteDay ? 0.9 : 1)
    }

    private var weekday: String {
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        let symbols = calendar.shortWeekdaySymbols
        guard symbols.indices.contains(weekdayIndex) else { return "" }
        let symbol = symbols[weekdayIndex]
        return symbol.count > 2 ? String(symbol.prefix(2)) : symbol
    }

    private var dayString: String {
        String(calendar.component(.day, from: date))
    }

    private var isFutureDay: Bool {
        date > Date().startOfDay
    }
}

// MARK: - Habit Tiles

struct HabitTileModel {
    let title: String
    let subtitle: String
    let icon: String
    let goal: Double
    let unit: String
    let step: Double
    let accentColor: Color
    let backgroundColor: Color
}

struct HabitTile: View {
    let model: HabitTileModel
    @Binding var progress: Double
    var onProgressChange: (Double) -> Void

    @State private var isDragging: Bool = false
    @State private var hasCelebratedCompletion = false
    @State private var dragStartProgress: Double = 0
    @State private var displayProgress: Double = 0

    private let lightFeedback = UIImpactFeedbackGenerator(style: .light)
    private let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let rigidFeedback = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private let tileHeight: CGFloat = 68

    private var progressRatio: Double {
        guard model.goal > 0 else { return 0 }
        return min(max(progress / model.goal, 0), 1)
    }

    private var displayRatio: Double {
        guard model.goal > 0 else { return 0 }
        return min(max(displayProgress / model.goal, 0), 1)
    }

    private var progressText: String {
        let current = HabitTile.numberFormatter.string(from: NSNumber(value: progress)) ?? "0"
        let goal = HabitTile.numberFormatter.string(from: NSNumber(value: model.goal)) ?? "0"
        let unit = model.unit.isEmpty ? "" : " \(model.unit)"
        return "\(current)/\(goal)\(unit)"
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let cornerRadius = DesignTokens.CornerRadius.small
            let fillWidth = max(width * displayRatio, 0)

            let isComplete = progressRatio >= 1 - 0.0001
            let fillOpacity = (isDragging || isComplete) ? 0.48 : 0.32
            let iconBackground = model.accentColor.opacity(0.2 + (displayRatio * 0.15))

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(model.backgroundColor)

                if fillWidth > 0 {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(model.accentColor.opacity(fillOpacity))
                        .frame(width: fillWidth)
                        .animation(.easeOut(duration: 0.18), value: displayRatio)
                }

                HStack(spacing: DesignTokens.Spacing.md) {
                    Text(model.icon)
                        .font(.system(size: 26))
                        .frame(width: 44, height: 44)
                        .background(iconBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.sherpaTextPrimary)
                            .lineLimit(1)

                        Text(model.subtitle)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.sherpaTextSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: DesignTokens.Spacing.md)

                    Text(progressText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.sherpaTextPrimary.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
            .frame(height: tileHeight)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(model.accentColor.opacity(isDragging ? 0.22 : 0.14), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isDragging ? 0.08 : 0.05), radius: isDragging ? 10 : 8, y: isDragging ? 6 : 4)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .gesture(dragGesture(totalWidth: width))
        }
        .frame(height: tileHeight)
        .onAppear {
            displayProgress = progress
            handleCompletionState(for: progress)
        }
        .onChange(of: progress) { newValue in
            if isDragging == false {
                withAnimation(.easeOut(duration: 0.18)) {
                    displayProgress = newValue
                }
            }
            handleCompletionState(for: newValue)
        }
    }

    private func dragGesture(totalWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .onChanged { value in
                if !isDragging {
                    let horizontalMagnitude = abs(value.translation.width)
                    let verticalMagnitude = abs(value.translation.height)
                    guard horizontalMagnitude > verticalMagnitude, horizontalMagnitude > 6 else {
                        return
                    }
                    isDragging = true
                    dragStartProgress = progress
                    hasCelebratedCompletion = progress >= model.goal - 0.0001
                }

                guard isDragging else { return }

                let deltaRatio = Double(value.translation.width / max(totalWidth, 1))
                let target = dragStartProgress + (deltaRatio * model.goal)
                displayProgress = max(0, min(model.goal, target))
                updateProgress(to: target)
            }
            .onEnded { value in
                guard isDragging else { return }

                let deltaRatio = Double(value.translation.width / max(totalWidth, 1))
                let predictedRatio = Double(value.predictedEndTranslation.width / max(totalWidth, 1))
                let predictedTarget = dragStartProgress + (predictedRatio * model.goal)
                let target = dragStartProgress + (deltaRatio * model.goal)

                let shouldSnapToGoal = predictedTarget >= model.goal * 0.95 || value.translation.width >= totalWidth * 0.6
                let shouldSnapToZero = predictedTarget <= model.goal * -0.05 || value.translation.width <= -totalWidth * 0.6

                if shouldSnapToGoal {
                    displayProgress = model.goal
                    updateProgress(to: model.goal)
                    rigidFeedback.impactOccurred()
                } else if shouldSnapToZero {
                    displayProgress = 0
                    updateProgress(to: 0)
                    rigidFeedback.impactOccurred()
                } else if model.goal <= model.step {
                    if target >= model.goal * 0.5 {
                        displayProgress = model.goal
                        updateProgress(to: model.goal)
                        rigidFeedback.impactOccurred()
                    } else {
                        displayProgress = 0
                        updateProgress(to: 0)
                        if dragStartProgress > 0 {
                            rigidFeedback.impactOccurred()
                        }
                    }
                } else {
                    displayProgress = max(0, min(model.goal, target))
                    updateProgress(to: target)
                    if abs(target - dragStartProgress) > 0.0001 {
                        rigidFeedback.impactOccurred()
                    }
                }

                isDragging = false

                withAnimation(.easeOut(duration: 0.2)) {
                    displayProgress = progress
                }
            }
    }

    private func updateProgress(to target: Double) {
        let clampedRaw = max(0, min(model.goal, target))
        displayProgress = clampedRaw

        let quantized = quantize(clampedRaw)
        let previous = progress

        guard abs(quantized - previous) > 0.0001 else { return }

        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.85)) {
            progress = quantized
        }
        onProgressChange(quantized)
        handleStepHaptics(previous: previous, newValue: quantized)
        handleCompletionState(for: quantized)

        if !isDragging {
            withAnimation(.easeOut(duration: 0.2)) {
                displayProgress = quantized
            }
        }
    }

    private func handleStepHaptics(previous: Double, newValue: Double) {
        guard model.step > 0 else { return }

        let previousIndex = Int((previous / model.step).rounded(.down))
        let newIndex = Int((newValue / model.step).rounded(.down))

        guard newIndex != previousIndex else { return }

        if newValue >= model.goal - 0.0001 {
            if hasCelebratedCompletion == false {
                notificationFeedback.notificationOccurred(.success)
                hasCelebratedCompletion = true
            }
        } else {
            hasCelebratedCompletion = false
            let delta = newIndex - previousIndex
            let iterations = min(abs(delta), 6)

            if delta > 0 {
                for _ in 0 ..< iterations {
                    mediumFeedback.impactOccurred()
                }
            } else {
                for _ in 0 ..< iterations {
                    lightFeedback.impactOccurred()
                }
            }
        }
    }

    private func handleCompletionState(for value: Double) {
        let isComplete = value >= model.goal - 0.0001
        if !isComplete {
            hasCelebratedCompletion = false
        }
    }

    private func quantize(_ value: Double) -> Double {
        guard model.step > 0 else { return value }
        let stepCount = (value / model.step).rounded()
        return stepCount * model.step
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        formatter.roundingMode = .down
        return formatter
    }()
}

struct HabitProgressItem: Identifiable {
    let id = UUID()
    var title: String
    var subtitle: String
    var icon: String
    var unit: String
    var goal: Double
    var step: Double
    var accentColor: Color
    var backgroundColor: Color
    var current: Double
}

struct HabitTileDemoView: View {
    @State private var items: [HabitProgressItem] = [
        HabitProgressItem(title: "Drink Water", subtitle: "Hydration", icon: "💧", unit: "ml", goal: 3000, step: 250, accentColor: Color(hex: "#28A6FF"), backgroundColor: Color(hex: "#DFF1FF"), current: 1350),
        HabitProgressItem(title: "Eat 100g Protein", subtitle: "Nutrition", icon: "🍗", unit: "g", goal: 400, step: 25, accentColor: Color(hex: "#68E08C"), backgroundColor: Color(hex: "#E5FBEA"), current: 370),
        HabitProgressItem(title: "Morning Walk", subtitle: "Movement", icon: "🚶", unit: "steps", goal: 8000, step: 500, accentColor: Color(hex: "#FF914D"), backgroundColor: Color(hex: "#FFE9D8"), current: 4500),
        HabitProgressItem(title: "Meditate", subtitle: "Mindfulness", icon: "🧘", unit: "min", goal: 20, step: 5, accentColor: Color(hex: "#BA8CFF"), backgroundColor: Color(hex: "#F2E7FF"), current: 10),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.md) {
                ForEach($items) { $item in
                    let model = HabitTileModel(
                        title: item.title,
                        subtitle: item.subtitle,
                        icon: item.icon,
                        goal: item.goal,
                        unit: item.unit,
                        step: item.step,
                        accentColor: item.accentColor,
                        backgroundColor: item.backgroundColor
                    )

                    HabitTile(model: model, progress: $item.current) { newValue in
                        saveProgress(for: item, updatedValue: newValue)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .background(Color.sherpaBackground.ignoresSafeArea())
    }

    private func saveProgress(for item: HabitProgressItem, updatedValue: Double) {
        let percent = item.goal > 0 ? Int((updatedValue / item.goal) * 100) : 0
        Logger.habits.debug(
            "Demo progress for \(item.title, privacy: .private): \(Int(updatedValue), privacy: .public)/\(Int(item.goal), privacy: .public) \(item.unit, privacy: .private) (\(percent, privacy: .public)% done)"
        )
    }
}

private struct EmptyStateView: View {
    var body: some View {
        Text("All goals completed today, tap below to create new goal")
            .font(DesignTokens.Fonts.body().weight(.semibold))
            .foregroundStyle(Color.sherpaTextSecondary)
            .multilineTextAlignment(.center)
            .padding(DesignTokens.Spacing.xl)
            .frame(maxWidth: .infinity)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                    .stroke(
                        DesignTokens.Colors.neutral.g3,
                        style: StrokeStyle(lineWidth: 4, dash: [10, 6])
                    )
            )
    }
}

private struct AddHabitsButton: View {
    let action: () -> Void

    var body: some View {
        Button(
            action: action,
            label: {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                        .fill(Color(hex: "#2F7C1B"))
                        .offset(y: 4)
                        .opacity(0.9)

                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                        .fill(Color(hex: "#58B62F"))

                    Text("ADD HABITS")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.white)
                        .kerning(1.1)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
            }
        )
        .buttonStyle(PressedScaleButtonStyle())
        .accessibilityLabel("Add a new habit")
    }
}

private struct PressedScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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
    @State private var dueDate = Date()

    private var suggestions: [Suggestion] {
        switch itemKind {
        case .habit:
            return [
                Suggestion(title: "Morning stretch", detail: "5 minute warm-up", frequency: .daily, weekdays: nil),
                Suggestion(title: "Deep tidy", detail: "30m reset", frequency: .weekly, weekdays: [.saturday]),
                Suggestion(title: "Drink water", detail: "Hydrate before coffee", frequency: .daily, weekdays: nil),
            ]
        case .task:
            return [
                Suggestion(title: "Submit assignment", detail: "Wrap before midnight", frequency: .daily, weekdays: nil),
                Suggestion(title: "Meal prep", detail: "Sunday planning", frequency: .weekly, weekdays: [.sunday]),
                Suggestion(title: "Budget review", detail: "Payday check-in", frequency: .monthly, weekdays: nil),
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
                            .lineLimit(2 ... 4)
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

                            Stepper(value: $interval, in: 1 ... 30) {
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
            Logger.habits.error("Failed to save new item: \(error.localizedDescription, privacy: .public)")
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
                        .lineLimit(3 ... 5)
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
