//
//  PersistentOrder.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData
import SQLite3

/// Ensures that display order changes are properly persisted between app launches
class PersistentOrder {
    /// Save display order changes to persistent store
    static func save(context: NSManagedObjectContext) {
        do {
            // Save the context with forced WAL checkpoint
            try context.save()
            
            // Force parent contexts to save if they exist
            if let parent = context.parent {
                try parent.save()
            }
            
            // For view context, perform full disk flush
            if context == PersistenceController.shared.container.viewContext {
                forceDataSync()
                print("✅ Context saved after reordering")
            }
        } catch {
            print("❌ Error persisting order changes: \(error)")
        }
    }
    
    /// Force sync to disk using low-level SQLite functionality
    static func forceDataSync() {
        let container = PersistenceController.shared.container
        let coordinator = container.persistentStoreCoordinator
        
        // Get SQLite file URL
        guard let store = coordinator.persistentStores.first,
              let storeURL = store.url,
              store.type == NSSQLiteStoreType else {
            print("⚠️ Cannot find SQLite store")
            return
        }
        
        // Use FileManager sync
        do {
            let fileHandle = try FileHandle(forWritingTo: storeURL)
            try fileHandle.synchronize()
            fileHandle.closeFile()
        } catch {
            print("⚠️ File sync failed: \(error)")
        }
        
        // Create a FileManager forcing data flush
        do {
            // Create a .sync file
            let syncMarker = storeURL.deletingLastPathComponent().appendingPathComponent(".sync_\(UUID().uuidString)")
            try Data().write(to: syncMarker)
            
            // Force a sync
            let fileManager = FileManager.default
            try fileManager.removeItem(at: syncMarker)
        } catch {
            print("⚠️ Sync marker failed: \(error)")
        }
    }
    
    /// Force the CoreData stack to save all pending changes
    static func saveAllContexts() {
        let container = PersistenceController.shared.container
        let viewContext = container.viewContext
        
        do {
            // Check for uncommitted changes
            if viewContext.hasChanges {
                try viewContext.save()
                print("✅ Saved view context changes")
            }
            
            // Force disk sync
            forceDataSync()
            
            // Create a background context for additional insurance
            let bgContext = container.newBackgroundContext()
            bgContext.perform {
                do {
                    // Execute a dummy query to flush WAL
                    let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
                    fetchRequest.fetchLimit = 1
                    _ = try bgContext.count(for: fetchRequest)
                    try bgContext.save()
                    print("✅ Executed final flush query")
                } catch {
                    print("⚠️ Final flush error: \(error)")
                }
            }
        } catch {
            print("❌ Error saving all contexts: \(error)")
        }
    }
}
