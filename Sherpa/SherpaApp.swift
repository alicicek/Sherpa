//
//  SherpaApp.swift
//  Sherpa
//
//  Created by Ali Cicek on 15/10/2025.
//

import OSLog
import SwiftData
import SwiftUI

@main
struct SherpaApp: App {
    private struct StartupIssue: Identifiable {
        let id = UUID()
        let message: String
    }

    @State private var modelContainer: ModelContainer?
    @State private var startupIssue: StartupIssue?
    @StateObject private var xpStore = XPStore()

    init() {
        let result = SherpaApp.makeModelContainer()
        _modelContainer = State(initialValue: result.container)
        _startupIssue = State(initialValue: result.issue)
    }

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                ContentView()
                    .modelContainer(container)
                    .environmentObject(xpStore)
            } else if let issue = startupIssue {
                StartupFailureView(message: issue.message) {
                    rebuildModelContainer()
                }
            } else {
                ProgressView()
            }
        }
    }

    private func rebuildModelContainer() {
        let result = SherpaApp.makeModelContainer()
        modelContainer = result.container
        startupIssue = result.issue
    }

    private static func makeModelContainer() -> (container: ModelContainer?, issue: StartupIssue?) {
        do {
            let container = try ModelContainer(
                for: Habit.self,
                Task.self,
                HabitInstance.self,
                RecurrenceRule.self
            )
            return (container, nil)
        } catch {
            Logger.startup.critical(
                "Failed to initialise model container: \(error.localizedDescription, privacy: .public)"
            )
            return (nil, StartupIssue(message: Self.startupFailureMessage(for: error)))
        }
    }

    private static func startupFailureMessage(for error: Error) -> String {
        if let localized = error as? LocalizedError {
            return localized.failureReason ?? localized.errorDescription ?? error.localizedDescription
        }
        return error.localizedDescription
    }
}
