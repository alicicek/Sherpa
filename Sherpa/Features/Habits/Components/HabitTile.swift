//
//  HabitTile.swift
//  Sherpa
//
//  Extracted to keep HabitsHomeView lean and document the animation contract.
//

import SwiftUI
import OSLog

struct HabitTileModel {
    let title: String
    let subtitle: String
    let iconSystemName: String
    let goal: Double
    let unit: String
    let step: Double
    let accentColor: Color
    let backgroundColor: Color
}

/// Visual tile used on the Habits home list. Handles drag gestures, snapping, haptics and display state.
struct HabitTile: View {
    let model: HabitTileModel
    @Binding var progress: Double
    var onDragStateChange: (Bool) -> Void = { _ in }
    var onProgressChange: (Double) -> Void

    @State private var isDragging: Bool = false
    @State private var hasCelebratedCompletion = false
    @State private var dragStartProgress: Double = 0
    @State private var displayProgress: Double = 0
    @State private var lastPreviewQuantized: Double = 0
    @State private var lastCommittedQuantized: Double = 0
    @State private var lastHapticTimestamp: TimeInterval = 0

    private let lightFeedback = UIImpactFeedbackGenerator(style: .light)
    private let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let rigidFeedback = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private let tileHeight: CGFloat = 68

    private static let dragFollowAnimation = Animation.interpolatingSpring(mass: 1.1, stiffness: 120, damping: 20, initialVelocity: 0)
    private static let dragBlendFactor: Double = 0.225
    private static let snapAnimation = Animation.spring(response: 0.32, dampingFraction: 0.85, blendDuration: 0)

    private enum UX {
        static let goalPredictiveThreshold: Double = 0.95
        static let zeroPredictiveThreshold: Double = -0.05
        static let dragWidthFractionGoal: CGFloat = 0.6
        static let dragWidthFractionZero: CGFloat = 0.6
        static let dragHorizontalGate: CGFloat = 6
        static let hapticDebounce: TimeInterval = 0.035
        static let dragMinimumDistance: CGFloat = 12
    }

    private var displayRatio: Double {
        guard model.goal > 0 else { return 0 }
        return min(max(displayProgress / model.goal, 0), 1)
    }

    private var progressText: String {
        let valueForDisplay = isDragging ? lastPreviewQuantized : progress
        let current = HabitTile.numberFormatter.string(from: NSNumber(value: valueForDisplay)) ?? "0"
        let goal = HabitTile.numberFormatter.string(from: NSNumber(value: model.goal)) ?? "0"
        let unit = model.unit.isEmpty ? "" : " \(model.unit)"
        return "\(current)/\(goal)\(unit)"
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let cornerRadius = DesignTokens.CornerRadius.small
            let fillWidth = max(width * displayRatio, 0)
            let fillCornerRadius = min(cornerRadius, fillWidth / 2)

            let isComplete = displayRatio >= 1 - HabitMetrics.completionTolerance
            let fillOpacity: Double = isComplete ? 0.5 : 0.42

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(model.backgroundColor)

                // Keep the fill permanently mounted so width changes never trigger SwiftUI's remove/reinsert fade.
                RoundedRectangle(cornerRadius: fillCornerRadius, style: .continuous)
                    .fill(model.accentColor.opacity(fillOpacity))
                    .frame(width: max(0, fillWidth))
                    .transition(.identity)

                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: model.iconSystemName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(model.accentColor)
                        .frame(width: 44, height: 44)
                        .background(model.accentColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .animation(nil, value: isDragging)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.sherpaTextPrimary)
                            .lineLimit(1)

                        Text(model.subtitle)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.sherpaTextSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: DesignTokens.Spacing.md)

