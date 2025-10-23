import Foundation
import Testing
@testable import Sherpa

struct FocusTimerViewModelTests {
    @MainActor
    @Test
    func focusTimerTransitionsToShortBreakAfterFocus() {
        let viewModel = FocusTimerViewModel()
        viewModel.startSession()

        let focusDuration = viewModel.currentPhaseDuration
        fastForward(viewModel, seconds: focusDuration)

        #expect(viewModel.phase == .shortBreak)
        #expect(viewModel.totalFocusSessions == 1)
        #expect(viewModel.completedSessionsInCycle == 1)
        #expect(viewModel.remainingSeconds == viewModel.currentPhaseDuration)
    }

    @MainActor
    @Test
    func focusTimerPromotesToLongBreakAfterCycle() {
        let viewModel = FocusTimerViewModel()
        viewModel.startSession()

        for session in 1...4 {
            let focusDuration = viewModel.currentPhaseDuration
            fastForward(viewModel, seconds: focusDuration)

            if session < 4 {
                #expect(viewModel.phase == .shortBreak)
                let breakDuration = viewModel.currentPhaseDuration
                fastForward(viewModel, seconds: breakDuration)
                #expect(viewModel.phase == .focus)
            }
        }

        #expect(viewModel.phase == .longBreak)
        #expect(viewModel.totalFocusSessions == 4)
        #expect(viewModel.completedSessionsInCycle == 4)
    }

    @MainActor
    @Test
    func focusTimerSkipBreakResumesFocus() {
        let viewModel = FocusTimerViewModel()
        viewModel.startSession()

        let focusDuration = viewModel.currentPhaseDuration
        fastForward(viewModel, seconds: focusDuration)

        #expect(viewModel.phase == .shortBreak)
        viewModel.skipBreak()
        #expect(viewModel.phase == .focus)
        #expect(viewModel.isRunning)
    }

    @MainActor
    private func fastForward(_ viewModel: FocusTimerViewModel, seconds: Int) {
        for _ in 0..<seconds {
            viewModel.tick()
        }
    }
}
