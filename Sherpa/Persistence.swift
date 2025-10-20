//
//  Persistence.swift
//  Sherpa
//
//  Created by Ali Cicek on 15/10/2025.
//

import CoreData
import OSLog

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            Logger.persistence.error("Failed to create preview data: \(nsError), userInfo: \(nsError.userInfo)" )
            assertionFailure("Preview data seeding failed: \(nsError.localizedDescription)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Sherpa")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                Logger.persistence.critical("Failed to load persistent stores: \(error), userInfo: \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
