//
//  SherpaApp.swift
//  Sherpa
//
//  Created by Ali Cicek on 15/10/2025.
//

import SwiftData
import SwiftUI
import OSLog

@main
struct SherpaApp: App {
    private struct StartupIssue: Identifiable {
        let id = UUID()
        let message: String
    }

    @State private var modelContainer: ModelContainer?
    @State private var startupIssue: StartupIssue?
    @StateObject private var appContainer = AppContainer()

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
                    .environmentObject(appContainer.xpStore)
                    .environmentObject(appContainer)
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
                "Failed to initialise persistent model container: \(error.localizedDescription, privacy: .public)"
            )

            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            if let fallback = try? ModelContainer(
                for: Habit.self,
                    Task.self,
                    HabitInstance.self,
                    RecurrenceRule.self,
                configurations: fallbackConfig
            ) {
                Logger.startup.notice("Using in-memory fallback model container after start-up failure")
                return (fallback, StartupIssue(message: startupFailureMessage(for: error)))
            }

            Logger.startup.fault("Unable to create fallback in-memory model container")
            return (nil, StartupIssue(message: startupFailureMessage(for: error)))
        }
    }

    private static func startupFailureMessage(for error: Error) -> String {
        if let localized = error as? LocalizedError {
            return localized.failureReason ?? localized.errorDescription ?? error.localizedDescription
        }
        return error.localizedDescription
    }
}
