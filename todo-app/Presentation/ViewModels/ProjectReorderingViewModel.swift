//
//  ProjectReorderingViewModel.swift
//  todo-app
//
//  Created on 3/20/25.
//

import Foundation
import SwiftUI
import CoreData
import Combine

/// ViewModel for handling project reordering in the UI
class ProjectReorderingViewModel: ObservableObject {
    /// The persistence controller for accessing Core Data
    private let persistence: PersistenceController
    
    /// The managed object context for data operations
    private let context: NSManagedObjectContext
    
    /// The currently active/dragged project
    @Published var activeProject: Project? = nil
    
    /// The projects in their current order
    @Published private(set) var projects: [Project] = []
    
    /// Private cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Initialize with a persistence controller
    /// - Parameter persistence: The persistence controller for Core Data access
    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        self.context = persistence.container.viewContext
        
        // Fetch initial projects
        fetchProjects()
        
        // Set up notification observers for data changes
        setupObservers()
    }
    
    /// Set up notification observers to refresh data when context changes
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.fetchProjects()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("ForceUIRefresh"))
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.fetchProjects()
            }
            .store(in: &cancellables)
    }
    
    /// Fetch projects from Core Data, ordered by displayOrder or name
    func fetchProjects() {
        // Use a safer fetch method that handles missing displayOrder
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        
        // Check if displayOrder exists on the entity
        let entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName["Project"]
        let hasDisplayOrder = entity?.propertiesByName["displayOrder"] != nil
        
        print("🔍 ProjectReorderingViewModel - Checking displayOrder attribute: \(hasDisplayOrder ? "exists" : "missing")")
        
        if hasDisplayOrder {
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "displayOrder", ascending: true)
            ]
        } else {
            // Fallback to sorting by name if displayOrder doesn't exist
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \Project.name, ascending: true)
            ]
            
            // Try to add the displayOrder attribute dynamically
            DisplayOrderManager.ensureDisplayOrderExists()
        }
        
        do {
            self.projects = try context.fetch(fetchRequest)
            print("📊 ProjectReorderingViewModel - Fetched \(self.projects.count) projects")
            
            // Debug log of projects
            for (index, project) in self.projects.enumerated() {
                let displayOrder = hasDisplayOrder ? (project.value(forKey: "displayOrder") as? Int32 ?? -1) : -1
                print("  Project \(index): \(project.name ?? "unnamed") (id: \(project.id?.uuidString ?? "no-id")) [displayOrder: \(displayOrder)]")
            }
        } catch {
            print("❌ Error fetching projects: \(error)")
            self.projects = []
        }
    }
    
    /// Reorder projects by moving from one index set to another index
    /// - Parameters:
    ///   - fromOffsets: The source indices
    ///   - toOffset: The destination index
    func reorderProjects(fromOffsets: IndexSet, toOffset: Int) {
        guard let fromIndex = fromOffsets.first else { return }
        
        Project.reorderProjects(
            from: fromIndex,
            to: toOffset,
            projects: projects,
            context: context
        )
        
        // Refresh projects after reordering
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.fetchProjects()
        }
    }
    
    /// Save the current project order
    /// - Returns: Whether the save was successful
    @discardableResult
    func saveCurrentProjectOrder() -> Bool {
        guard !projects.isEmpty else { return false }
        
        // Update display order values with spacing
        for (index, project) in projects.enumerated() {
            project.updateDisplayOrder(Int32(index * 10), save: false)
        }
        
        // Save the changes
        do {
            try context.save()
            return true
        } catch {
            print("Error saving project order: \(error)")
            return false
        }
    }
    
    /// Reset project order to alphabetical
    func resetProjectOrderToAlphabetical() {
        let sortedProjects = projects.sorted { ($0.name ?? "") < ($1.name ?? "") }
        
        // Update display order values
        for (index, project) in sortedProjects.enumerated() {
            project.updateDisplayOrder(Int32(index * 10), save: false)
        }
        
        // Save the changes
        do {
            try context.save()
            
            // Force UI refresh
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.fetchProjects()
            }
        } catch {
            print("Error resetting project order: \(error)")
        }
    }
}
