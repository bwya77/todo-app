//
//  Area+CoreDataExtensions.swift
//  todo-app
//
//  Created on 3/22/25.
//

import Foundation
import CoreData
import SwiftUI

extension Area {
    /// The computed property for project count
    var projectCount: Int {
        return (projects?.count ?? 0)
    }
    
    /// The computed property for active projects (not completed)
    var activeProjectCount: Int {
        guard let projects = projects as? Set<Project> else { return 0 }
        return projects.reduce(0) { count, project in
            // Check if the project has non-completed tasks
            let taskCount = project.items?.count ?? 0
            let completedCount = (project.items as? Set<Item>)?.filter { $0.completed }.count ?? 0
            let activeTasks = taskCount - completedCount
            return count + (activeTasks > 0 ? 1 : 0)
        }
    }
    
    /// The computed property for total task count across all projects
    var totalTaskCount: Int {
        guard let projects = projects as? Set<Project> else { return 0 }
        return projects.reduce(0) { count, project in
            let taskCount = project.items?.count ?? 0
            let completedCount = (project.items as? Set<Item>)?.filter { $0.completed }.count ?? 0
            let activeTasks = taskCount - completedCount
            return count + activeTasks
        }
    }
    
    /// Create a new Area with the given details
    /// - Parameters:
    ///   - name: The name of the area
    ///   - color: The color of the area
    ///   - context: The managed object context
    /// - Returns: The newly created area
    static func create(name: String, color: String, in context: NSManagedObjectContext) -> Area {
        let area = Area(context: context)
        area.id = UUID()
        area.name = name
        area.color = color
        area.displayOrder = Area.getNextDisplayOrder(in: context)
        return area
    }
    
    /// Get the next display order for a new area
    /// - Parameter context: The managed object context
    /// - Returns: The next display order value
    static func getNextDisplayOrder(in context: NSManagedObjectContext) -> Int32 {
        let fetchRequest: NSFetchRequest<Area> = Area.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Area.displayOrder, ascending: false)]
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
