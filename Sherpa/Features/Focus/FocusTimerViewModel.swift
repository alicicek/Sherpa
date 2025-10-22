//
//  FocusTimerViewModel.swift
//  Sherpa
//
//  Created by Codex on 20/10/2025.
//

import Foundation
import Combine

@MainActor
final class FocusTimerViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case focus
        case shortBreak
        case longBreak

        var title: String {
            switch self {
            case .idle:
                return L10n.string("focus.timer.phase.ready")
            case .focus:
                return L10n.string("focus.timer.phase.focus")
            case .shortBreak:
                return L10n.string("focus.timer.phase.shortBreak")
            case .longBreak:
                return L10n.string("focus.timer.phase.longBreak")
            }
        }

        var subtitle: String {
            switch self {
            case .idle:
                return L10n.string("focus.timer.subtitle.ready")
            case .focus:
                return L10n.string("focus.timer.subtitle.focus")
            case .shortBreak:
                return L10n.string("focus.timer.subtitle.shortBreak")
            case .longBreak:
                return L10n.string("focus.timer.subtitle.longBreak")
            }
        }
    }

    private enum Config {
        static let focusSeconds: Int = 25 * 60
        static let shortBreakSeconds: Int = 5 * 60
        static let longBreakSeconds: Int = 15 * 60
        static let sessionsPerLongBreak: Int = 4
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var remainingSeconds: Int = Config.focusSeconds
    @Published private(set) var currentPhaseDuration: Int = Config.focusSeconds
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var completedSessionsInCycle: Int = 0
    @Published private(set) var totalFocusSessions: Int = 0

    var isInBreak: Bool {
        phase == .shortBreak || phase == .longBreak
    }

    var isPaused: Bool {
        !isRunning && phase != .idle && remainingSeconds < currentPhaseDuration
    }

    var progress: Double {
        guard currentPhaseDuration > 0, phase != .idle else { return 0 }
        let elapsed = currentPhaseDuration - remainingSeconds
        return Double(elapsed) / Double(currentPhaseDuration)
    }

    /// Advances the timer by one second when active.
    func tick() {
        guard isRunning, phase != .idle else { return }

        if remainingSeconds > 1 {
            remainingSeconds -= 1
            return
        }

        remainingSeconds = 0
        handlePhaseCompletion()
    }

    func startSession() {
        switch phase {
        case .idle:
            transition(to: .focus)
        default:
            isRunning = true
        }
    }

    func togglePause() {
        guard phase != .idle else { return }
        isRunning.toggle()
    }

    func skipBreak() {
        guard isInBreak else { return }

        if phase == .longBreak {
            completedSessionsInCycle = 0
        }

        transition(to: .focus)
    }

    func reset() {
        phase = .idle
        currentPhaseDuration = Config.focusSeconds
        remainingSeconds = Config.focusSeconds
        isRunning = false
        completedSessionsInCycle = 0
    }

    private func handlePhaseCompletion() {
        isRunning = false

        switch phase {
        case .focus:
            completedSessionsInCycle += 1
            totalFocusSessions += 1

            if completedSessionsInCycle % Config.sessionsPerLongBreak == 0 {
                transition(to: .longBreak)
            } else {
                transition(to: .shortBreak)
            }

        case .shortBreak:
            transition(to: .focus)

        case .longBreak:
            completedSessionsInCycle = 0
            transition(to: .focus)

        case .idle:
            break
        }
    }

    private func transition(to newPhase: Phase) {
        phase = newPhase

        switch newPhase {
        case .idle:
            currentPhaseDuration = Config.focusSeconds
            remainingSeconds = Config.focusSeconds
            isRunning = false

        case .focus:
            currentPhaseDuration = Config.focusSeconds
            remainingSeconds = Config.focusSeconds
            isRunning = true

        case .shortBreak:
            currentPhaseDuration = Config.shortBreakSeconds
            remainingSeconds = Config.shortBreakSeconds
            isRunning = true

        case .longBreak:
            currentPhaseDuration = Config.longBreakSeconds
            remainingSeconds = Config.longBreakSeconds
            isRunning = true
        }
    }
}
