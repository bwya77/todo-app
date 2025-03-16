//
//  TaskReorderingTests.swift
//  todo-appTests
//
//  Created on 3/15/25.
//

import XCTest
import CoreData
@testable import todo_app

class TaskReorderingTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        viewContext = nil
        persistenceController = nil
    }
    
    func testSetDisplayOrder() throws {
        // Create test task
        let task = Item.create(in: viewContext, title: "Test Task")
        try viewContext.save()
        
        // Set initial display order
        let initialOrder: Int32 = 5000
        task.setDisplayOrder(initialOrder)
        
        // Verify display order was set
        XCTAssertEqual(task.displayOrder, initialOrder)
    }
    
    func testReorderItems() throws {
        // Create test tasks
        let task1 = Item.create(in: viewContext, title: "Task 1")
        let task2 = Item.create(in: viewContext, title: "Task 2")
        let task3 = Item.create(in: viewContext, title: "Task 3")
        
        try viewContext.save()
        
        // Reorder tasks
        Item.reorderItems([task1, task2, task3])
        
        // Verify order
        XCTAssertLessThan(task1.displayOrder, task2.displayOrder)
        XCTAssertLessThan(task2.displayOrder, task3.displayOrder)
        
        // Change order and verify again
        Item.reorderItems([task3, task1, task2])
        
        XCTAssertLessThan(task3.displayOrder, task1.displayOrder)
        XCTAssertLessThan(task1.displayOrder, task2.displayOrder)
    }
    
    func testMoveBeforeItem() throws {
        // Create test tasks
        let task1 = Item.create(in: viewContext, title: "Task 1")
        let task2 = Item.create(in: viewContext, title: "Task 2")
        let task3 = Item.create(in: viewContext, title: "Task 3")
        
        // Set initial display orders
        task1.displayOrder = 0
        task2.displayOrder = 1000
        task3.displayOrder = 2000
        try viewContext.save()
        
        // Move task3 before task1
        task3.moveBeforeItem(task1)
        
        // Verify new order (order should now be: task3, task1, task2)
        let allTasks = try viewContext.fetch(Item.fetchRequest())
            .sorted { $0.displayOrder < $1.displayOrder }
        
        XCTAssertEqual(allTasks[0].title, "Task 3")
        XCTAssertEqual(allTasks[1].title, "Task 1")
        XCTAssertEqual(allTasks[2].title, "Task 2")
    }
    
    func testFetchWithDisplayOrder() throws {
        // Create test tasks with deliberate unordered creation
        let task2 = Item.create(in: viewContext, title: "Task 2")
        let task1 = Item.create(in: viewContext, title: "Task 1")
        let task3 = Item.create(in: viewContext, title: "Task 3")
        
        // Set display orders different from creation order
        task1.displayOrder = 0     // First
        task3.displayOrder = 1000  // Second
        task2.displayOrder = 2000  // Third
        try viewContext.save()
        
        // Create fetch request with display order sorting
        let request = TaskFetchRequestFactory.allTasks(in: viewContext)
        
        // Perform fetch
        let fetchedTasks = try viewContext.fetch(request)
        
        // Verify fetch order matches display order
        XCTAssertEqual(fetchedTasks[0].title, "Task 1")
        XCTAssertEqual(fetchedTasks[1].title, "Task 3")
        XCTAssertEqual(fetchedTasks[2].title, "Task 2")
    }
    
    func testProjectSpecificOrdering() throws {
        // Create two projects
        let project1 = Project(context: viewContext)
        project1.id = UUID()
        project1.name = "Project 1"
        
        let project2 = Project(context: viewContext)
        project2.id = UUID()
        project2.name = "Project 2"
        
        try viewContext.save()
        
        // Create tasks in different projects
        let task1 = Item.create(in: viewContext, title: "Task 1", project: project1)
        let task2 = Item.create(in: viewContext, title: "Task 2", project: project1)
        let task3 = Item.create(in: viewContext, title: "Task 3", project: project2)
        let task4 = Item.create(in: viewContext, title: "Task 4", project: project2)
        
        // Set custom display orders
        task1.displayOrder = 1000
        task2.displayOrder = 2000
        task3.displayOrder = 1000
        task4.displayOrder = 2000
        
        try viewContext.save()
        
        // Verify tasks are ordered correctly within their respective projects
        let project1Request = TaskFetchRequestFactory.tasksForProject(project1, in: viewContext)
        let project2Request = TaskFetchRequestFactory.tasksForProject(project2, in: viewContext)
        
        let project1Tasks = try viewContext.fetch(project1Request)
        let project2Tasks = try viewContext.fetch(project2Request)
        
        // Verify project 1 tasks
        XCTAssertEqual(project1Tasks.count, 2)
        XCTAssertEqual(project1Tasks[0].title, "Task 1")
        XCTAssertEqual(project1Tasks[1].title, "Task 2")
        
        // Verify project 2 tasks
        XCTAssertEqual(project2Tasks.count, 2)
        XCTAssertEqual(project2Tasks[0].title, "Task 3")
        XCTAssertEqual(project2Tasks[1].title, "Task 4")
        
        // Now reorder within a project
        task2.moveBeforeItem(task1)
        
        // Verify the new order in project 1
        let updatedProject1Tasks = try viewContext.fetch(project1Request)
        XCTAssertEqual(updatedProject1Tasks[0].title, "Task 2")
        XCTAssertEqual(updatedProject1Tasks[1].title, "Task 1")
        
        // Ensure project 2 order didn't change
        let updatedProject2Tasks = try viewContext.fetch(project2Request)
        XCTAssertEqual(updatedProject2Tasks[0].title, "Task 3")
        XCTAssertEqual(updatedProject2Tasks[1].title, "Task 4")
    }
    
    func testInboxTasksOrdering() throws {
        // Create inbox tasks (no project)
        let task1 = Item.create(in: viewContext, title: "Inbox Task 1")
        let task2 = Item.create(in: viewContext, title: "Inbox Task 2")
        let task3 = Item.create(in: viewContext, title: "Inbox Task 3")
        
        // Set display orders
        task1.displayOrder = 1000
        task2.displayOrder = 2000
        task3.displayOrder = 3000
        
        try viewContext.save()
        
        // Verify initial order
        let inboxRequest = TaskFetchRequestFactory.inboxTasks(in: viewContext)
        let inboxTasks = try viewContext.fetch(inboxRequest)
        
        XCTAssertEqual(inboxTasks.count, 3)
        XCTAssertEqual(inboxTasks[0].title, "Inbox Task 1")
        XCTAssertEqual(inboxTasks[1].title, "Inbox Task 2")
        XCTAssertEqual(inboxTasks[2].title, "Inbox Task 3")
        
        // Reorder tasks
        task3.moveBeforeItem(task1)
        
        // Verify new order
        let updatedInboxTasks = try viewContext.fetch(inboxRequest)
        XCTAssertEqual(updatedInboxTasks[0].title, "Inbox Task 3")
        XCTAssertEqual(updatedInboxTasks[1].title, "Inbox Task 1")
        XCTAssertEqual(updatedInboxTasks[2].title, "Inbox Task 2")
    }
    
    func testNewItemsOrderedAtEnd() throws {
        // Create a project
        let project = Project(context: viewContext)
        project.id = UUID()
        project.name = "Test Project"
        
        // Create initial tasks
        let task1 = Item.create(in: viewContext, title: "Task 1", project: project)
        let task2 = Item.create(in: viewContext, title: "Task 2", project: project)
        
        try viewContext.save()
        
        // Add a new task to the project
        let task3 = Item.create(in: viewContext, title: "Task 3", project: project)
        
        try viewContext.save()
        
        // Verify that the new task is ordered after existing tasks
        let projectRequest = TaskFetchRequestFactory.tasksForProject(project, in: viewContext)
        let projectTasks = try viewContext.fetch(projectRequest)
        
        XCTAssertEqual(projectTasks.count, 3)
        XCTAssertTrue(projectTasks[2].title == "Task 3", "New task should be at the end")
        XCTAssertGreaterThan(task3.displayOrder, task2.displayOrder)
    }
}
