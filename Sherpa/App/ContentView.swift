//
//  ContentView.swift
//  Sherpa
//
//  Created by Ali Cicek on 15/10/2025.
//

import SwiftData
import SwiftUI

enum AppTab: Hashable {
    case habits
    case focus
    case coach
    case insights
    case leaderboard
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .habits

    var body: some View {
        TabView(selection: $selectedTab) {
            HabitsHomeView()
                .tabItem {
                    Label(L10n.string("tab.habits.title"), systemImage: "house.lodge")
                }
                .tag(AppTab.habits)

            FocusHomeView()
            .tabItem {
                Label(L10n.string("tab.focus.title"), systemImage: "binoculars")
            }
            .tag(AppTab.focus)

            CoachHomeView()
                .tabItem {
                    Label(L10n.string("tab.coach.title"), systemImage: "bubble.left.and.bubble.right")
                }
                .tag(AppTab.coach)

            TabPlaceholderView(
                title: L10n.string("tab.insights.title"),
                message: L10n.string("placeholder.insights.message"),
                illustrationSymbol: "chart.bar.doc.horizontal"
            )
            .tabItem {
                Label(L10n.string("tab.insights.title"), systemImage: "chart.bar.doc.horizontal")
            }
            .tag(AppTab.insights)

            TabPlaceholderView(
                title: L10n.string("tab.leaderboard.title"),
                message: L10n.string("placeholder.leaderboard.message"),
                illustrationSymbol: "mountain.2"
            )
            .tabItem {
                Label(L10n.string("tab.leaderboard.title"), systemImage: "mountain.2")
            }
            .tag(AppTab.leaderboard)
        }
        .tint(.sherpaPrimary)
    }
}

private struct TabPlaceholderView: View {
    let title: String
    let message: String
    let illustrationSymbol: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    Image(systemName: illustrationSymbol)
                        .font(.system(size: 60, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.sherpaPrimary)
                        .padding(DesignTokens.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 12, y: 8)
                        )
                        .accessibilityHidden(true)

                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Text(title)
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.sherpaTextPrimary)

                        Text(message)
                            .font(.body)
                            .foregroundStyle(Color.sherpaTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                    }

                    Button(action: {}) {
                        Label(L10n.string("placeholder.comingSoon.label"), systemImage: "sparkles")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44) // Apple HIG minimum touch target.
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.sherpaPrimary)
                    .disabled(true)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.xl)
            }
            .background(Color.sherpaBackground.ignoresSafeArea())
            .navigationTitle(title)
        }
    }
}

#Preview {
    let container = AppContainer()
    return ContentView()
        .modelContainer(for: [Habit.self, Task.self, HabitInstance.self, RecurrenceRule.self], inMemory: true)
        .environmentObject(container.xpStore)
        .environmentObject(container)
}
