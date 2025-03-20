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
        
        // Enhanced debugging to track the reordering operations
        if let firstIndex = fromOffsets.first {
            // Log the reordering operation for debugging
            TaskOrderDebugger.logReorderingOperation(
                fromIndex: firstIndex, 
                toIndex: toOffset,
                tasks: sectionTasks,
                in: sectionTitles.count > section ? sectionTitles[section] : "Section \(section)"
            )
        }
        
        // Create a mutable array of sectionTasks
        var updatedTasks = sectionTasks
        
        // Validate operation bounds
        guard let fromIndex = fromOffsets.first, fromIndex < updatedTasks.count else {
            print("⚠️ Invalid source index: \(fromOffsets)")
            return
        }
        
        // Ensure destination is within bounds
        let safeToOffset = min(toOffset, updatedTasks.count)
        if safeToOffset != toOffset {
            print("⚠️ Adjusted target index from \(toOffset) to \(safeToOffset)")
        }
        
        // Move the items
        // This is the core of the reordering logic - make sure it's consistent with inbox behavior
        updatedTasks.move(fromOffsets: fromOffsets, toOffset: safeToOffset)
        
        // Debug the move operation
        if let fromIndex = fromOffsets.first {
            // Safe index calculation
            let displayIndex = min(safeToOffset > fromIndex && safeToOffset > 0 ? safeToOffset - 1 : safeToOffset, updatedTasks.count - 1)
            
            if displayIndex < updatedTasks.count {
                print("🔄 Moving task '\(updatedTasks[displayIndex].title ?? "Untitled")' from position \(fromIndex) to \(safeToOffset)")
            } else {
                print("🔄 Moving task from position \(fromIndex) to \(safeToOffset)")
            }
        }
        
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
            
            // Verify the integrity of the display order
            if let project = self.selectedProject {
                TaskOrderDebugger.verifyDisplayOrderIntegrity(for: project, in: context)
            }
        }
    }
}
