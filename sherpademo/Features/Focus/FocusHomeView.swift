//
//  FocusHomeView.swift
//  sherpademo
//
//  Created by Codex on 20/10/2025.
//

import Combine
import SwiftUI

struct FocusHomeView: View {
    @StateObject private var viewModel = FocusTimerViewModel()
    @EnvironmentObject private var xpStore: XPStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var confettiTrigger: Int = 0
    @State private var celebrateBadgeVisible = false
    @State private var rewardedSessionCount = 0

    private let focusXPReward = 25

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Gradients.sky
                    .ignoresSafeArea()

                VStack(spacing: DesignTokens.Spacing.xl) {
                    headerSection
                    timerCard
                    sessionProgressCard
                    controlsSection
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.xl)

                FocusConfettiView(trigger: confettiTrigger)

                if celebrateBadgeVisible {
                    celebrationBadge
                        .transition(.opacity)
                }
            }
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(.hidden, for: .navigationBar)
            .background(Color.sherpaBackground.ignoresSafeArea())
        }
        .onAppear {
            rewardedSessionCount = viewModel.totalFocusSessions
        }
        .onReceive(timer) { _ in
            viewModel.tick()
        }
        .onChange(of: viewModel.totalFocusSessions) { newValue in
            guard newValue > rewardedSessionCount else { return }
            let delta = newValue - rewardedSessionCount
            rewardedSessionCount = newValue
            xpStore.add(points: focusXPReward * delta)
            if reduceMotion {
                showCelebrationBadge()
            } else {
                confettiTrigger += 1
            }
        }
    }
}

private extension FocusHomeView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Sherpa Flow")
                .font(DesignTokens.Fonts.captionUppercase())
                .foregroundStyle(Color.sherpaTextSecondary)

            Text("Stay in the zone")
                .font(DesignTokens.Fonts.heroTitle())
                .foregroundStyle(Color.sherpaTextPrimary)

            Text("Complete Pomodoro sessions to earn XP and keep your streak climbing.")
                .font(DesignTokens.Fonts.body())
                .foregroundStyle(Color.sherpaTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var timerCard: some View {
        SherpaCard(backgroundStyle: .palette([DesignTokens.Colors.accentGold.opacity(0.32), DesignTokens.Colors.primary.opacity(0.35)])) {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text(viewModel.phase.title)
                    .font(DesignTokens.Fonts.sectionTitle())
                    .foregroundStyle(Color.sherpaTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(viewModel.phase.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.sherpaTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .stroke(
                            Color.white.opacity(0.28),
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )

                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.progress))
                        .stroke(
                            DesignTokens.Colors.primary,
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.4), value: viewModel.progress)

                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Text(formattedTime(from: viewModel.remainingSeconds))
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.sherpaTextPrimary)
                            .monospacedDigit()
                            .accessibilityLabel("\(formattedAccessibilityTime(from: viewModel.remainingSeconds)) remaining")

                        Text(viewModel.isInBreak ? "Break" : "Focus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.sherpaTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)

                HStack {
                    Label("Rewards", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.sherpaTextSecondary)

                    Spacer()

                    Text("+\(focusXPReward) XP / session")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.sherpaPrimary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.phase)
    }

    var sessionProgressCard: some View {
        SherpaCard(backgroundStyle: .solid(Color.white.opacity(0.92))) {
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack {
                    Text("Flow Sessions Completed")
                        .font(DesignTokens.Fonts.sectionTitle())
                        .foregroundStyle(Color.sherpaTextPrimary)

                    Spacer()

                    SherpaBadge(text: "\(xpStore.totalXP) XP", kind: .xp, icon: "⭐️")
                }

                HStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(fillColor(for: index))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Circle()
                                    .stroke(Color.sherpaTextSecondary.opacity(0.25), lineWidth: 1)
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.65), value: viewModel.completedSessionsInCycle)
                            .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(summaryText)
                    .font(.footnote)
                    .foregroundStyle(Color.sherpaTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    var controlsSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            if viewModel.phase == .idle {
                Button {
                    viewModel.startSession()
                } label: {
                    Label("Start Focus Session", systemImage: "play.fill")
                        .font(DesignTokens.Fonts.button())
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                }
                .sherpaPillStyle(background: LinearGradient(colors: [DesignTokens.Colors.primary, DesignTokens.Colors.accentBlue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .accessibilityIdentifier("focusStartButton")
            } else {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button {
                        viewModel.togglePause()
                    } label: {
                        Label(viewModel.isRunning ? "Pause" : "Resume", systemImage: viewModel.isRunning ? "pause.fill" : "play.fill")
                            .font(DesignTokens.Fonts.button())
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 52)
                    }
                    .sherpaPillStyle(
                        background: Color.white.opacity(0.92),
                        stroke: DesignTokens.Colors.primary.opacity(0.4)
                    )
                    .tint(Color.sherpaPrimary)
                    .accessibilityIdentifier("focusPauseResumeButton")

                    Button(role: .cancel) {
                        viewModel.reset()
                        rewardedSessionCount = viewModel.totalFocusSessions
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(DesignTokens.Fonts.button())
                            .frame(minWidth: 120)
                            .frame(minHeight: 52)
                    }
                    .sherpaPillStyle(
                        background: Color.white.opacity(0.12),
                        stroke: Color.white.opacity(0.3)
                    )
                    .foregroundStyle(Color.sherpaTextSecondary)
                    .accessibilityIdentifier("focusResetButton")
                }
            }

            if viewModel.isInBreak {
                Button {
                    viewModel.skipBreak()
                } label: {
                    Label("Skip Break", systemImage: "forward.end.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(DesignTokens.Colors.accentGold)
                .accessibilityIdentifier("focusSkipBreakButton")
            }
        }
    }

    var celebrationBadge: some View {
        VStack {
            Text("Focus streak +\(focusXPReward) XP 🎉")
                .font(.headline.weight(.semibold))
                .padding()
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.yellow.opacity(0.85))
                        .shadow(color: Color.yellow.opacity(0.35), radius: 18, y: 12)
                )
                .foregroundStyle(Color.sherpaTextPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, DesignTokens.Spacing.xl)
        .animation(.easeInOut(duration: 0.25), value: celebrateBadgeVisible)
    }

    func showCelebrationBadge() {
        celebrateBadgeVisible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            celebrateBadgeVisible = false
        }
    }

    func formattedTime(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }

    func formattedAccessibilityTime(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        var components: [String] = []
        if minutes > 0 {
            components.append("\(minutes) \(minutes == 1 ? "minute" : "minutes")")
        }
        components.append("\(remainder) \(remainder == 1 ? "second" : "seconds")")
        return components.joined(separator: " ")
    }

    func fillColor(for index: Int) -> Color {
        index < viewModel.completedSessionsInCycle ? DesignTokens.Colors.primary : Color.white.opacity(0.25)
    }

    var summaryText: String {
        if viewModel.totalFocusSessions == 0 {
            return "Complete your first 25-minute session to earn XP and unlock a longer break."
        }

        if viewModel.phase == .longBreak {
            return "Long break unlocked! Enjoy 15 minutes of downtime."
        }

        let progress = viewModel.completedSessionsInCycle % 4

        if progress == 0 {
            return "Cycle complete! Start the next sprint to keep momentum going."
        }

        let remaining = 4 - progress

        if remaining == 1 {
            return "One more focus sprint before your long break."
        }

        return "\(remaining) focus sprints until your long break."
    }
}

#Preview {
    FocusHomeView()
        .environmentObject(XPStore())
}
