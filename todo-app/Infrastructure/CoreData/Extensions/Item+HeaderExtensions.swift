//
//  Item+HeaderExtensions.swift
//  todo-app
//
//  Created on 3/26/25.
//

import Foundation
import CoreData

extension Item {
    /// Move this task to a header
    /// - Parameters:
    ///   - header: The header to move the task to (nil to remove from header)
    ///   - save: Whether to save the context after moving
    func moveToHeader(_ header: ProjectHeader?, save: Bool = true) {
        // Store the old header for comparison
        let oldHeader = self.header
        
        // Update the header relationship
        self.header = header
        
        // If moving to a different header, update displayOrder to be at the end
        if header != oldHeader {
            if let newHeader = header {
                // Calculate new order at end of header's tasks
                let headerTasks = newHeader.tasks()
                let newOrder = headerTasks.isEmpty ? 0 : (headerTasks.map { $0.displayOrder }.max() ?? 0) + 10
                self.displayOrder = newOrder
            } else if let project = self.project {
                // Calculate new order at end of unheadered tasks
                let unheaderedTasks = project.tasksWithoutHeader()
                let newOrder = unheaderedTasks.isEmpty ? 0 : (unheaderedTasks.map { $0.displayOrder }.max() ?? 0) + 10
                self.displayOrder = newOrder
            }
        }
        
        // Save changes if requested
        if save, let context = managedObjectContext {
            do {
                try context.save()
            } catch {
                print("Error saving after moving task to header: \(error)")
            }
        }
    }
}
