//
//  HabitsCalendarStrip.swift
//  Sherpa
//
//  Extracted from HabitsHomeView to keep the home layout focused on composition.
//

import SwiftUI

struct DayCompletionSnapshot {
    let progress: Double
    let isComplete: Bool
    let hasEligibleItems: Bool

    static let empty = DayCompletionSnapshot(progress: 0, isComplete: false, hasEligibleItems: false)
}

struct CalendarStripView: View {
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
            .onChange(of: selectedDate) { _, newDate in
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
        let targetDate = selectedDate.startOfDay

        let performScroll = {
            proxy.scrollTo(targetDate, anchor: anchor)
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

        _Concurrency.Task { @MainActor in
            scrollAction()
        }
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

struct CalendarStripCell: View {
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
