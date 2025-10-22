//
//  HabitsAddButton.swift
//  Sherpa
//
//  Extracted from HabitsHomeView so the layout file stays focused on composition.
//

import SwiftUI

struct AddHabitsButton: View {
    let action: () -> Void

    var body: some View {
        let title = L10n.string("habits.addButton.title").uppercased()
        Button(action: action) {
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(Color.white)
                .kerning(1.1)
                .accessibilityHidden(true)
        }
        .buttonStyle(AddHabitsButtonStyle())
        .accessibilityLabel(L10n.string("habits.addButton.label"))
    }
}

struct AddHabitsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        AddHabitsButtonStyleBody(configuration: configuration)
    }

    private struct AddHabitsButtonStyleBody: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled
        @State private var isHovered = false
        @State private var isPressedVisual = false

        private let buttonHeight: CGFloat = 54
        private let baseDrop: CGFloat = 6
        private let hoverLiftAmount: CGFloat = 1.6

        private var isPressed: Bool {
            configuration.isPressed && isEnabled
        }

        private var cornerRadius: CGFloat {
            DesignTokens.CornerRadius.small
        }

        private var faceColor: Color {
            Color(hex: "#58B62F")
        }

        private var baseColor: Color {
            Color(hex: "#2F7C1B")
        }

        private var hoverLift: Bool {
            isHovered && !isPressedVisual
        }

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            let baseYOffset: CGFloat = baseDrop
            let faceYOffset: CGFloat = isPressedVisual ? baseDrop : (hoverLift ? -hoverLiftAmount : 0)
            let faceBrightness: Double = hoverLift ? 0.07 : 0
            let baseBrightness: Double = hoverLift ? 0.08 : 0
            let faceScaleY: CGFloat = isPressedVisual ? 0.995 : 1
            let highlightOpacity: Double = 0.18
            let faceOutlineOpacity: Double = hoverLift ? 0.12 : 0.1

            ZStack {
                shape
                    .fill(baseColor)
                    .brightness(baseBrightness)
                    .frame(height: buttonHeight)
                    .offset(y: baseYOffset)

                shape
                    .fill(faceColor)
                    .brightness(faceBrightness)
                    .frame(height: buttonHeight)
                    .overlay(shape.fill(highlightGradient(opacity: highlightOpacity)))
                    .overlay(shape.stroke(Color.white.opacity(faceOutlineOpacity), lineWidth: 1))
                    .overlay(
                        configuration.label
                            .frame(maxWidth: .infinity, minHeight: buttonHeight, alignment: .center)
                    )
                    .scaleEffect(x: 1, y: faceScaleY, anchor: .center)
                    .offset(y: faceYOffset)
            }
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
            .contentShape(shape)
            .animation(.easeOut(duration: 0.14), value: isHovered)
#if os(iOS) || os(macOS)
            .onHover { hovering in
                isHovered = hovering
            }
#endif
            .onChange(of: isPressed) { _, pressed in
                if pressed {
                    withAnimation(nil) {
                        isPressedVisual = true
                    }
                } else {
                    withAnimation(.timingCurve(0.4, 1.44, 0.44, 0.88, duration: 0.2)) {
                        isPressedVisual = false
                    }
                }
            }
            .onAppear {
                isPressedVisual = isPressed
            }
        }

        private func highlightGradient(opacity: Double) -> LinearGradient {
            LinearGradient(
                colors: [
                    Color.white.opacity(opacity),
                    Color.white.opacity(0.05),
                    Color.white.opacity(0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
