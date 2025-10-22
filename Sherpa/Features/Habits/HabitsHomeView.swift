//
//  HabitsHomeView.swift
//  Sherpa
//
//  Created by Codex on 15/10/2025.
//

import SwiftData
import SwiftUI

struct HabitsHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HabitsHomeViewModel()
    @State private var showingAddSheet = false
    @State private var skipNoteTarget: HabitInstance?
    @State private var isAnyTileDragging = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.99, green: 0.96, blue: 0.91)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        CalendarStripView(
                            dates: viewModel.calendarDates,
                            dayProgress: viewModel.dayCompletionSnapshots,
                            selectedDate: $viewModel.selectedDate
                        )
                        .padding(.horizontal, -DesignTokens.Spacing.lg)

                        HabitsHeroCard(
                            date: viewModel.selectedDate,
                            leagueName: viewModel.leagueTitle,
                            xpValue: viewModel.totalXP
                        )

                        if viewModel.todaysItems.isEmpty {
                            EmptyStateView()
                        } else {
                            VStack(spacing: DesignTokens.Spacing.md) {
                                ForEach(viewModel.todaysItems, id: \.id) { instance in
                                    let profile = viewModel.habitProfile(for: instance)
                                    let model = viewModel.tileModel(for: instance, profile: profile)
                                    HabitTile(
                                        model: model,
                                        progress: viewModel.progressBinding(for: instance, profile: profile),
                                        onDragStateChange: { dragging in
                                            isAnyTileDragging = dragging
                                        }
                                    ) { newValue in
                                        viewModel.handleProgressChange(for: instance, profile: profile, newValue: newValue)
                                    }
                                    .contextMenu {
                                        Button(L10n.string("habits.context.reset"), role: .destructive) {
                                            viewModel.resetProgress(for: instance, profile: profile)
                                        }

                                        Divider()

                                        Button(L10n.string("habits.context.skip"), role: .destructive) {
                                            viewModel.skip(instance: instance, profile: profile)
                                        }

                                        Button(L10n.string("habits.context.skipWithNote")) {
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
                .scrollDisabled(isAnyTileDragging)
            }
            .task(id: viewModel.selectedDate) {
                let selected = viewModel.selectedDate
                viewModel.configureIfNeeded(modelContext: modelContext)
                await viewModel.refreshSelection(to: selected)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddRoutineSheet(isPresented: $showingAddSheet, onComplete: viewModel.handleAddItem)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $skipNoteTarget) { target in
                SkipNoteSheet(instance: target) { note in
                    viewModel.update(instance: target, status: .skippedWithNote, note: note)
                }
                .presentationDetents([.fraction(0.35)])
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Header

private struct HabitsHeroCard: View {
    let date: Date
    let leagueName: String
    let xpValue: Int

    var body: some View {
        SherpaCard(
            backgroundStyle: .solid(Color.white.opacity(0.95)),
            strokeColor: Color.white,
            strokeOpacity: 0.3,
            padding: 0,
            shadowColor: Color.black.opacity(0.06)
        ) {
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
                        Color.white.opacity(0.0)
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
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large, style: .continuous))
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(leagueName) with \(xpValue) XP on \(date.formatted(date: .complete, time: .omitted))")
    }
}

// MARK: - Empty State

private struct EmptyStateView: View {
    var body: some View {
        Text(L10n.string("habits.emptyState.message"))
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
