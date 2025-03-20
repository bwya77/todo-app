//
//  PersistenceController.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//  Refactored according to improvement plan on 3/7/25.
//  Updated on 3/12/25 to support migration and optimized model.
//

import CoreData
import SwiftUI

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create projects using the optimized extension methods
        let inbox = Project.create(in: viewContext, name: "Inbox", color: "blue")
        let workProject = Project.create(in: viewContext, name: "Work", color: "red")
        let personalProject = Project.create(in: viewContext, name: "Personal", color: "green")
        
        // Create tags using the optimized extension methods
        let urgentTag = Tag.create(in: viewContext, name: "Urgent", color: "red")
        let homeTag = Tag.create(in: viewContext, name: "Home", color: "purple")
        
        // Create sample tasks
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Task for today
        let task1 = Item.create(
            in: viewContext,
            title: "Respond to emails",
            dueDate: currentDate,
            priority: .low,
            project: workProject
        )
        task1.addTag(urgentTag)
        
        // Task for tomorrow
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate) {
            let task2 = Item.create(
                in: viewContext,
                title: "Take trash out",
                dueDate: tomorrow,
                priority: .medium,
                project: personalProject
            )
            task2.addTag(homeTag)
        }
        
        // Task for next week
        if let nextWeek = calendar.date(byAdding: .day, value: 7, to: currentDate) {
            let task3 = Item.create(
                in: viewContext,
                title: "Create UI mockups",
                dueDate: nextWeek,
                priority: .high,
                project: workProject
            )
        }
        
        // Add more sample tasks
        let task4 = Item.create(
            in: viewContext,
            title: "Edit the task list view",
            dueDate: calendar.date(byAdding: .day, value: 3, to: currentDate),
            priority: .medium,
            project: personalProject
        )
        
        let task5 = Item.create(
            in: viewContext,
            title: "Bug bounty submission",
            dueDate: calendar.date(byAdding: .day, value: 6, to: currentDate),
            priority: .high,
            project: workProject
        )
        
        // March 17 tasks
        if let march17 = calendar.date(from: DateComponents(year: 2025, month: 3, day: 17)) {
            let task6 = Item.create(
                in: viewContext,
                title: "Add new GitHub repo",
                dueDate: march17,
                priority: .medium,
                project: workProject
            )
        }
        
        // March 31 tasks
        if let march31 = calendar.date(from: DateComponents(year: 2025, month: 3, day: 31)) {
            let task7 = Item.create(
                in: viewContext,
                title: "Contuit: Ship MVP",
                dueDate: march31,
                priority: .low,
                project: workProject
            )
            
            let task8 = Item.create(
                in: viewContext,
                title: "Pay Mortgage",
                dueDate: march31,
                priority: .low,
                project: personalProject
            )
            
            let task9 = Item.create(
                in: viewContext,
                title: "Weight Check",
                dueDate: march31,
                priority: .high,
                project: personalProject
            )
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "todo_app")
        
        // Configure the container
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // CRITICAL UPDATE - Add pragmas for better durability
        if let description = container.persistentStoreDescriptions.first, !inMemory {
            // Set options for better durability
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            
            // Configure SQLite options
            var sqliteOptions = [String: String]()
            
            // Set journal mode to WAL (write-ahead logging) for better concurrency
            sqliteOptions["journal_mode"] = "WAL"
            
            // Set synchronous mode to FULL for maximum durability (prevents data loss on system crash)
            sqliteOptions["synchronous"] = "FULL"
            
            // Set busy timeout to 5 seconds (5000 ms)
            sqliteOptions["busy_timeout"] = "5000"
            
            // Apply the options
            description.setOption(sqliteOptions as NSDictionary, forKey: NSSQLitePragmasOption)
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Instead of crashing, log the error and potentially handle migration issues
                print("Persistent store loading error: \(error), \(error.userInfo)")
                
                // If this is a migration error, you could try to recover
                if (error.domain == NSCocoaErrorDomain && 
                    [NSPersistentStoreIncompatibleVersionHashError, NSMigrationError, NSMigrationMissingSourceModelError].contains(error.code)) {
                    print("Migration error - attempting recovery...")
                    
                    // We'll handle repair via AppDelegate instead
                }
            }
        })
        
        // Enable automatic merge from parent contexts
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Improve error handling by setting a merge policy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Configure save notifications to enable handling conflicts
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main) { [weak container] notification in
                
                guard let context = notification.object as? NSManagedObjectContext,
                      context != container?.viewContext else {
                    return
                }
                
                container?.viewContext.perform {
                    container?.viewContext.mergeChanges(fromContextDidSave: notification)
                }
            }
    }
    
    // Helper to create a background context for performing operations off the main thread
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // Helper to perform an operation on a background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = newBackgroundContext()
        context.perform {
            block(context)
        }
    }
    
    // Helper to perform an operation that returns a result on a background context
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = newBackgroundContext()
        return try await context.perform {
            try block(context)
        }
    }
}
