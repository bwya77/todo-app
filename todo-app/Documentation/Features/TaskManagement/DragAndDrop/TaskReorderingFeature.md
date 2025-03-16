# Task Reordering Feature Implementation Plan

## Overview

This document outlines the implementation plan for adding drag-and-drop functionality to reorder tasks in the Todo app. The feature will allow users to reorder tasks in various list views including Inbox, Upcoming, and Projects.

## Current Architecture Assessment

The Todo app is built with:
- **Swift and SwiftUI**: Main framework for the UI
- **CoreData**: Storage and persistence
- **MVVM Architecture**: Clear separation between views and data

### Current Implementation

Currently, tasks are displayed in:
1. `TaskListView.swift`: The original task list implementation
2. `EnhancedTaskListView.swift`: An improved version using `NSFetchedResultsController`
3. Various calendar views

Tasks are ordered based on CoreData fetch request sort descriptors:
```swift
request.sortDescriptors = [
    NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
    NSSortDescriptor(keyPath: \Item.priority, ascending: false),
    NSSortDescriptor(keyPath: \Item.title, ascending: true)
]
```

## Missing Components

1. **Sort Order Attribute**: The `Item` entity in CoreData does not have an explicit `sortOrder` or `displayOrder` attribute.
2. **Drag and Drop Infrastructure**: SwiftUI drag and drop capabilities are not yet implemented.
3. **Persistent Ordering**: No mechanism to persist user-defined order.

## Implementation Plan

### 1. CoreData Model Update

Add a new attribute to the `Item` entity:

```swift
// Add to CoreData model
attribute name="displayOrder" attributeType="Integer 32" defaultValueString="0" usesScalarValueType="YES"
```

This will require a CoreData migration strategy since the app is already using CoreData version 2:

1. Create `todo_app_v3.xcdatamodel` in the model versioning
2. Add migration logic to `TodoAppMigrationPolicy.swift`
3. Update version hash modifiers as needed

### 2. Update Item Extension

Add new methods to `Item+CoreDataExtensions.swift`:

```swift
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

/// Update display order for all items in a collection
/// - Parameters:
///   - items: The items to reorder
///   - context: The managed object context
static func reorderItems(_ items: [Item], save: Bool = true) {
    for (index, item) in items.enumerated() {
        item.displayOrder = Int32(index)
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

### 3. Update Fetch Request Factory

Modify `TaskFetchRequestFactory.swift` to include `displayOrder` in sort descriptors:

```swift
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

Similarly update other fetch request methods to prioritize `displayOrder`.

### 4. Implement Drag and Drop in Task Lists

1. Create a new reusable component `DraggableTaskRow.swift`:

```swift
struct DraggableTaskRow: View {
    let task: Item
    let onToggleComplete: (Item) -> Void
    let viewType: ViewType
    
    var body: some View {
        TaskRow(task: task, onToggleComplete: onToggleComplete, viewType: viewType)
            .onDrag {
                // Return NSItemProvider with task ID
                let provider = NSItemProvider(object: task.id?.uuidString ?? "" as NSString)
                return provider
            }
    }
}
```

2. Update `EnhancedTaskListView.swift` to support drag and drop:

```swift
if expandedGroups.contains(title) {
    ForEach(tasks) { task in
        DraggableTaskRow(task: task, onToggleComplete: onToggleComplete, viewType: viewType)
            .onDrop(of: ["public.text"], isTargeted: nil) { providers in
                // Handle drop logic
                handleDrop(of: providers, task: task, tasks: tasks)
                return true
            }
    }
}
```

3. Add the drop handling logic to `EnhancedTaskViewModel.swift`:

```swift
func moveTask(with id: UUID, before targetTask: Item) {
    guard let taskToMove = findTask(with: id) else { return }
    guard let targetIndex = findTaskIndex(targetTask) else { return }
    
    // Remove task from current position
    var updatedTasks = tasks
    if let currentIndex = findTaskIndex(taskToMove, in: updatedTasks) {
        updatedTasks.remove(at: currentIndex)
    }
    
    // Insert at new position
    if let newIndex = findTaskIndex(targetTask, in: updatedTasks) {
        updatedTasks.insert(taskToMove, at: newIndex)
    }
    
    // Update display orders
    Item.reorderItems(updatedTasks, save: true)
    
    // Refresh the fetch to update UI
    refreshFetch()
}
```

### 5. Handle Project-Specific Ordering

For items moved between projects, we need special handling:

```swift
func moveTaskBetweenProjects(task: Item, toProject: Project?, atIndex: Int) {
    // First update the project
    task.project = toProject
    
    // Get all tasks in the target project
    let projectTasks = fetchTasksForProject(toProject)
    var updatedTasks = projectTasks
    
    // Insert at correct position
    if !updatedTasks.contains(task) {
        let insertIndex = min(atIndex, updatedTasks.count)
        updatedTasks.insert(task, at: insertIndex)
    }
    
    // Reorder all items in this project
    Item.reorderItems(updatedTasks, save: true)
    
    // Refresh to update UI
    refreshFetch()
}
```

### 6. Update Project Detail View

Make sure `ProjectDetailView.swift` also supports task reordering:

```swift
ForEach(projectTasks) { task in
    DraggableTaskRow(task: task, onToggleComplete: toggleTaskCompletion, viewType: .project)
        .onDrop(of: ["public.text"], isTargeted: nil) { providers in
            handleDrop(of: providers, task: task, tasks: projectTasks)
            return true
        }
}
```

## Potential Challenges

1. **Performance Implications**: Reordering many tasks could be expensive.
   - Solution: Batch updates and optimize CoreData saves.

2. **User Experience on Reordering**: Need animations to clearly show the reordering.
   - Solution: Implement with SwiftUI's withAnimation.

3. **View Refresh Issues**: After reordering, the view may not immediately reflect changes.
   - Solution: Ensure proper NSFetchedResultsController configuration and notification handling.

4. **Conflict with Auto-Sorting**: Some views may have automatic sorting (e.g., by date).
   - Solution: Make explicit which views support custom ordering versus auto-sorting.

## Testing Plan

1. Unit tests for:
   - Display order persistence
   - Reordering algorithm
   - Sort descriptor changes

2. UI tests for:
   - Drag and drop behavior
   - Persistence between app restarts

## Implementation Timeline

1. CoreData Model Update: 1 day
2. Item Extensions and Fetch Request Updates: 1 day
3. Basic Drag and Drop UI: 2 days
4. Project-Specific Ordering: 1 day
5. Edge Case Handling and Testing: 2 days

Total Estimated Time: 7 days

## Conclusion

Adding drag-and-drop reordering to the Todo app is a medium-complexity feature that primarily requires:
1. CoreData schema updates with migration
2. New interaction patterns in the task list views
3. Logic to handle the reordering persistence

This implementation maintains the app's current architecture while adding valuable user flexibility. The main complexity lies in handling CoreData migrations safely and ensuring consistent order when tasks are viewed in different contexts.
