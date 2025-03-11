//
//  ProjectCompletionTracker.swift
//  todo-app
//
//  Created on 3/11/25.
//

import SwiftUI
import CoreData
import Combine

/// A dedicated class to track project completion state and ensure accurate calculations
class ProjectCompletionTracker: ObservableObject {
    @Published var completionPercentage: Double = 0.0
    
    private let viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    private var taskViewModel: TaskViewModel
    private var projectId: UUID?
    
    /// Create a tracker for a specific project
    /// - Parameter project: The project to track
    init(project: Project) {
        self.projectId = project.id
        self.viewContext = project.managedObjectContext ?? PersistenceController.shared.container.viewContext
        self.taskViewModel = TaskViewModel(context: viewContext)
        
        // Set up notification observer for context changes
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main) // Debounce to avoid multiple updates
            .sink { [weak self] _ in
                self?.updateCompletionPercentage()
            }
            .store(in: &cancellables)
        
        // Perform initial update
        updateCompletionPercentage()
    }
    
    /// Force a recalculation of the completion percentage
    func refresh() {
        updateCompletionPercentage()
    }
    
    /// Direct getter for updated percentage
    /// - Returns: The current completion percentage (0.0 to 1.0)
    func getCurrentPercentage() -> Double {
        updateCompletionPercentage()
        return completionPercentage
    }
    
    /// Stop tracking and release resources
    func cleanup() {
        cancellables.removeAll()
    }
    
    /// Update the project ID being tracked
    /// - Parameter projectId: The new project ID to track
    func updateProject(_ projectId: UUID?) {
        // Only update if the ID is different
        if self.projectId != projectId {
            self.projectId = projectId
            updateCompletionPercentage()
        }
    }
    
    /// Update the completion percentage directly from the database
    private func updateCompletionPercentage() {
        guard let projectId = projectId else { return }
        
        // Fetch the project first to make sure we have the latest version
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", projectId as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let project = results.first {
                // Get task counts directly using raw CoreData queries for best accuracy
                let totalCount = getTaskCount(for: project, onlyCompleted: nil)
                
                if totalCount == 0 {
                    // No tasks, set to 0.0
                    DispatchQueue.main.async {
                        self.completionPercentage = 0.0
                    }
                    return
                }
                
                let completedCount = getTaskCount(for: project, onlyCompleted: true)
                let newPercentage = Double(completedCount) / Double(totalCount)
                
                DispatchQueue.main.async {
                    self.completionPercentage = newPercentage
                }
            }
        } catch {
            print("Error fetching project: \(error)")
        }
    }
    
    /// Get accurate task count using direct Core Data query
    /// - Parameters:
    ///   - project: The project to get tasks for
    ///   - onlyCompleted: If provided, filters tasks by completion status
    /// - Returns: The number of tasks matching the criteria
    private func getTaskCount(for project: Project, onlyCompleted: Bool?) -> Int {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        // Build the predicate based on parameters
        var predicateFormat = "project == %@"
        var predicateArgs: [Any] = [project]
        
        if let onlyCompleted = onlyCompleted {
            predicateFormat += " AND completed == %@"
            predicateArgs.append(onlyCompleted as NSNumber)
        }
        
        fetchRequest.predicate = NSPredicate(format: predicateFormat, argumentArray: predicateArgs)
        
        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            print("Error counting tasks: \(error)")
            return 0
        }
    }
}
