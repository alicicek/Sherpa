//
//  Persistence.swift
//  Sherpa
//
//  Created by Ali Cicek on 15/10/2025.
//

import CoreData
import OSLog

@MainActor
struct PersistenceController {
    static let shared: PersistenceController = {
        do {
            return try PersistenceController()
        } catch {
            Logger.persistence.critical(
                "Falling back to transient persistence: \(error.localizedDescription, privacy: .public)"
            )
            return PersistenceController(disabledDueTo: error)
        }
    }()

    static let preview: PersistenceController = {
        do {
            let controller = try PersistenceController(inMemory: true)
            let viewContext = controller.container.viewContext
            for _ in 0..<10 {
                let newItem = Item(context: viewContext)
                newItem.timestamp = Date()
            }
            do {
                try viewContext.save()
            } catch {
                Logger.persistence.error(
                    "Failed to save preview context: \(error.localizedDescription, privacy: .public)"
                )
            }
            return controller
        } catch {
            Logger.persistence.error(
                "Unable to set up preview persistence store: \(error.localizedDescription, privacy: .public)"
            )
            return PersistenceController(disabledDueTo: error)
        }
    }()

    let container: NSPersistentContainer
    private(set) var loadError: Error?

    private init(disabledDueTo error: Error?) {
        container = NSPersistentContainer(name: "Sherpa")
        loadError = error
    }

    init(inMemory: Bool = false) throws {
        container = NSPersistentContainer(name: "Sherpa")
        if inMemory {
            if let description = container.persistentStoreDescriptions.first {
                description.url = URL(fileURLWithPath: "/dev/null")
            } else {
                Logger.persistence.error(
                    "Missing persistent store description when configuring in-memory store"
                )
            }
        }

        var capturedError: Error?
        container.loadPersistentStores { _, error in
            if let error {
                capturedError = error
                Logger.persistence.critical(
                    "Persistent store failed to load: \(error.localizedDescription, privacy: .public)"
                )
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        loadError = capturedError

        if let capturedError {
            throw capturedError
        }
    }

    func saveIfNeeded() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            Logger.persistence.error(
                "Failed to save persistence context: \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}
