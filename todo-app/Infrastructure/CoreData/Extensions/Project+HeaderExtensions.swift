//
//  Project+HeaderExtensions.swift
//  todo-app
//
//  Created on 3/26/25.
//

import Foundation
import CoreData

extension Project {
    /// Get all headers for this project in display order
    /// - Returns: Array of headers in order
    func orderedHeaders() -> [ProjectHeader] {
        guard let headers = headers as? Set<ProjectHeader> else { return [] }
        return headers.sorted { $0.displayOrder < $1.displayOrder }
    }
    
    /// Get all tasks that are not associated with any header
    /// - Returns: Array of tasks not under any header in display order
    func tasksWithoutHeader() -> [Item] {
        guard let items = items as? Set<Item> else { return [] }
        return items
            .filter { !$0.completed && !$0.logged && $0.header == nil }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    /// Calculate the next display order value for a new header
    /// - Returns: The next display order value
    func nextHeaderDisplayOrder() -> Int32 {
        let existingHeaders = orderedHeaders()
        if existingHeaders.isEmpty {
            return 0
        } else {
            // Find the maximum display order value and add 10
            return existingHeaders.map { $0.displayOrder }.max()! + 10
        }
    }
    
    /// Add a new header to this project
    /// - Parameters:
    ///   - title: The title of the header
    ///   - save: Whether to save the context after adding
    /// - Returns: The newly created header
    @discardableResult
    func addHeader(title: String, save: Bool = true) -> ProjectHeader {
        guard let context = managedObjectContext else {
            fatalError("Attempted to add header to project without a valid context")
        }
        
        let header = ProjectHeader.create(in: context, title: title, project: self)
        
        if save {
            do {
                try context.save()
            } catch {
                print("Error saving after adding header to project: \(error)")
            }
        }
        
        return header
    }
    
    /// Move tasks to a header
    /// - Parameters:
    ///   - tasks: Array of tasks to move
    ///   - header: The header to move tasks to
    ///   - save: Whether to save the context after moving
    func moveTasks(_ tasks: [Item], toHeader header: ProjectHeader?, save: Bool = true) {
        guard let context = managedObjectContext else { return }
        
        for task in tasks {
            task.header = header
            
            // Update display order to be at the end of the header's tasks
            if let header = header {
                let existingTasks = header.tasks()
                task.displayOrder = existingTasks.isEmpty ? 0 : (existingTasks.map { $0.displayOrder }.max() ?? 0) + 10
            }
        }
        
        if save {
            do {
                try context.save()
            } catch {
                print("Error saving after moving tasks to header: \(error)")
            }
        }
    }
}
