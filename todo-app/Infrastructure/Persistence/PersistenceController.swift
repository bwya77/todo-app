//
//  PersistenceController.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//  Refactored according to improvement plan on 3/7/25.
//

import CoreData
import SwiftUI

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create projects
        let inbox = Project(context: viewContext)
        inbox.id = UUID()
        inbox.name = "Inbox"
        inbox.color = "blue"
        
        let workProject = Project(context: viewContext)
        workProject.id = UUID()
        workProject.name = "Work"
        workProject.color = "red"
        
        let personalProject = Project(context: viewContext)
        personalProject.id = UUID()
        personalProject.name = "Personal"
        personalProject.color = "green"
        
        // Create tags
        let urgentTag = Tag(context: viewContext)
        urgentTag.id = UUID()
        urgentTag.name = "Urgent"
        urgentTag.color = "red"
        
        let homeTag = Tag(context: viewContext)
        homeTag.id = UUID()
        homeTag.name = "Home"
        homeTag.color = "purple"
        
        // Create sample tasks
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Task for today
        let task1 = Item(context: viewContext)
        task1.id = UUID()
        task1.title = "Respond to emails"
        task1.createdDate = currentDate
        task1.dueDate = currentDate
        task1.priority = 1
        task1.completed = false
        task1.project = workProject
        let tagsForTask1 = NSMutableSet()
        tagsForTask1.add(urgentTag)
        task1.tags = tagsForTask1
        
        // Task for tomorrow
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate) {
            let task2 = Item(context: viewContext)
            task2.id = UUID()
            task2.title = "Take trash out"
            task2.createdDate = currentDate
            task2.dueDate = tomorrow
            task2.priority = 2
            task2.completed = false
            task2.project = personalProject
            let tagsForTask2 = NSMutableSet()
            tagsForTask2.add(homeTag)
            task2.tags = tagsForTask2
        }
        
        // Task for next week
        if let nextWeek = calendar.date(byAdding: .day, value: 7, to: currentDate) {
            let task3 = Item(context: viewContext)
            task3.id = UUID()
            task3.title = "Create UI mockups"
            task3.createdDate = currentDate
            task3.dueDate = nextWeek
            task3.priority = 3
            task3.completed = false
            task3.project = workProject
        }
        
        // Add more sample tasks
        let task4 = Item(context: viewContext)
        task4.id = UUID()
        task4.title = "Edit the task list view"
        task4.createdDate = currentDate
        task4.dueDate = calendar.date(byAdding: .day, value: 3, to: currentDate)
        task4.priority = 2
        task4.completed = false
        task4.project = personalProject
        
        let task5 = Item(context: viewContext)
        task5.id = UUID()
        task5.title = "Bug bounty submission"
        task5.createdDate = currentDate
        task5.dueDate = calendar.date(byAdding: .day, value: 6, to: currentDate)
        task5.priority = 3
        task5.completed = false
        task5.project = workProject
        
        // March 17 tasks
        if let march17 = calendar.date(from: DateComponents(year: 2025, month: 3, day: 17)) {
            let task6 = Item(context: viewContext)
            task6.id = UUID()
            task6.title = "Add new GitHub repo"
            task6.createdDate = currentDate
            task6.dueDate = march17
            task6.priority = 2
            task6.completed = false
            task6.project = workProject
        }
        
        // March 31 tasks
        if let march31 = calendar.date(from: DateComponents(year: 2025, month: 3, day: 31)) {
            let task7 = Item(context: viewContext)
            task7.id = UUID()
            task7.title = "Contuit: Ship MVP"
            task7.createdDate = currentDate
            task7.dueDate = march31
            task7.priority = 1
            task7.completed = false
            task7.project = workProject
            
            let task8 = Item(context: viewContext)
            task8.id = UUID()
            task8.title = "Pay Mortgage"
            task8.createdDate = currentDate
            task8.dueDate = march31
            task8.priority = 1
            task8.completed = false
            task8.project = personalProject
            
            let task9 = Item(context: viewContext)
            task9.id = UUID()
            task9.title = "Weight Check"
            task9.createdDate = currentDate
            task9.dueDate = march31
            task9.priority = 3
            task9.completed = false
            task9.project = personalProject
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "todo_app")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// Extensions to help with relationships in CoreData
