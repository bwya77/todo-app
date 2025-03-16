# Drag and Drop Task Reordering Implementation Guide

## Introduction

This document provides detailed implementation steps for adding drag-and-drop functionality to reorder tasks in the Todo app. It expands on the feature plan with specific code examples and implementation details.

## 1. CoreData Model Updates

### Create New Model Version

1. Open the `todo_app.xcdatamodeld` file
2. In Xcode, select Editor > Add Model Version
3. Name it `todo_app_v3.xcdatamodel`
4. Make it the current version by selecting the xcdatamodeld file and setting the current version in the file inspector

### Add DisplayOrder Attribute

Add to the Item entity in the new model version:

```swift
attribute name="displayOrder" attributeType="Integer 32" defaultValueString="0" usesScalarValueType="YES"
```

### Update Migration Policy

Update `TodoAppMigrationPolicy.swift`:

```swift
func createDestinationInstances(forSource sourceInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
    // Call the superclass implementation
    try super.createDestinationInstances(forSource: sourceInstance, in: mapping, manager: manager)
    
    // Get the destination instances that were created
    let destinationInstances = manager.destinationInstances(forSourceInstance: sourceInstance, entityMappingName: mapping.name)
    
    guard let destinationInstance = destinationInstances.first else { return }
    
    // Handle v2 to v3 migration - set initial displayOrder
    if mapping.destinationEntityName == "Item" && !destinationInstance.entity.attributesByName.keys.contains("displayOrder") {
        // Set initial display order based on creation date as a reasonable default
        if let createdDate = sourceInstance.value(forKey: "createdDate") as? Date {
            let timeInterval = createdDate.timeIntervalSince1970
            destinationInstance.setValue(Int32(timeInterval), forKey: "displayOrder")
        } else {
            // Fallback to a random value if no created date
            destinationInstance.setValue(Int32.random(in: 0..<10000), forKey: "displayOrder")
        }
    }
}
```

## 2. Item Extension Updates

### Add to Item+CoreDataExtensions.swift

```swift
// MARK: - Display Order Operations

/// Set the display order for this item
/// - Parameters:
///   - order: The new display order value
///   - save: Whether to save the context
func setDisplayOrder(_ order: Int32, save: Bool = true) {
    displayOrder = order
    
    if save, let context = managedObjectContext {
        do {
            try context.save()
        } catch {
            print("Error saving display order: \(error)")
        }
    }
}

/// Get all items with the same project as this item
/// - Returns: Array of items in the same project, sorted by display order
func getSiblingsInProject() -> [Item] {
    guard let context = self.managedObjectContext else { return [] }
    
    let request: NSFetchRequest<Item> = Item.fetchRequest()
    if let project = self.project {
        request.predicate = NSPredicate(format: "project == %@", project)
    } else {
        request.predicate = NSPredicate(format: "project == nil")
    }
    
    request.sortDescriptors = [
        NSSortDescriptor(keyPath: \Item.displayOrder, ascending: true)
    ]
    
    do {
        return try context.fetch(request)
    } catch {
        print("Error fetching siblings: \(error)")
        return []
    }
}

/// Reorder this item to be before another item
/// - Parameters:
///   - targetItem: The item that this item should appear before
///   - save: Whether to save the context after reordering
func moveBeforeItem(_ targetItem: Item, save: Bool = true) {
    // Ensure items are in the same project
    guard self.project == targetItem.project else {
        print("Cannot reorder items in different projects")
        return
    }
    
    // Get all siblings sorted by display order
    var siblings = getSiblingsInProject()
    
    // Remove self from the array
    siblings.removeAll { $0 == self }
    
    // Find the index of the target item
    guard let targetIndex = siblings.firstIndex(of: targetItem) else {
        print("Target item not found in siblings")
        return
    }
    
    // Insert self at the target position
    siblings.insert(self, at: targetIndex)
    
    // Update display orders for all items
    Self.reorderItems(siblings, save: save)
}

/// Update display order for all items in a collection
/// - Parameters:
///   - items: The items to reorder
///   - context: The managed object context
static func reorderItems(_ items: [Item], save: Bool = true) {
    // Use a reasonable spacing between items to allow for later insertions
    // without having to reorder everything
    let orderSpacing: Int32 = 1000
    
    for (index, item) in items.enumerated() {
        item.displayOrder = Int32(index) * orderSpacing
    }
    
    if save, let context = items.first?.managedObjectContext {
        do {
            try context.save()
        } catch {
            print("Error saving after reordering: \(error)")
        }
    }
}
```

