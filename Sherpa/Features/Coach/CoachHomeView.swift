//
//  CoachHomeView.swift
//  Sherpa
//
//  Created by Codex on 16/10/2025.
//

import Combine
import SwiftUI
import UIKit

@MainActor
final class CoachViewModel: ObservableObject {
    @Published var messages: [CoachMessage] = []
    @Published var composerText: String = ""
    @Published var isCoachTyping: Bool = false

    private var responseIndex: Int = 0
    private var pendingResponseWorkItems: [DispatchWorkItem] = []
    private let cannedResponses: [[String]] = [
        [
            "Love that energy!",
            "Remember: tiny wins count just as much as the big swings.",
            "Want help lining up one small action for today?",
        ],
        [
            "Totally hear you.",
            "Let’s zoom into the next hour instead of the whole day.",
            "What’s one thing you could wrap up before you take a break?",
        ],
        [
            "You’re building momentum, even if it doesn’t feel like it yet.",
            "How about we celebrate one win you’ve had this week?",
        ],
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
            var workItem: DispatchWorkItem?
            workItem = DispatchWorkItem { [weak self] in
                guard let self, let workItem else { return }

                let isLastBubble = index == response.count - 1

                if isLastBubble {
                    isCoachTyping = false
                }

                messages.append(CoachMessage(text: bubble, role: .coach))
                pendingResponseWorkItems.removeAll { $0 === workItem }
            }

            if let workItem {
                pendingResponseWorkItems.append(workItem)
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + leadDelay + bubbleSpacing * Double(index),
                    execute: workItem
                )
            }
        }

        if let lastBubbleDelay = response.indices.last {
            let totalDelay = leadDelay + bubbleSpacing * Double(lastBubbleDelay + 1)
            let typingReset = DispatchWorkItem { [weak self] in
                guard let self else { return }
                isCoachTyping = false
            }
            pendingResponseWorkItems.append(typingReset)
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay, execute: typingReset)
        }
    }

    private func cancelPendingResponses() {
        pendingResponseWorkItems.forEach { $0.cancel() }
        pendingResponseWorkItems.removeAll()
        isCoachTyping = false
    }

    private func seedConversation() {
        messages = [
            CoachMessage(text: "Hey, I’m Summit — your Sherpa coach.", role: .coach),
            CoachMessage(text: "Here for pep-talks, quick nudges, and the occasional reality check.", role: .coach),
            CoachMessage(text: "What’s on your mind today?", role: .coach),
            CoachMessage(text: "Just exploring the app right now!", role: .user),
        ]
    }
}

struct CoachHomeView: View {
    @StateObject private var viewModel = CoachViewModel()
    @StateObject private var keyboardObserver = KeyboardObserver()
    @FocusState private var isComposerFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let keyboardPadding = max(0, keyboardObserver.currentHeight - proxy.safeAreaInsets.bottom)

                ZStack {
                    Color.sherpaBackground
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        ConversationListView(
                            messages: viewModel.messages,
                            isCoachTyping: viewModel.isCoachTyping,
                            keyboardHeight: keyboardPadding,
                            onBackgroundTap: {
                                isComposerFocused = false
                                hideKeyboard()
                            }
                        )

                        Divider()
                            .overlay(Color.white)

                        CoachComposer(
                            text: $viewModel.composerText,
                            isFocused: $isComposerFocused,
                            onSend: {
                                viewModel.sendComposerMessage()
                            }
                        )
                        .padding(.bottom, keyboardPadding)
                    }
                }
            }
            .navigationTitle("Sherpa Coach")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Back", systemImage: "chevron.backward")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
        }
    }
}

@MainActor
private struct ConversationListView: View {
    private let bottomAnchorId = "conversation-bottom-anchor"

    let messages: [CoachMessage]
    let isCoachTyping: Bool
    let keyboardHeight: CGFloat
    var onBackgroundTap: () -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(messages) { message in
                        MessageRow(message: message)
                            .id(message.id)
                    }

                    if isCoachTyping {
                        TypingIndicatorRow()
                            .id("typing")
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchorId)
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.xl)
                .padding(.bottom, keyboardHeight)
                .frame(maxWidth: .infinity)
            }
            .background(Color.clear)
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture {
                onBackgroundTap()
            }
            .onChange(of: messages, initial: false) { @MainActor @Sendable (_: [CoachMessage], _: [CoachMessage]) in
                scrollToBottom(proxy)
            }
            .onChange(of: isCoachTyping, initial: false) { @MainActor @Sendable (_: Bool, newValue: Bool) in
                if newValue {
                    scrollToBottom(proxy)
                }
            }
            .onChange(of: keyboardHeight, initial: false) { @MainActor @Sendable (_: CGFloat, newValue: CGFloat) in
                if newValue > 0 {
                    scrollToBottom(proxy)
                }
            }
            .onAppear {
                scrollToBottom(proxy)
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(bottomAnchorId, anchor: .bottom)
            }
        }
    }
}

