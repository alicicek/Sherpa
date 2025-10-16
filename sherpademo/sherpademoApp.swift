//
//  sherpademoApp.swift
//  sherpademo
//
//  Created by Ali Cicek on 15/10/2025.
//

import SwiftUI
import SwiftData

@main
struct sherpademoApp: App {
    @State private var modelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: Habit.self,
                    Task.self,
                    HabitInstance.self,
                    RecurrenceRule.self
            )
        } catch {
            fatalError("Failed to initialise model container: \(error)")
        }
    }()
    @StateObject private var xpStore = XPStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environmentObject(xpStore)
        }
    }
}
