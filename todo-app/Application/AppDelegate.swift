//
//  AppDelegate.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Cocoa
import SwiftUI
import CoreData

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // EMERGENCY FIX: Reset task ordering but skip project modification date
        FixTaskReordering.resetEverything()
        
        // Try again after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.repairTaskOrder()
        }
    }
    
    private func repairTaskOrder() {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        do {
            let items = try context.fetch(fetchRequest)
            print("🔄 Repairing display order for \(items.count) tasks")
            
            // Group by project
            let itemsByProject = Dictionary(grouping: items) { item in
                item.project?.id?.uuidString ?? "no-project"
            }
            
            // Reindex each group
            for (projectId, projectItems) in itemsByProject {
                var order: Int32 = 0
                
                // Sort by created date
                let sortedItems = projectItems.sorted { 
                    ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) 
                }
                
                print("  Setting display order for project: \(projectId)")
                
                for item in sortedItems {
                    item.setValue(order, forKey: "displayOrder")
                    order += 10
                }
            }
            
            // Use persistent order saving
            PersistentOrder.save(context: context)
            
            print("✅ Task ordering repaired")
        } catch {
            print("❌ Error repairing task order: \(error)")
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Force save any pending changes to ensure ordering is preserved
        PersistentOrder.saveAllContexts()
    }
    
    // Additional handlers to ensure data is saved

    func applicationDidResignActive(_ notification: Notification) {
        // App is going to background
        PersistentOrder.saveAllContexts()
    }
    
    func applicationWillHide(_ notification: Notification) {
        // App is being hidden
        PersistentOrder.saveAllContexts()
    }
}
