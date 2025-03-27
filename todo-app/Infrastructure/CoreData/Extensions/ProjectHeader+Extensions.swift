//
//  ProjectHeader+Extensions.swift
//  todo-app
//
//  Created on 3/26/25.
//

import Foundation
import CoreData

extension ProjectHeader {
    /// The default sort order attribute name in the data model
    static let orderAttributeName = "displayOrder"
    
    /// Get all tasks associated with this header
    /// - Returns: Array of tasks in the correct order
    func tasks() -> [Item] {
        guard let items = self.value(forKey: "items") as? Set<Item> else { return [] }
        return items.sorted { $0.displayOrder < $1.displayOrder }
    }
    
    /// Reorders headers within a project
    /// - Parameters:
    ///   - from: The source index
    ///   - to: The destination index
    ///   - headers: The array of headers to reorder
    ///   - context: The managed object context to save changes in
    static func reorderHeaders(from: Int, to: Int, headers: [ProjectHeader], context: NSManagedObjectContext) {
        guard from != to, from >= 0, to >= 0, from < headers.count, to < headers.count else { return }
        
        print("🔄 Reordering project header from index \(from) to \(to)")
        
        // Get the header being moved
        let headerToMove = headers[from]
        
        // Create a mutable copy of the headers array
        var mutableHeaders = headers
        
        // Remove the header from its current position
        mutableHeaders.remove(at: from)
        
        // Insert the header at the new position
        mutableHeaders.insert(headerToMove, at: to)
        
        // Update the display order of all headers - use 10-spacing to allow for insertions
        for (index, header) in mutableHeaders.enumerated() {
            let newOrder = Int32(index * 10)
            print("  → Setting header '\(header.title ?? "Untitled")' display order: \(newOrder)")
            header.displayOrder = newOrder
        }
        
        // Save changes
        PersistentOrder.save(context: context)
        
        // Notify that header order has changed
        NotificationCenter.default.post(
            name: NSNotification.Name("HeaderOrderChanged"),
            object: nil
        )
        
        print("  ✅ Successfully saved header reordering")
    }
    
    /// Get all headers for a project in the correct display order
    /// - Parameters:
    ///   - project: The project to get headers for
    ///   - context: The managed object context
    /// - Returns: Array of headers in the correct order
    static func getOrderedHeaders(for project: Project, in context: NSManagedObjectContext) -> [ProjectHeader] {
        let fetchRequest: NSFetchRequest<ProjectHeader> = ProjectHeader.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "project == %@", project)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: orderAttributeName, ascending: true)
        ]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ Error fetching ordered headers: \(error)")
            return []
        }
    }
}
