//
//  ReorderableTaskList.swift
//  todo-app
//
//  Created on 3/19/25.
//

import SwiftUI
import CoreData

struct ReorderableTaskList: View {
    @Environment(\.managedObjectContext) private var viewContext
    let tasks: FetchedResults<Item>
    let onToggleComplete: (Item) -> Void
    let projectId: UUID?
    
    @State private var draggingItem: Item?
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(tasks) { task in
                TaskRow(task: task, onToggleComplete: onToggleComplete)
                    .id("task-\(task.id?.uuidString ?? UUID().uuidString)")
                    .contentShape(Rectangle())
                    .onDrag {
                        // Set the item being dragged
                        self.draggingItem = task
                        
                        // Use the UUID string as the dragging identifier
                        return NSItemProvider(object: NSString(string: task.id?.uuidString ?? "unknown"))
                    }
                    .onDrop(of: ["public.text"], isTargeted: nil) { providers, location in
                        // Only handle drop if we have a dragging item
                        guard let draggingItem = self.draggingItem else { return false }
                        
                        // Find the indices of the source and destination items
                        guard let fromIndex = indexOf(task: draggingItem),
                              let toIndex = indexOf(task: task) else {
                            return false
                        }
                        
                        // Don't do anything if dropped on itself
                        if fromIndex == toIndex { return false }
                        
                        // Perform the reordering
                        reorderTasks(from: fromIndex, to: toIndex)
                        
                        // Reset dragging state
                        self.draggingItem = nil
                        return true
                    }
                    .padding(.vertical, 4)
            }
        }
    }
    
    // Find the index of a task in the FetchedResults
    private func indexOf(task: Item) -> Int? {
        for i in 0..<tasks.count {
            if tasks[i].id == task.id {
                return i
            }
        }
        return nil
    }
    
    // Reorder the tasks and update display order in Core Data
    private func reorderTasks(from: Int, to: Int) {
        print("📲 Reordering tasks from \(from) to \(to)")
        
        // Convert to array for easier manipulation
        var taskArray = Array(tasks)
        
        // Create a mutable copy of the task array
        let taskToMove = taskArray[from]
        taskArray.remove(at: from)
        taskArray.insert(taskToMove, at: to)
        
        // Update display order values (using 10-point increments)
        for (index, task) in taskArray.enumerated() {
            let newOrder = Int32(index * 10)
            print("  → Setting task '\(task.title ?? "Untitled")' display order: \(newOrder)")
            task.setValue(newOrder, forKey: "displayOrder")
        }
        
        // Save changes
        do {
            try viewContext.save()
            
            // Force a notification to update all views
            NotificationCenter.default.post(
                name: NSNotification.Name.NSManagedObjectContextDidSave,
                object: viewContext
            )
            
            // Use our PersistentOrder to ensure changes are flushed to disk
            PersistentOrder.save(context: viewContext)
            
            print("✅ Successfully saved task reordering")
        } catch {
            print("❌ Error reordering tasks: \(error)")
        }
    }
}
