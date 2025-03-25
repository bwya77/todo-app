//
//  TaskViewModel.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//  Refactored according to improvement plan on 3/7/25.
//  Updated on 3/9/25 to add date-specific task queries.
//

import SwiftUI
import CoreData

class TaskViewModel: ObservableObject {
    // Making viewContext internal so that components can use it
    var viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
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
    
    func toggleTaskCompletion(_ task: Item) {
        let wasCompleted = task.completed
        task.completed.toggle()
        
        // If task is newly completed, set the completion date but don't set logged flag yet
        if !wasCompleted && task.completed {
            task.completionDate = Date()
            task.logged = false // Ensure it's not logged initially
        }
        // If task was completed and is now uncompleted, reset logged flag and completion date
        else if wasCompleted {
            task.logged = false
            task.completionDate = nil
        }
        
        saveContext()
    }
    
    func markTaskAsLogged(_ task: Item) {
        task.logged = true
        saveContext()
    }
    
    func setLoggedStateForAllCompletedTasks(project: Project, logged: Bool) {
        // Get all completed tasks for this project
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "completed == YES AND project == %@", project)
        
        do {
            let tasks = try viewContext.fetch(fetchRequest)
            for task in tasks {
                task.logged = logged
            }
            saveContext()
        } catch {
            print("Error setting logged state for completed tasks: \(error)")
        }
    }
    
    func deleteTask(_ task: Item) {
        viewContext.delete(task)
        saveContext()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error saving context: \(nsError), \(nsError.userInfo)")
        }
    }
    
    // MARK: - Projects
    
    func addProject(name: String, color: String = "gray", area: Area? = nil) {
        let newProject = Project(context: viewContext)
        newProject.id = UUID()
        newProject.name = name
        newProject.color = color
        newProject.displayOrder = Project.getNextDisplayOrder(in: viewContext)
        newProject.area = area
        
        saveContext()
    }
    
    /// Adds a new area
    /// - Parameters:
    ///   - name: Area name
    ///   - color: Area color
    func addArea(name: String, color: String = "green") {
        let area = Area(context: viewContext)
        area.id = UUID()
        area.name = name
        area.color = color
        area.displayOrder = Area.getNextDisplayOrder(in: viewContext)
        
        saveContext()
    }
    
    func updateProject(_ project: Project, name: String? = nil, color: String? = nil, notes: String? = nil) {
        if let name = name {
            project.name = name
        }
        if let color = color {
            project.color = color
        }
        if let notes = notes {
            project.notes = notes
        }
        
        saveContext()
    }
    
    /// Updates an area's properties
    /// - Parameters:
    ///   - area: The area to update
    ///   - name: New name for the area (optional)
    ///   - color: New color for the area (optional)
    func updateArea(_ area: Area, name: String? = nil, color: String? = nil) {
        if let name = name {
            area.name = name
        }
        if let color = color {
            area.color = color
        }
        
        saveContext()
    }
    
    func deleteProject(_ project: Project) {
        viewContext.delete(project)
        saveContext()
    }
    
    /// Deletes an area
    /// - Parameter area: The area to delete
    func deleteArea(_ area: Area) {
        viewContext.delete(area)
        saveContext()
    }
    
    // MARK: - Tags
    
    func addTag(name: String, color: String = "gray") {
        let newTag = Tag(context: viewContext)
        newTag.id = UUID()
        newTag.name = name
        newTag.color = color
        
        saveContext()
    }
    
    func updateTag(_ tag: Tag, name: String? = nil, color: String? = nil) {
        if let name = name {
            tag.name = name
        }
        if let color = color {
            tag.color = color
        }
        
        saveContext()
    }
    
    func deleteTag(_ tag: Tag) {
        viewContext.delete(tag)
        saveContext()
    }
    
    func addTagToTask(_ tag: Tag, task: Item) {
        let tagSet = task.tags?.mutableCopy() as? NSMutableSet ?? NSMutableSet()
        tagSet.add(tag)
        task.tags = tagSet
        saveContext()
    }
    
    func removeTagFromTask(_ tag: Tag, task: Item) {
        if let tagSet = task.tags?.mutableCopy() as? NSMutableSet {
            tagSet.remove(tag)
            task.tags = tagSet
            saveContext()
        }
    }
    
    // MARK: - Tasks for a specific date
    
    func getTasksForDate(_ date: Date) -> [Item] {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        // Create a calendar that matches the user's locale
        let calendar = Calendar.current
        
        // Get the start and end of the day
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Set up the predicate to get tasks for this date
        let datePredicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@", startOfDay as NSDate, endOfDay as NSDate)
        let allDayPredicate = NSPredicate(format: "isAllDay == YES AND dueDate >= %@ AND dueDate < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        // Combine predicates with OR
        fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [datePredicate, allDayPredicate])
        
        // Sort tasks by time
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching tasks for date: \(error)")
            return []
        }
    }
    
    // MARK: - Task Counts
    
    func getInboxTaskCount() -> Int {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "completed == NO AND project == nil")
        
        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            print("Error fetching inbox task count: \(error)")
            return 0
        }
    }
    
    func getTodayTaskCount() -> Int {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        fetchRequest.predicate = NSPredicate(format: "completed == NO AND dueDate >= %@ AND dueDate < %@", today as NSDate, tomorrow as NSDate)
        
        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            print("Error fetching today task count: \(error)")
            return 0
        }
    }
    
    func getUpcomingTaskCount() -> Int {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        let today = Calendar.current.startOfDay(for: Date())
        
        fetchRequest.predicate = NSPredicate(format: "completed == NO AND dueDate >= %@", today as NSDate)
        
        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            print("Error fetching upcoming task count: \(error)")
            return 0
        }
    }
    
    func getCompletedTaskCount() -> Int {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "completed == YES")
        
        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            print("Error fetching completed task count: \(error)")
            return 0
        }
    }
    
    // Get the count of incomplete tasks for a project (these are the tasks we want to show in the sidebar count)
