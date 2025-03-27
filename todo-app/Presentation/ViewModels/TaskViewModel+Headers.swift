//
//  TaskViewModel+Headers.swift
//  todo-app
//
//  Created on 3/26/25.
//

import Foundation
import CoreData

// Extension to add ProjectHeader operations to TaskViewModel
extension TaskViewModel {
    
    // MARK: - ProjectHeader Methods
    
    /// Adds a new header to a project
    /// - Parameters:
    ///   - title: The header title
    ///   - project: The project to add the header to
    /// - Returns: The newly created header
    @discardableResult
    func addHeader(title: String, project: Project) -> ProjectHeader {
        let header = ProjectHeader.create(in: viewContext, title: title, project: project)
        saveContext()
        return header
    }
    
    /// Updates a header's properties
    /// - Parameters:
    ///   - header: The header to update
    ///   - title: New title for the header
    func updateHeader(_ header: ProjectHeader, title: String) {
        header.title = title
        saveContext()
    }
    
    /// Deletes a header and moves its tasks to unheadered status
    /// - Parameter header: The header to delete
    func deleteHeader(_ header: ProjectHeader) {
        // First move all tasks in this header to no header
        if let project = header.project {
            let tasks = Array(header.tasks())
            project.moveTasks(tasks, toHeader: nil, save: false)
        }
        
        // Then delete the header
        viewContext.delete(header)
        saveContext()
    }
    
    /// Reorders headers within a project
    /// - Parameters:
    ///   - from: Source index
    ///   - to: Destination index
    ///   - headers: Array of headers to reorder
    func reorderHeaders(from: Int, to: Int, headers: [ProjectHeader]) {
        ProjectHeader.reorderHeaders(from: from, to: to, headers: headers, context: viewContext)
    }
    
    /// Moves a task to a header
    /// - Parameters:
    ///   - task: The task to move
    ///   - header: The destination header (nil to remove from any header)
    func moveTaskToHeader(_ task: Item, header: ProjectHeader?) {
        task.moveToHeader(header)
    }
    
    /// Gets all headers for a project in display order
    /// - Parameter project: The project to get headers for
    /// - Returns: Array of headers in display order
    func getHeadersForProject(_ project: Project) -> [ProjectHeader] {
        return project.orderedHeaders()
    }
    
    /// Gets tasks for a specific header
    /// - Parameter header: The header to get tasks for
    /// - Returns: Array of tasks in display order
    func getTasksForHeader(_ header: ProjectHeader) -> [Item] {
        return header.tasks()
    }
    
    /// Gets tasks that don't belong to any header in a project
    /// - Parameter project: The project to get unheadered tasks for
    /// - Returns: Array of tasks in display order
    func getUnheaderedTasks(_ project: Project) -> [Item] {
        return project.tasksWithoutHeader()
    }
}
