//
//  EnhancedTaskViewModel.swift
//  todo-app
//
//  Created on 3/13/25.
//

import Foundation
import CoreData
import Combine
import SwiftUI

/// Enhanced ViewModel for Tasks using NSFetchedResultsController for improved list management
class EnhancedTaskViewModel: ObservableObject {
    // MARK: - Properties
    
    /// The managed object context
    private let viewContext: NSManagedObjectContext
    
    /// The fetched results controller for tasks
    private var fetchedResultsController: TaskFetchedResultsController?
    
    /// Publisher for task updates
    @Published private(set) var tasks: [Item] = []
    
    /// Tasks grouped by section (if using sections)
    @Published private(set) var tasksBySection: [[Item]] = []
    @Published private(set) var sectionTitles: [String] = []
    
    /// Current view configuration
    private var currentViewType: ViewType?
    private var currentProject: Project?
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // MARK: - Fetch Configuration
    
    /// Configures the fetch controller for a specific view type
    /// - Parameters:
    ///   - viewType: The view type to display tasks for
    ///   - project: Optional project for project view
    ///   - groupByProject: Whether to group tasks by project
    func configureFetch(for viewType: ViewType, project: Project? = nil, groupByProject: Bool = false) {
        // Store current configuration
        self.currentViewType = viewType
        self.currentProject = project
        
        // Create the fetched results controller
        fetchedResultsController = TaskFetchedResultsController(
            viewType: viewType,
            selectedProject: project,
            context: viewContext,
            groupByProject: groupByProject
        )
        
        // Subscribe to updates from the fetched results controller
        fetchedResultsController?.tasksPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedTasks in
                self?.tasks = updatedTasks
                
                if groupByProject, let controller = self?.fetchedResultsController {
                    self?.tasksBySection = (0..<controller.numberOfSections).map { section in
                        controller.objectsInSection(section)
                    }
                    
                    self?.sectionTitles = (0..<controller.numberOfSections).map { section in
                        controller.titleForSection(section)
                    }
                } else {
                    // No sections, just use all tasks as a single section
                    if !updatedTasks.isEmpty {
                        self?.tasksBySection = [updatedTasks]
                        self?.sectionTitles = ["All Tasks"]
                    } else {
                        self?.tasksBySection = []
                        self?.sectionTitles = []
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Refreshes the current fetch to update data
    func refreshFetch() {
        fetchedResultsController?.refreshFetch()
    }
    
    // MARK: - Calendar View Operations
    
    /// Configures an optimized fetch for calendar month view
    /// - Parameters:
    ///   - startDate: Start date of the month
    ///   - endDate: End date of the month
    func configureCalendarMonthFetch(from startDate: Date, to endDate: Date) {
        let request = TaskFetchRequestFactory.calendarMonthTasks(from: startDate, to: endDate, in: viewContext)
        
        // Create a fetched results controller with no sections
        fetchedResultsController = TaskFetchedResultsController(
            fetchRequest: request,
            context: viewContext
        )
        
        // Subscribe to updates
        fetchedResultsController?.tasksPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedTasks in
                self?.tasks = updatedTasks
                self?.tasksBySection = [updatedTasks]
                self?.sectionTitles = ["Calendar Tasks"]
            }
            .store(in: &cancellables)
    }
    
    /// Configures an optimized fetch for calendar week view
    /// - Parameters:
    ///   - startDate: Start date of the week
    ///   - endDate: End date of the week
    func configureCalendarWeekFetch(from startDate: Date, to endDate: Date) {
        let request = TaskFetchRequestFactory.calendarWeekTasks(from: startDate, to: endDate, in: viewContext)
        
        // Create a fetched results controller with no sections
        fetchedResultsController = TaskFetchedResultsController(
            fetchRequest: request,
            context: viewContext
        )
        
        // Subscribe to updates
        fetchedResultsController?.tasksPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedTasks in
                self?.tasks = updatedTasks
                self?.tasksBySection = [updatedTasks]
                self?.sectionTitles = ["Week Tasks"]
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Task Operations
    
    /// Adds a new task
    /// - Parameters:
    ///   - title: The task title
    ///   - dueDate: Optional due date
    ///   - priority: Task priority
    ///   - project: Project the task belongs to
    ///   - notes: Optional notes
    func addTask(title: String, dueDate: Date? = nil, priority: Int16 = 0, project: Project? = nil, notes: String? = nil) {
        let newItem = Item(context: viewContext)
        newItem.id = UUID()
        newItem.title = title
        newItem.createdDate = Date()
        newItem.dueDate = dueDate
        newItem.priority = priority
        newItem.completed = false
        newItem.project = project
        newItem.notes = notes
        
        saveContext()
    }
    
    /// Updates an existing task
    /// - Parameters:
    ///   - task: The task to update
    ///   - title: Optional new title
    ///   - dueDate: Optional new due date
    ///   - priority: Optional new priority
    ///   - completed: Optional completion status
    ///   - completionDate: Optional new completion date
    ///   - project: Optional new project
    ///   - notes: Optional new notes
    ///   - logged: Optional new logged status
    func updateTask(_ task: Item, title: String? = nil, dueDate: Date? = nil, priority: Int16? = nil, completed: Bool? = nil, completionDate: Date? = nil, project: Project? = nil, notes: String? = nil, logged: Bool? = nil) {
        if let title = title {
            task.title = title
        }
        if let dueDate = dueDate {
            task.dueDate = dueDate
        }
        if let priority = priority {
            task.priority = priority
        }
        if let completed = completed {
            let wasCompleted = task.completed
            task.completed = completed
            
            // Set completion date if newly completed
            if !wasCompleted && completed {
                task.completionDate = Date()
            }
            // Clear completion date if uncompleted
            else if wasCompleted && !completed {
                task.completionDate = nil
            }
        }
        
        if let completionDate = completionDate {
            task.completionDate = completionDate
        }
        if let project = project {
            task.project = project
        }
        if let notes = notes {
            task.notes = notes
        }
        if let logged = logged {
            task.logged = logged
        }
        
        saveContext()
    }
    
    /// Toggles a task's completion status
    /// - Parameter task: The task to toggle
    func toggleTaskCompletion(_ task: Item) {
        task.toggleCompletion(save: true)
    }
    
    /// Marks a task as logged
    /// - Parameter task: The task to mark as logged
    func markTaskAsLogged(_ task: Item) {
        task.markAsLogged(save: true)
    }
    
    /// Deletes a task
    /// - Parameter task: The task to delete
    func deleteTask(_ task: Item) {
        viewContext.delete(task)
        saveContext()
    }
    
    // MARK: - Context Operations
    
    /// Saves the managed object context
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error saving context: \(nsError), \(nsError.userInfo)")
        }
    }
    
    // MARK: - Section Helpers
    
    /// Gets the title for a specific section
    /// - Parameter section: The section index
    /// - Returns: The section title
    func titleForSection(_ section: Int) -> String {
        guard section < sectionTitles.count else { return "Unknown" }
        return sectionTitles[section]
    }
    
    /// Gets tasks for a specific section
    /// - Parameter section: The section index
    /// - Returns: Array of tasks in the section
    func tasksForSection(_ section: Int) -> [Item] {
        guard section < tasksBySection.count else { return [] }
        return tasksBySection[section]
    }
    
    /// Gets the number of sections
    var numberOfSections: Int {
        return tasksBySection.count
    }
    
    /// Gets the number of tasks in a section
    /// - Parameter section: The section index
    /// - Returns: Count of tasks in the section
    func numberOfTasksInSection(_ section: Int) -> Int {
        guard section < tasksBySection.count else { return 0 }
        return tasksBySection[section].count
    }
    
    /// Moves items within a section to support drag and drop reordering
    /// - Parameters:
    ///   - section: The section containing the items
    ///   - source: The source indices
    ///   - destination: The destination index
    func moveItems(in section: Int, from source: IndexSet, to destination: Int) {
        // Make sure we have a valid section
        guard section < tasksBySection.count else { return }
        
        // Get a mutable copy of the section's tasks
        var sectionTasks = tasksBySection[section]
        
        // Perform the move operation on our local copy
        sectionTasks.move(fromOffsets: source, toOffset: destination)
        
        // Store the new ordering in UserDefaults since we don't have an 'order' property
        // This is a temporary solution until we can update the Core Data model
        var orderDict = UserDefaults.standard.dictionary(forKey: "TaskOrdering") as? [String: Int] ?? [:]
        
        // Update the ordering for each task
        for (index, task) in sectionTasks.enumerated() {
            if let taskId = task.id?.uuidString {
                orderDict[taskId] = index
            }
        }
        
        // Save the ordering
        UserDefaults.standard.set(orderDict, forKey: "TaskOrdering")
        
        // Save the context for any other changes
        do {
            try viewContext.save()
            
            // Refresh the fetch to update the UI
            self.refreshFetch()
        } catch {
            print("Failed to save context after reordering: \(error)")
        }
    }
}