                    Text(progressText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.sherpaTextPrimary.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                // Lock progress text layout to the drag animation; implicit animations cause stutter when the fill snaps.
                .animation(nil, value: displayProgress)
            }
            .frame(height: tileHeight)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(model.accentColor.opacity(isDragging ? 0.22 : 0.14), lineWidth: 1)
                    // Outline responds instantly to drag to reinforce the "grabbed" state.
                    .animation(nil, value: isDragging)
            )
            .shadow(color: Color.black.opacity(isDragging ? 0.08 : 0.05), radius: isDragging ? 10 : 8, y: isDragging ? 6 : 4)
            // The outer shell skips implicit animations so we control all transitions via explicit springs.
            .animation(nil, value: isDragging)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .simultaneousGesture(dragGesture(totalWidth: width))
        }
        .frame(height: tileHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.title)
        .accessibilityValue(progressText)
        .accessibilityHint(Text(L10n.string("habits.tile.accessibility.hint")))
        .accessibilityAdjustableAction { direction in
            let delta = direction == .increment ? model.step : -model.step
            commitProgress(to: progress + delta)
        }
        .onAppear {
            displayProgress = progress
            handleCompletionState(for: progress)

            let quantized = quantize(progress)
            lastPreviewQuantized = quantized
            lastCommittedQuantized = quantized
        }
        .onChange(of: progress) { _, newValue in
            if isDragging == false {
                withAnimation(.easeOut(duration: 0.18)) {
                    displayProgress = newValue
                }
                let quantized = quantize(newValue)
                lastPreviewQuantized = quantized
                lastCommittedQuantized = quantized
            }
            handleCompletionState(for: newValue)
        }
    }

    private func dragGesture(totalWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: UX.dragMinimumDistance, coordinateSpace: .local)
            .onChanged { value in
                if !isDragging {
                    let horizontalMagnitude = abs(value.translation.width)
                    let verticalMagnitude = abs(value.translation.height)
                    guard horizontalMagnitude > verticalMagnitude, horizontalMagnitude > UX.dragHorizontalGate else {
                        return
                    }
                    // Toggle drag state inside a transaction with nil animation so the tile snaps instantly to the interaction state.
                    withTransaction(Transaction(animation: nil)) {
                        isDragging = true
                        onDragStateChange(true)
                    }
                    dragStartProgress = progress
                    hasCelebratedCompletion = progress >= model.goal - HabitMetrics.completionTolerance
                    lastPreviewQuantized = quantize(progress)
                    prepareFeedbackGenerators()
                }

                guard isDragging else { return }

                let deltaRatio = Double(value.translation.width / max(totalWidth, 1))
                let target = dragStartProgress + (deltaRatio * model.goal)
                let clamped = max(0, min(model.goal, target))
                withAnimation(Self.dragFollowAnimation) {
                    displayProgress += (clamped - displayProgress) * Self.dragBlendFactor
                }

                let quantized = quantize(clamped)
                if abs(quantized - lastPreviewQuantized) > HabitMetrics.completionTolerance {
                    emitStepHaptic(from: lastPreviewQuantized, to: quantized)
                    lastPreviewQuantized = quantized
                }
                handleCompletionState(for: clamped)
            }
            .onEnded { value in
                guard isDragging else { return }

                let deltaRatio = Double(value.translation.width / max(totalWidth, 1))
                let predictedRatio = Double(value.predictedEndTranslation.width / max(totalWidth, 1))
                let predictedTarget = dragStartProgress + (predictedRatio * model.goal)
                let target = dragStartProgress + (deltaRatio * model.goal)

                let shouldSnapToGoal = predictedTarget >= model.goal * UX.goalPredictiveThreshold || value.translation.width >= totalWidth * UX.dragWidthFractionGoal
                let shouldSnapToZero = predictedTarget <= model.goal * UX.zeroPredictiveThreshold || value.translation.width <= -totalWidth * UX.dragWidthFractionZero

                if shouldSnapToGoal {
                    rigidFeedback.prepare()
                    commitProgress(to: model.goal)
                    rigidFeedback.impactOccurred()
                } else if shouldSnapToZero {
                    rigidFeedback.prepare()
                    commitProgress(to: 0)
                    rigidFeedback.impactOccurred()
                } else if model.goal <= model.step {
                    if target >= model.goal * 0.5 {
                        rigidFeedback.prepare()
                        commitProgress(to: model.goal)
                        rigidFeedback.impactOccurred()
                    } else {
                        rigidFeedback.prepare()
                        commitProgress(to: 0)
                        if dragStartProgress > 0 {
                            rigidFeedback.impactOccurred()
                        }
                    }
                } else {
                    commitProgress(to: target)
                }

                withTransaction(Transaction(animation: nil)) {
                    isDragging = false
                    onDragStateChange(false)
                }
            }
    }

    private func commitProgress(to target: Double) {
        let clampedRaw = max(0, min(model.goal, target))
        let quantized = quantize(clampedRaw)
        let previousQuantized = lastCommittedQuantized

        if abs(quantized - previousQuantized) <= HabitMetrics.completionTolerance {
            progress = quantized
            lastPreviewQuantized = quantized
            lastCommittedQuantized = quantized
            handleCompletionState(for: quantized)
            withAnimation(Self.snapAnimation) {
                displayProgress = quantized
            }
            return
        }

        let targetProgress = quantized

        progress = quantized
        onProgressChange(quantized)

        if abs(quantized - lastPreviewQuantized) > HabitMetrics.completionTolerance {
            emitStepHaptic(from: previousQuantized, to: quantized)
            lastPreviewQuantized = quantized
        }

        handleCompletionState(for: quantized)
        lastCommittedQuantized = quantized

        withAnimation(Self.snapAnimation) {
            displayProgress = targetProgress
        }
    }

    private func emitStepHaptic(from previous: Double, to newValue: Double) {
        guard model.step > 0 else { return }

        let previousIndex = Int((previous / model.step).rounded(.down))
        let newIndex = Int((newValue / model.step).rounded(.down))
        let delta = newIndex - previousIndex

        guard delta != 0 else { return }

        let now = ProcessInfo.processInfo.systemUptime
        if now - lastHapticTimestamp < UX.hapticDebounce { return }
        lastHapticTimestamp = now

        if newValue >= model.goal - HabitMetrics.completionTolerance {
            guard hasCelebratedCompletion == false else { return }
            notificationFeedback.prepare()
            notificationFeedback.notificationOccurred(.success)
            hasCelebratedCompletion = true
            return
        }

        hasCelebratedCompletion = false
        let normalizedIntensity = min(1.0, 0.45 + 0.1 * Double(abs(delta)))

        if delta > 0 {
            mediumFeedback.prepare()
            mediumFeedback.impactOccurred(intensity: CGFloat(normalizedIntensity))
        } else {
            lightFeedback.prepare()
            lightFeedback.impactOccurred(intensity: CGFloat(normalizedIntensity))
        }
    }

    private func prepareFeedbackGenerators() {
        mediumFeedback.prepare()
        lightFeedback.prepare()
        notificationFeedback.prepare()
        rigidFeedback.prepare()
    }

    private func handleCompletionState(for value: Double) {
        let isComplete = value >= model.goal - HabitMetrics.completionTolerance
        if !isComplete {
            hasCelebratedCompletion = false
        }
    }

    private func quantize(_ value: Double) -> Double {
        guard model.step > 0 else { return value }
        let stepCount = (value / model.step).rounded()
        return stepCount * model.step
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        formatter.roundingMode = .down
        return formatter
    }()
}

#Preview("Habit Tile") {
    HabitTilePreview()
}

private struct HabitTilePreview: View {
    @State private var progress: Double = 1350

    private let model = HabitTileModel(
        title: "Drink Water",
        subtitle: "Hydration",
        iconSystemName: "drop.fill",
        goal: 3000,
        unit: "ml",
        step: 250,
        accentColor: Color(hex: "#28A6FF"),
        backgroundColor: Color(hex: "#DFF1FF")
    )

    var body: some View {
        HabitTile(model: model, progress: $progress) { newValue in
            progress = newValue
        }
        .padding()
        .background(Color.sherpaBackground)
    }
}
