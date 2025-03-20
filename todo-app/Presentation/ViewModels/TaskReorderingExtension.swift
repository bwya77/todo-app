//
//  TaskReorderingExtension.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData
import SwiftUI

/// Adds reordering capabilities to the EnhancedTaskViewModel
extension EnhancedTaskViewModel {
    
    /// Updates the display order for tasks within a section and saves changes
    /// - Parameters:
    ///   - tasks: Array of tasks to update
    ///   - save: Whether to save the context immediately
    func updateTaskDisplayOrder(for tasks: [Item], save: Bool = true) {
        // Print debug info
        print("🏷️ Updating display order for \(tasks.count) tasks")
        
        for (index, task) in tasks.enumerated() {
            print("  Setting task '\(task.title ?? "Untitled")' display order: \(index)")
            task.displayOrder = Int32(index)
        }
        
        if save {
            saveContext()
            
            // Force a notification to update all views
            if let context = tasks.first?.managedObjectContext {
                NotificationCenter.default.post(
                    name: NSNotification.Name.NSManagedObjectContextDidSave,
                    object: context
                )
            }
        }
    }
    
    /// Public method to reorder tasks within a section
    /// - Parameters:
    ///   - fromOffsets: Source indices
    ///   - toOffset: Destination index
    ///   - section: Section index where reordering occurs
    func moveTasksInSection(fromOffsets: IndexSet, toOffset: Int, section: Int) {
        // Get tasks for this section
        let sectionTasks = tasksForSection(section)
        
        // Create a mutable copy of the section tasks and perform the move
        var updatedSectionTasks = sectionTasks
        updatedSectionTasks.move(fromOffsets: fromOffsets, toOffset: toOffset)
        
        // Update the display order for all tasks in the section
        updateTaskDisplayOrder(for: updatedSectionTasks, save: true)
        
        // Get the project if available
        let project = updatedSectionTasks.first?.project
        
        // If we're in a project view, update the project's lastModifiedDate
        if let project = project {
            project.setValue(Date(), forKey: "lastModifiedDate")
            print("Updated project lastModifiedDate: \(project.name ?? "Unknown")")
        }
        
        // Refresh the UI
        refreshFetch()
    }
    
    /// Public method to reorder all tasks (when not using sections)
    /// - Parameters:
    ///   - fromOffsets: Source indices
    ///   - toOffset: Destination index
    func moveTasks(fromOffsets: IndexSet, toOffset: Int) {
        // Create a mutable copy of the tasks array
        var updatedTasks = tasks
        
        // Perform the move
        updatedTasks.move(fromOffsets: fromOffsets, toOffset: toOffset)
        
        // Update the display order
        updateTaskDisplayOrder(for: updatedTasks, save: true)
        
        // Get the project if available
        let project = updatedTasks.first?.project
        
        // If we're in a project view, update the project's lastModifiedDate
        if let project = project {
            project.setValue(Date(), forKey: "lastModifiedDate")
        }
        
        // Refresh the UI
        refreshFetch()
    }
}
