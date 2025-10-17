//
//  FocusConfettiView.swift
//  Sherpa
//
//  Created by Codex on 20/10/2025.
//

import SwiftUI

struct FocusConfettiView: View {
    let trigger: Int

    @State private var emissionDate: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let particleCount = 44
    private let activeDuration: Double = 2.2

    var body: some View {
        TimelineView<AnimationTimelineSchedule, AnyView>(.animation(minimumInterval: 1.0 / 30.0), content: { timeline in
            AnyView(Canvas { context, size in
                guard let emissionDate else { return }

                let elapsed = timeline.date.timeIntervalSince(emissionDate)
                let duration = reduceMotion ? 0.4 : activeDuration

                guard elapsed <= duration else {
                    _Concurrency.Task { @MainActor in
                        self.emissionDate = nil
                    }
                    return
                }

                let travelHeight = size.height + 80.0
                let fadeOutStart = duration * 0.7
                let baseColor = Color.yellow.opacity(reduceMotion ? 0.7 : 0.92)

                for id in 0..<particleCount {
                    let base = Double(id) / Double(particleCount)
                    let stagger = base * 0.4
                    let timeFactor = elapsed - stagger
                    if timeFactor < 0 { continue }

                    let normalized = min(1.0, max(0.0, timeFactor) / max(0.001, duration - stagger))
                    let x = size.width * base + cos((elapsed + base) * 5.3) * 36
                    let y = normalized * travelHeight - 40

                    let opacityFactor: Double
                    if elapsed > fadeOutStart {
                        let fadeProgress = (elapsed - fadeOutStart) / max(0.001, duration - fadeOutStart)
                        opacityFactor = max(0.0, 1.0 - fadeProgress)
                    } else {
                        opacityFactor = 1.0
                    }

                    var particleContext = context
                    particleContext.opacity = opacityFactor

                    let rect = CGRect(x: x - 3, y: y - 6, width: 6, height: 12)
                    let path = Path(roundedRect: rect, cornerRadius: 2)
                    particleContext.fill(path, with: .color(baseColor))
                }
            })
        })
        .allowsHitTesting(false)
        .opacity(emissionDate == nil ? 0 : 1)
        .onChange(of: trigger) { newValue in
            guard newValue > 0 else { return }
            emissionDate = Date()
        }
        .accessibilityHidden(true)
    }
}