## 3. Create Draggable Task Row

Create a new file `DraggableTaskRow.swift` in the Presentation/Components/Task directory:

```swift
//
//  DraggableTaskRow.swift
//  todo-app
//
//  Created on 3/15/25.
//

import SwiftUI

struct DraggableTaskRow: View {
    let task: Item
    let onToggleComplete: (Item) -> Void
    let viewType: ViewType
    let onReorder: ((Item, Item) -> Void)?
    
    @State private var isBeingDragged = false
    
    init(task: Item, onToggleComplete: @escaping (Item) -> Void, viewType: ViewType, onReorder: ((Item, Item) -> Void)? = nil) {
        self.task = task
        self.onToggleComplete = onToggleComplete
        self.viewType = viewType
        self.onReorder = onReorder
    }
    
    var body: some View {
        TaskRow(task: task, onToggleComplete: onToggleComplete, viewType: viewType)
            .opacity(isBeingDragged ? 0.5 : 1.0)
            .onDrag {
                // Start drag operation
                self.isBeingDragged = true
                
                // Create a data representation with the task ID
                let itemData = ["taskID": task.id?.uuidString ?? "unknown"]
                let data = try? JSONEncoder().encode(itemData)
                
                // Create and configure the provider
                let provider = NSItemProvider(item: data as NSSecureCoding?, typeIdentifier: "com.todoapp.taskid")
                
                // Set a cleanup callback
                provider.loadDataRepresentation(forTypeIdentifier: "com.todoapp.taskid") { _, _ in
                    // When drag operation completes (regardless of outcome)
                    DispatchQueue.main.async {
                        self.isBeingDragged = false
                    }
                    return
                }
                
                return provider
            }
            .onDrop(of: ["com.todoapp.taskid"], isTargeted: nil) { providers in
                // Handle the drop operation
                guard let first = providers.first else { return false }
                
                first.loadDataRepresentation(forTypeIdentifier: "com.todoapp.taskid") { data, error in
                    guard let data = data,
                          let itemData = try? JSONDecoder().decode([String: String].self, from: data),
                          let sourceTaskIDString = itemData["taskID"],
                          let sourceTaskID = UUID(uuidString: sourceTaskIDString),
                          let sourceTask = findTask(with: sourceTaskID),
                          let onReorder = self.onReorder else {
                        return
                    }
                    
                    // Call the reorder callback
                    DispatchQueue.main.async {
                        onReorder(sourceTask, self.task)
                    }
                }
                
                return true
            }
    }
    
    // Helper function to find a task by ID
    private func findTask(with id: UUID) -> Item? {
        guard let context = task.managedObjectContext else { return nil }
        
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error finding task with ID \(id): \(error)")
            return nil
        }
    }
}
```

## 4. Update the EnhancedTaskViewModel

Add the following functions to `EnhancedTaskViewModel.swift`:

```swift
// MARK: - Task Reordering

/// Handle reordering when a task is dragged and dropped onto another task
/// - Parameters:
///   - sourceTask: The task being dragged
///   - targetTask: The task being dropped onto
func reorderTask(_ sourceTask: Item, before targetTask: Item) {
    // Don't reorder if it's the same task
    guard sourceTask != targetTask else { return }
    
    // If source and target are in different projects, handle project change first
    if sourceTask.project != targetTask.project {
        sourceTask.project = targetTask.project
    }
    
    // Move source task before target task
    sourceTask.moveBeforeItem(targetTask)
    
    // Refresh to update UI
    refreshFetch()
}

/// Find a task by its ID
/// - Parameter id: The UUID to search for
/// - Returns: The matching Item or nil if not found
func findTask(with id: UUID) -> Item? {
    let request: NSFetchRequest<Item> = Item.fetchRequest()
    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
    request.fetchLimit = 1
    
    do {
        let results = try viewContext.fetch(request)
        return results.first
    } catch {
        print("Error finding task with ID \(id): \(error)")
        return nil
    }
}
```

