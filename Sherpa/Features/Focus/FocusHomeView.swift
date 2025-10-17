//
//  FocusHomeView.swift
//  Sherpa
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
        GeometryReader { proxy in
            buildContent(safeAreaInsets: proxy.safeAreaInsets)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private extension FocusHomeView {
    @ViewBuilder
    func buildContent(safeAreaInsets: EdgeInsets) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl + DesignTokens.Spacing.lg) {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        phaseHeader
                        progressDots
                        timerDisplay
                        primaryControlButton
                    }
                    .frame(maxWidth: .infinity)

                    secondaryControls
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, safeAreaInsets.top + DesignTokens.Spacing.xl)
                .padding(.bottom, safeAreaInsets.bottom + DesignTokens.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground).ignoresSafeArea())
            .overlay {
                FocusConfettiView(trigger: confettiTrigger)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .top) {
                if celebrateBadgeVisible {
                    celebrationBadge
                        .transition(.opacity)
                        .padding(.top, DesignTokens.Spacing.xl)
                }
            }
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
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
    var phaseHeader: some View {
        Text(viewModel.isInBreak ? "Break" : "Flow")
            .font(.system(.title3, design: .rounded).weight(.medium))
            .foregroundStyle(Color.sherpaTextPrimary)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityAddTraits(.isHeader)
    }

    var progressDots: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(fillColor(for: index))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.sherpaTextSecondary.opacity(0.25), lineWidth: 1)
                    )
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.completedSessionsInCycle)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    var timerDisplay: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Text(formattedTime(from: viewModel.remainingSeconds))
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.sherpaTextPrimary)
                .accessibilityLabel("\(formattedAccessibilityTime(from: viewModel.remainingSeconds)) remaining")

            Text(viewModel.phase.title)
                .font(.subheadline)
                .foregroundStyle(Color.sherpaTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    var primaryControlButton: some View {
        Button {
            if viewModel.phase == .idle {
                viewModel.startSession()
            } else {
                viewModel.togglePause()
            }
        } label: {
            Image(systemName: primaryControlIconName)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.sherpaTextPrimary)
                .padding(DesignTokens.Spacing.lg)
                .background(
                    Circle()
                        .stroke(Color.sherpaTextPrimary.opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(primaryControlAccessibilityLabel)
        .accessibilityIdentifier("focusPrimaryControlButton")
    }

    var secondaryControls: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            Button {
                viewModel.reset()
                rewardedSessionCount = viewModel.totalFocusSessions
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.sherpaTextSecondary)
                    .padding(DesignTokens.Spacing.md)
                    .background(
                        Circle()
                            .stroke(Color.sherpaTextSecondary.opacity(0.25), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reset session")
            .accessibilityIdentifier("focusResetButton")

            if viewModel.isInBreak {
                Button {
                    viewModel.skipBreak()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.sherpaTextSecondary)
                        .padding(DesignTokens.Spacing.md)
                        .background(
                            Circle()
                                .stroke(Color.sherpaTextSecondary.opacity(0.25), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Skip break")
                .accessibilityIdentifier("focusSkipBreakButton")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
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
        index < viewModel.completedSessionsInCycle ? DesignTokens.Colors.primary : Color.sherpaTextSecondary.opacity(0.15)
    }

    var primaryControlIconName: String {
        if viewModel.phase == .idle { return "play.fill" }
        return viewModel.isRunning ? "pause.fill" : "play.fill"
    }

    var primaryControlAccessibilityLabel: String {
        if viewModel.phase == .idle { return "Start focus session" }
        return viewModel.isRunning ? "Pause timer" : "Resume timer"
    }
}

#Preview {
    FocusHomeView()
        .environmentObject(XPStore())
}