func getProjectTaskCount(project: Project) -> Int {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "completed == NO AND project == %@", project)
        
        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            print("Error fetching project task count: \(error)")
            return 0
        }
    }
    
    func getProjectTotalTaskCount(project: Project) -> Int {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project == %@", project)
        
        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            print("Error fetching project total task count: \(error)")
            return 0
        }
    }
    
    func getProjectCompletedTaskCount(project: Project) -> Int {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "completed == YES AND project == %@", project)
        
        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            print("Error fetching project completed task count: \(error)")
            return 0
        }
    }
    
    func getProjectCompletionPercentage(project: Project) -> Double {
        let totalCount = getProjectTotalTaskCount(project: project)
        if totalCount == 0 {
            return 0.0
        }
        
        let completedCount = getProjectCompletedTaskCount(project: project)
        return Double(completedCount) / Double(totalCount)
    }
    
    func getFilteredTaskCount() -> Int {
        // This is a placeholder for the Filters & Labels count
        // In a real implementation, this would count tasks with tags/filters
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "completed == NO AND tags.@count > 0")
        
        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            print("Error fetching filtered task count: \(error)")
            return 0
        }
    }
    
    // MARK: - Area Tasks
    
    /// Gets the total count of active tasks in an area (across all projects)
    /// - Parameter area: The area to count tasks for
    /// - Returns: The count of active tasks
    func getAreaTaskCount(area: Area) -> Int {
        // Get all projects in this area
        guard let projects = area.projects as? Set<Project> else { return 0 }
        
        // Sum up the active task counts for each project
        return projects.reduce(0) { count, project in
            return count + getProjectTaskCount(project: project)
        }
    }
    
    /// Gets the count of projects in an area
    /// - Parameter area: The area to count projects for
    /// - Returns: The count of projects
    func getAreaProjectCount(area: Area) -> Int {
        return area.projects?.count ?? 0
    }
}
