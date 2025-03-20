//
//  EnhancedTaskViewModel+Reordering.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData

// Direct implementation of task reordering to bypass any potential issues
extension EnhancedTaskViewModel {
    
    /// Direct implementation to reorder tasks within a section
    /// - Parameters:
    ///   - fromOffsets: Source indices
    ///   - toOffset: Destination index
    ///   - section: Section index where reordering occurs
    func reorderTasksInSection(fromOffsets: IndexSet, toOffset: Int, section: Int) {
        // Get the tasks for this section
        let sectionTasks = tasksForSection(section)
        guard !sectionTasks.isEmpty else { 
            print("⚠️ No tasks in section \(section)")
            return 
        }
        
        print("\n🔄 DIRECT REORDERING tasks in section \(section) from \(fromOffsets) to \(toOffset)")
        
        // Create a mutable array of sectionTasks
        var updatedTasks = sectionTasks
        
        // Move the items
        updatedTasks.move(fromOffsets: fromOffsets, toOffset: toOffset)
        
        print("New task order:")
        for (i, task) in updatedTasks.enumerated() {
            let order = Int32(i * 10)
            print(" [\(i)] '\(task.title ?? "Untitled")' - setting order: \(order)")
            task.setValue(order, forKey: "displayOrder")
        }
        
        // Get the context
        guard let context = sectionTasks.first?.managedObjectContext else {
            print("⚠️ Missing context")
            return
        }
        
        // Use the new PersistentOrder class to ensure changes are saved to disk
        PersistentOrder.save(context: context)
        
        // FORCE a notification to refresh UI
        NotificationCenter.default.post(
            name: NSNotification.Name.NSManagedObjectContextDidSave,
            object: context
        )
        
        // Force UI refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.refreshFetch()
        }
    }
}
