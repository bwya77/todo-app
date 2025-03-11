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
    
    func updateTask(_ task: Item, title: String? = nil, dueDate: Date? = nil, priority: Int16? = nil, completed: Bool? = nil, project: Project? = nil, notes: String? = nil) {
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
            task.completed = completed
        }
        if let project = project {
            task.project = project
        }
        if let notes = notes {
            task.notes = notes
        }
        
        saveContext()
    }
    
    func toggleTaskCompletion(_ task: Item) {
        task.completed.toggle()
        saveContext()
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
    
    func addProject(name: String, color: String = "gray") {
        let newProject = Project(context: viewContext)
        newProject.id = UUID()
        newProject.name = name
        newProject.color = color
        
        saveContext()
    }
    
    func updateProject(_ project: Project, name: String? = nil, color: String? = nil) {
        if let name = name {
            project.name = name
        }
        if let color = color {
            project.color = color
        }
        
        saveContext()
    }
    
    func deleteProject(_ project: Project) {
        viewContext.delete(project)
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
        
        // Convert to Double before division to ensure proper decimal calculation
        let completedCount = getProjectCompletedTaskCount(project: project)
        
        // Debug logging for troubleshooting
        print("Project completion: \(completedCount)/\(totalCount) = \(Double(completedCount) / Double(totalCount))")
        
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
}