## 5. Update SectionView in EnhancedTaskListView

Replace the ForEach loop in `SectionView` with this:

```swift
// Tasks content
if expandedGroups.contains(title) {
    ForEach(tasks) { task in
        DraggableTaskRow(
            task: task, 
            onToggleComplete: onToggleComplete, 
            viewType: viewType,
            onReorder: { sourceTask, targetTask in
                // Call the parent view model to handle reordering
                onReorderTask(sourceTask, targetTask)
            }
        )
        .contextMenu {
            Button(action: {
                onDeleteTask(task)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
```

## 6. Update EnhancedTaskListView

Add this property and pass it to the SectionView:

```swift
// Add this to EnhancedTaskListView struct
private func handleTaskReorder(_ sourceTask: Item, _ targetTask: Item) {
    viewModel.reorderTask(sourceTask, before: targetTask)
}

// Then in the SectionView creation:
SectionView(
    section: section,
    title: viewModel.titleForSection(section),
    tasks: viewModel.tasksForSection(section),
    expandedGroups: $expandedGroups,
    onToggleComplete: { task in
        viewModel.toggleTaskCompletion(task)
    },
    onDeleteTask: { task in
        viewModel.deleteTask(task)
    },
    onReorderTask: handleTaskReorder,  // Add this line
    viewType: viewType
)
```

## 7. Update SectionView Declaration

Update the SectionView struct declaration to include the new parameter:

```swift
struct SectionView: View {
    let section: Int
    let title: String
    let tasks: [Item]
    @Binding var expandedGroups: Set<String>
    let onToggleComplete: (Item) -> Void
    let onDeleteTask: (Item) -> Void
    let onReorderTask: (Item, Item) -> Void  // Add this line
    let viewType: ViewType
    
    // ... rest of struct remains the same
}
```

## 8. Update TaskFetchRequestFactory

Update all fetch request methods in `TaskFetchRequestFactory.swift` to include displayOrder in sort descriptors:

```swift
// Example for allTasks method
static func allTasks(in context: NSManagedObjectContext) -> NSFetchRequest<Item> {
    let request: NSFetchRequest<Item> = Item.fetchRequest()
    request.sortDescriptors = [
        NSSortDescriptor(keyPath: \Item.displayOrder, ascending: true),
        NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
        NSSortDescriptor(keyPath: \Item.priority, ascending: false),
        NSSortDescriptor(keyPath: \Item.title, ascending: true)
    ]
    
    return request
}
```

Do the same for all other fetch request methods, adding `displayOrder` as the first sort descriptor.

## 9. Update Project Detail View

Ensure the `ProjectDetailView.swift` also supports task reordering:

```swift
ForEach(projectTasks) { task in
    DraggableTaskRow(
        task: task, 
        onToggleComplete: toggleTaskCompletion, 
        viewType: .project,
        onReorder: { sourceTask, targetTask in
            // Call the same reordering function used in task list view
            viewModel.reorderTask(sourceTask, before: targetTask)
        }
    )
}
```

## 10. Add Tests

Create a new test file `TaskReorderingTests.swift`:

```swift
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
}
```

## Conclusion

This implementation provides a complete drag-and-drop reordering experience while maintaining the app's architecture. The key aspects are:

1. CoreData schema update with a `displayOrder` attribute
2. Reusable drag and drop components
3. Logic to handle the persistence of the custom ordering

After implementing these changes, users will be able to organize their tasks in a personalized order within projects, Inbox, and Upcoming views, significantly enhancing the app's flexibility and user experience.
