//
//  TaskFetchedResultsController.swift
//  todo-app
//
//  Created on 3/13/25.
//

import Foundation
import CoreData
import Combine
import SwiftUI

/// A manager class that encapsulates NSFetchedResultsController for better task list management
class TaskFetchedResultsController: NSObject, NSFetchedResultsControllerDelegate {
    
    // MARK: - Properties
    
    /// The fetched results controller responsible for managing the results
    private let fetchedResultsController: NSFetchedResultsController<Item>
    
    /// Publisher that emits whenever the fetched results change
    private let tasksSubject = PassthroughSubject<[Item], Never>()
    
    /// Public tasks publisher that observers can subscribe to
    var tasksPublisher: AnyPublisher<[Item], Never> {
        return tasksSubject.eraseToAnyPublisher()
    }
    
    /// Current sections for grouped display
    private(set) var sections: [[Item]] = []
    private(set) var sectionTitles: [String] = []
    
    /// Computed property to access all fetched objects
    var fetchedObjects: [Item] {
        return fetchedResultsController.fetchedObjects ?? []
    }
    
    // MARK: - Initialization
    
    /// Initialize with a specific fetch request
    /// - Parameters:
    ///   - fetchRequest: The NSFetchRequest to use
    ///   - context: The managed object context
    ///   - sectionNameKeyPath: Optional keyPath for section grouping (e.g. "project.name")
    ///   - cacheName: Optional name for the cache
    init(fetchRequest: NSFetchRequest<Item>, 
         context: NSManagedObjectContext,
         sectionNameKeyPath: String? = nil,
         cacheName: String? = nil) {
        
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: cacheName
        )
        
        super.init()
        
        // Set delegate to receive updates
        self.fetchedResultsController.delegate = self
        
        // Perform initial fetch
        do {
            try self.fetchedResultsController.performFetch()
            self.updateSections()
            self.tasksSubject.send(self.fetchedObjects)
        } catch {
            print("Failed to fetch items: \(error)")
        }
    }
    
    /// Initialize with a view type (convenience method)
    /// - Parameters:
    ///   - viewType: The view type to fetch tasks for
    ///   - selectedProject: Optional selected project for project view
    ///   - context: The managed object context
    ///   - groupByProject: Whether to group results by project
    convenience init(viewType: ViewType, 
                    selectedProject: Project? = nil, 
                    context: NSManagedObjectContext,
                    groupByProject: Bool = false) {
        
        // Determine the appropriate fetch request factory method
        let fetchRequest: NSFetchRequest<Item>
        
        switch viewType {
        case .inbox:
            fetchRequest = TaskFetchRequestFactory.inboxTasks(in: context)
            
        case .today:
            fetchRequest = TaskFetchRequestFactory.todayTasks(in: context)
            
        case .upcoming:
            fetchRequest = TaskFetchRequestFactory.upcomingTasks(in: context)
            
        case .completed:
            fetchRequest = TaskFetchRequestFactory.completedTasks(in: context)
            
        case .project:
            if let project = selectedProject {
                fetchRequest = TaskFetchRequestFactory.tasksForProject(project, in: context)
                print("🔍 Creating fetch request for project: \(project.name ?? "Unknown")") 
            } else {
                fetchRequest = TaskFetchRequestFactory.allTasks(in: context)
            }
            
        case .filters:
            // Default to all tasks for now
            fetchRequest = TaskFetchRequestFactory.allTasks(in: context)
        }
        
        // Configure batch size for efficiency
        fetchRequest.fetchBatchSize = 20
        
        // Set a fixed sort descriptor for project view
        if viewType == .project && selectedProject != nil {
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "displayOrder", ascending: true)
            ]
            print("🔍 CRITICAL: Project view using absolute displayOrder sort")
        }
        
        // For reorderable tasks, always modify sort descriptors to prioritize display order
        // Keep section-based sorting if needed but add displayOrder as first sort
        var sortDescriptors = fetchRequest.sortDescriptors ?? []
        
        // Add displayOrder as primary sort only if it's not already there
        if !sortDescriptors.contains(where: { $0.key == "displayOrder" }) {
            sortDescriptors.insert(NSSortDescriptor(key: "displayOrder", ascending: true), at: 0)
            fetchRequest.sortDescriptors = sortDescriptors
            print("🔍 Set primary sort by displayOrder: \(String(describing: fetchRequest.sortDescriptors))")
        }
        
        // Initialize using the constructed fetch request
        self.init(
            fetchRequest: fetchRequest,
            context: context,
            sectionNameKeyPath: groupByProject ? "project.name" : nil,
            cacheName: nil
        )
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSections()
        tasksSubject.send(fetchedObjects)
    }
    
    // MARK: - Operations
    
    /// Refreshes the fetch request to get updated results
    func refreshFetch() {
        do {
            try fetchedResultsController.performFetch()
            updateSections()
            tasksSubject.send(fetchedObjects)
        } catch {
            print("Failed to refresh fetch: \(error)")
        }
    }
    
    /// Updates the sections and section titles based on the current fetch results
    private func updateSections() {
        let sections = fetchedResultsController.sections ?? []
        
        print("🧩 Updating sections: \(sections.count) sections found")
        
        self.sections = sections.map { section in
            // Get items in this section
            let items = section.objects?.compactMap { $0 as? Item } ?? []
            
            // Sort items by displayOrder within each section
            return items.sorted { $0.displayOrder < $1.displayOrder }
        }
        
        self.sectionTitles = sections.map { section in
            return section.name
        }
        
        // Log section information
        for (index, section) in self.sections.enumerated() {
            print("📂 Section \(index) (\(titleForSection(index))): \(section.count) items")
        }
    }
    
    /// Returns the title for a specific section
    /// - Parameter section: The section index
    /// - Returns: The title for the section
    func titleForSection(_ section: Int) -> String {
        guard section < sectionTitles.count else { return "Unknown" }
        
        // Handle nil project name
        if sectionTitles[section] == "" {
            return "No Project"
        }
        
        return sectionTitles[section]
    }
    
    /// Returns objects for a specific section
    /// - Parameter section: The section index
    /// - Returns: Array of items in the section
    func objectsInSection(_ section: Int) -> [Item] {
        guard section < sections.count else { return [] }
        return sections[section]
    }
    
    /// Returns the number of sections
    var numberOfSections: Int {
        return sections.count
    }
    
    /// Returns the number of objects in a specific section
    /// - Parameter section: The section index
    /// - Returns: The count of objects in the section
    func numberOfObjectsInSection(_ section: Int) -> Int {
        guard section < sections.count else { return 0 }
        return sections[section].count
    }
}