private struct MessageRow: View {
    let message: CoachMessage

    private var isUser: Bool { message.role == .user }
    private var avatarAssetName: String { isUser ? "userAvatar" : "coachAvatar" }
    private var messageAlignment: Alignment { isUser ? .trailing : .leading }
    private var contentAlignment: HorizontalAlignment { isUser ? .trailing : .leading }
    private var avatarBackgroundColor: Color { Color(red: 0.96, green: 0.93, blue: 0.86) }
    private var avatarBorderColor: Color { Color.sherpaPrimary.opacity(0.5) }

    var body: some View {
        HStack(alignment: .bottom, spacing: DesignTokens.Spacing.sm) {
            if isUser {
                Spacer(minLength: DesignTokens.Spacing.lg)
                messageContent
                avatarView
            } else {
                avatarView
                messageContent
                Spacer(minLength: DesignTokens.Spacing.lg)
            }
        }
        .frame(maxWidth: .infinity, alignment: messageAlignment)
    }

    private var messageContent: some View {
        VStack(alignment: contentAlignment, spacing: 0) {
            Text(message.text)
                .font(DesignTokens.Fonts.body())
                .foregroundStyle(isUser ? Color.white : Color.sherpaTextPrimary)
                .multilineTextAlignment(isUser ? .trailing : .leading)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(messageBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous))
                .frame(maxWidth: 260, alignment: isUser ? .trailing : .leading)
                .accessibilityLabel(accessibilityText)
        }
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(avatarBackgroundColor)
            Image(avatarAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        }
        .frame(width: 40, height: 40)
        .overlay(
            Circle()
                .stroke(avatarBorderColor, lineWidth: 1)
        )
        .accessibilityHidden(true)
    }

    private var messageBackground: some ShapeStyle {
        if isUser {
            Color.sherpaPrimary
        } else {
            Color.white
        }
    }

    private var accessibilityText: Text {
        Text(isUser ? "You said, \(message.text)" : "Coach said, \(message.text)")
    }
}

private struct TypingIndicatorRow: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: DesignTokens.Spacing.sm) {
            TypingBubble()
            Spacer(minLength: DesignTokens.Spacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TypingBubble: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(0 ..< 3) { index in
                Circle()
                    .fill(Color.sherpaTextSecondary.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .opacity(phase == CGFloat(index) ? 1 : 0.4)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous))
        .accessibilityLabel("Coach is typing")
        .task {
            var current = 0

            while true {
                withAnimation(.easeInOut(duration: 0.25)) {
                    phase = CGFloat(current)
                }

                current = (current + 1) % 3

                do {
                    try await _Concurrency.Task.sleep(nanoseconds: 380_000_000)
                } catch {
                    break
                }
            }
        }
    }
}

private struct CoachComposer: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            TextField("Type a message", text: $text, axis: .vertical)
                .lineLimit(1 ... 3)
                .textFieldStyle(.plain)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous)
                        .fill(Color.white)
                )
                .focused(isFocused)
                .submitLabel(.send)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }

            Button(
                action: onSend,
                label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? Color.sherpaTextSecondary.opacity(0.25)
                                        : Color.sherpaPrimary
                                )
                        )
                }
            )
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(
            Color.sherpaBackground
                .shadow(color: Color.black.opacity(0.05), radius: 6, y: -2)
        )
    }
}

struct CoachMessage: Identifiable, Equatable {
    enum Role {
        case coach
        case user
    }

    let id = UUID()
    let text: String
    let role: Role
}

private final class KeyboardObserver: ObservableObject {
    @Published var currentHeight: CGFloat = 0

    private var cancellables: Set<AnyCancellable> = []

    init() {
        let willChange = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

        Publishers.Merge(willChange, willHide)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self else { return }

                guard
                    let userInfo = notification.userInfo,
                    let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                    let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
                else {
                    currentHeight = 0
                    return
                }

                let screenHeight = windowScene.screen.bounds.height
                let overlap = max(0, screenHeight - endFrame.origin.y)
                currentHeight = overlap
            }
            .store(in: &cancellables)
    }
}

private func hideKeyboard() {
    #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    #endif
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

#Preview {
    CoachHomeView()
}
