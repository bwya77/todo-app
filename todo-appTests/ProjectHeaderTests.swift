//
//  ProjectHeaderTests.swift
//  todo-appTests
//
//  Created on 3/26/25.
//

import XCTest
import CoreData
@testable import todo_app

final class ProjectHeaderTests: XCTestCase {
    
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        container = NSPersistentContainer(name: "todo_app")
        
        // Use an in-memory store for testing
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { (description, error) in
            XCTAssertNil(error)
        }
        
        context = container.viewContext
    }
    
    override func tearDownWithError() throws {
        context = nil
        container = nil
    }
    
    func testCreateProjectHeader() throws {
        // Create a project
        let project = Project.create(in: context, name: "Test Project")
        
        // Create a header
        let header = ProjectHeader.create(in: context, title: "Planning", project: project)
        
        // Verify header was created with correct properties
        XCTAssertNotNil(header.id)
        XCTAssertEqual(header.title, "Planning")
        XCTAssertEqual(header.project, project)
        XCTAssertEqual(header.displayOrder, 0)  // First header should have order 0
        
        // Create a second header and verify its order
        let header2 = ProjectHeader.create(in: context, title: "Development", project: project)
        XCTAssertEqual(header2.displayOrder, 10)  // Second header should have order 10
    }
    
    func testAddTasksToHeader() throws {
        // Create a project
        let project = Project.create(in: context, name: "Test Project")
        
        // Create a header
        let header = ProjectHeader.create(in: context, title: "Planning", project: project)
        
        // Create tasks
        let task1 = Item.create(in: context, title: "Task 1", project: project)
        let task2 = Item.create(in: context, title: "Task 2", project: project)
        
        // Move tasks to header
        task1.moveToHeader(header)
        task2.moveToHeader(header)
        
        // Save context
        try context.save()
        
        // Verify tasks are in the header
        let headerTasks = header.tasks()
        XCTAssertEqual(headerTasks.count, 2)
        XCTAssertTrue(headerTasks.contains(task1))
        XCTAssertTrue(headerTasks.contains(task2))
    }
    
    func testReorderHeaders() throws {
        // Create a project
        let project = Project.create(in: context, name: "Test Project")
        
        // Create headers
        let header1 = ProjectHeader.create(in: context, title: "Planning", project: project)
        let header2 = ProjectHeader.create(in: context, title: "Development", project: project)
        let header3 = ProjectHeader.create(in: context, title: "Testing", project: project)
        
        try context.save()
        
        // Get headers in order
        let headers = project.orderedHeaders()
        XCTAssertEqual(headers.count, 3)
        XCTAssertEqual(headers[0].title, "Planning")
        XCTAssertEqual(headers[1].title, "Development")
        XCTAssertEqual(headers[2].title, "Testing")
        
        // Reorder headers (move Testing to first position)
        ProjectHeader.reorderHeaders(from: 2, to: 0, headers: headers, context: context)
        
        // Verify new order
        let reorderedHeaders = project.orderedHeaders()
        XCTAssertEqual(reorderedHeaders.count, 3)
        XCTAssertEqual(reorderedHeaders[0].title, "Testing")
        XCTAssertEqual(reorderedHeaders[1].title, "Planning")
        XCTAssertEqual(reorderedHeaders[2].title, "Development")
    }
    
    func testDeleteHeaderMovesTasksToUnheadered() throws {
        // Create a project
        let project = Project.create(in: context, name: "Test Project")
        
        // Create a header
        let header = ProjectHeader.create(in: context, title: "Planning", project: project)
        
        // Create tasks and add to header
        let task1 = Item.create(in: context, title: "Task 1", project: project)
        let task2 = Item.create(in: context, title: "Task 2", project: project)
        task1.moveToHeader(header)
        task2.moveToHeader(header)
        
        try context.save()
        
        // Verify tasks are in the header
        XCTAssertEqual(header.tasks().count, 2)
        
        // Get a copy of the task IDs
        let task1Id = task1.id!
        let task2Id = task2.id!
        
        // Delete the header
        let viewModel = TaskViewModel(context: context)
        viewModel.deleteHeader(header)
        
        // Verify tasks still exist but no longer have a header
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id IN %@", [task1Id, task2Id])
        let tasks = try context.fetch(fetchRequest)
        
        XCTAssertEqual(tasks.count, 2)
        XCTAssertNil(tasks[0].header)
        XCTAssertNil(tasks[1].header)
        
        // Verify they're now in the project's unheadered tasks
        let unheaderedTasks = project.tasksWithoutHeader()
        XCTAssertEqual(unheaderedTasks.count, 2)
    }
}
