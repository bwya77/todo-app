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
            return 
        }
        
        // Create a mutable array of sectionTasks
        var updatedTasks = sectionTasks
        
        // Validate operation bounds
        guard let fromIndex = fromOffsets.first, fromIndex < updatedTasks.count else {
            return
        }
        
        // Ensure destination is within bounds
        let safeToOffset = min(toOffset, updatedTasks.count)
        
        // Move the items - this is the core of the reordering logic
        updatedTasks.move(fromOffsets: fromOffsets, toOffset: safeToOffset)
        
        // Update display order values with spacing
        for (i, task) in updatedTasks.enumerated() {
            let order = Int32(i * 10)
            task.setValue(order, forKey: "displayOrder")
        }
        
        // Validate that we have a valid context
        guard sectionTasks.first?.managedObjectContext != nil else {
            return
        }
        
        // Save changes
        saveContext()
        
        // Force UI refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.refreshFetch()
        }
    }
    
    /// Save current task order to ensure persistence
    func persistCurrentTaskOrder() {
        // Get any task's context, as they all share the same context
        if let firstSection = tasksBySection.first, 
           let firstTask = firstSection.first,
           let context = firstTask.managedObjectContext {
            
            // For each section, ensure display order values are properly set
            for sectionIndex in 0..<tasksBySection.count {
                let sectionTasks = tasksBySection[sectionIndex]
                
                // Skip empty sections
                if sectionTasks.isEmpty {
                    continue
                }
                
                // Set display order values with spacing
                for (index, task) in sectionTasks.enumerated() {
                    let orderValue = Int32(index * 10)
                    task.setValue(orderValue, forKey: "displayOrder")
                }
            }
            
            // Save changes to disk
            if context.hasChanges {
                try? context.save()
            }
        } else {
            // Try to use saveContext as a fallback
            saveContext()
        }
    }
}
