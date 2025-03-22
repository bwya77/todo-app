//
//  Project+NextDisplayOrder.swift
//  todo-app
//
//  Created on 3/22/25.
//

import Foundation
import CoreData

extension Project {
    /// Get the next display order for a new project
    /// - Parameter context: The managed object context
    /// - Returns: The next display order value
    static func getNextDisplayOrder(in context: NSManagedObjectContext) -> Int32 {
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Project.displayOrder, ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            if let highestOrder = results.first?.displayOrder {
                return highestOrder + 1
            }
        } catch {
            print("Error fetching highest display order: \(error.localizedDescription)")
        }
        
        return 0
    }
}
