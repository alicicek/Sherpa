//
//  CoachHomeView.swift
//  Sherpa
//
//  Created by Codex on 16/10/2025.
//

import SwiftUI

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
            .navigationTitle(L10n.string("coach.navigation.title"))
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label(L10n.string("coach.button.back"), systemImage: "chevron.backward")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
        }
    }
}

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
            .onChange(of: messages) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: isCoachTyping) { _, newValue in
                if newValue {
                    scrollToBottom(proxy)
                }
            }
            .onChange(of: keyboardHeight) { _, newValue in
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
        _Concurrency.Task { @MainActor in
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
            return Color.sherpaPrimary
        } else {
            return Color.white
        }
    }

    private var accessibilityText: Text {
        if isUser {
            return Text(L10n.string("coach.accessibility.user", message.text))
        }
        return Text(L10n.string("coach.accessibility.coach", message.text))
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
            ForEach(0..<3) { index in
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
        .accessibilityLabel(L10n.string("coach.typing"))
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
                    TextField(L10n.string("coach.message.placeholder"), text: $text, axis: .vertical)
                        .lineLimit(1...3)
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

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.sherpaTextSecondary.opacity(0.25) : Color.sherpaPrimary)
                    )
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel(L10n.string("coach.button.send"))
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(
            Color.sherpaBackground
                .shadow(color: Color.black.opacity(0.05), radius: 6, y: -2)
        )
    }
}

#Preview {
    CoachHomeView()
}
