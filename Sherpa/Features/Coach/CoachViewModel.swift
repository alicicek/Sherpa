//
//  CoachViewModel.swift
//  Sherpa
//
//  Extracted to keep CoachHomeView focused on layout.
//

import Combine
import SwiftUI

struct CoachMessage: Identifiable, Equatable {
    enum Role {
        case coach
        case user
    }

    let id = UUID()
    let text: String
    let role: Role
}

@MainActor
final class CoachViewModel: ObservableObject {
    @Published var messages: [CoachMessage] = []
    @Published var composerText: String = ""
    @Published var isCoachTyping: Bool = false

    private var responseIndex: Int = 0
    private var pendingResponseTasks: [UUID: _Concurrency.Task<Void, Never>] = [:]
    private let cannedResponses: [[String]] = [
        [
            L10n.string("coach.response.affirm1"),
            L10n.string("coach.response.affirm2"),
            L10n.string("coach.response.prompt1")
        ],
        [
            L10n.string("coach.response.listen1"),
            L10n.string("coach.response.listen2"),
            L10n.string("coach.response.prompt2")
        ],
        [
            L10n.string("coach.response.encourage1"),
            L10n.string("coach.response.prompt3")
        ]
    ]

    init() {
        seedConversation()
    }

    func sendComposerMessage() {
        let trimmed = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        composerText = ""
        appendUserMessage(trimmed)
        respondToUser()
    }

    func appendUserMessage(_ text: String) {
        messages.append(CoachMessage(text: text, role: .user))
    }

    private func respondToUser() {
        let response = cannedResponses[safe: responseIndex] ?? cannedResponses.randomElement() ?? []
        responseIndex = (responseIndex + 1) % cannedResponses.count
        guard !response.isEmpty else { return }

        cancelPendingResponses()

        isCoachTyping = true

        let leadDelay: TimeInterval = 1.0
        let bubbleSpacing: TimeInterval = 1.0

        for (index, bubble) in response.enumerated() {
            scheduleCoachBubble(
                text: bubble,
                delay: leadDelay + bubbleSpacing * Double(index),
                isLastBubble: index == response.count - 1
            )
        }
    }

    private func cancelPendingResponses() {
        pendingResponseTasks.values.forEach { $0.cancel() }
        pendingResponseTasks.removeAll()
        isCoachTyping = false
    }

    private func seedConversation() {
        messages = [
            CoachMessage(text: L10n.string("coach.seed.hello"), role: .coach),
            CoachMessage(text: L10n.string("coach.seed.intro"), role: .coach),
            CoachMessage(text: L10n.string("coach.seed.prompt"), role: .coach),
            CoachMessage(text: L10n.string("coach.seed.user"), role: .user)
        ]
    }

    private func scheduleCoachBubble(text: String, delay: TimeInterval, isLastBubble: Bool) {
        let taskID = UUID()
        let nanoseconds = UInt64(max(0, delay) * 1_000_000_000)

        let task = _Concurrency.Task { [weak self] in
            do {
                try await _Concurrency.Task.sleep(nanoseconds: nanoseconds)
            } catch {
                return
            }

            guard !_Concurrency.Task.isCancelled else { return }

            await MainActor.run {
                guard let self, !_Concurrency.Task.isCancelled else { return }
                self.messages.append(CoachMessage(text: text, role: .coach))
                if isLastBubble {
                    self.isCoachTyping = false
                }
                self.pendingResponseTasks.removeValue(forKey: taskID)
            }
        }

        pendingResponseTasks[taskID] = task
    }
}

final class KeyboardObserver: ObservableObject {
    @Published var currentHeight: CGFloat = 0

    private var cancellables: Set<AnyCancellable> = []

    init() {
        let willChange = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

        Publishers.Merge(willChange, willHide)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self else { return }

                guard let userInfo = notification.userInfo,
                      let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let windowScene = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first else {
                    self.currentHeight = 0
                    return
                }

                let screenHeight = windowScene.screen.bounds.height
                let overlap = max(0, screenHeight - endFrame.origin.y)
                self.currentHeight = overlap
            }
            .store(in: &cancellables)
    }
}

func hideKeyboard() {
#if canImport(UIKit)
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
