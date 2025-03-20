//
//  InboxTaskList.swift
//  todo-app
//
//  Created on 3/20/25.
//

import SwiftUI
import CoreData
import Combine

/// A dedicated task list view for Inbox that perfectly mirrors the Project task reordering behavior
struct InboxTaskList: View {
    @Environment(\.managedObjectContext) private var viewContext
    let tasks: [Item]
    let onToggleComplete: (Item) -> Void
    let onDeleteTask: ((Item) -> Void)?
    
    @Binding var activeTask: Item?
    @State private var isReordering = false
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(tasks) { task in
                TaskRow(task: task, onToggleComplete: onToggleComplete, viewType: .inbox)
                    .id("task-\(task.id?.uuidString ?? UUID().uuidString)")
                    .contentShape(Rectangle())
                    .onDrag {
                        // Set the item being dragged
                        self.activeTask = task
                        self.isReordering = true
                        
                        // Use the UUID string as the dragging identifier
                        return NSItemProvider(object: NSString(string: task.id?.uuidString ?? "unknown"))
                    }
                    .onDrop(of: ["public.text"], isTargeted: nil) { providers, location in
                        // Only handle drop if we have a dragging item
                        guard let draggingItem = self.activeTask else { return false }
                        
                        // Find the indices of the source and destination items
                        guard let fromIndex = indexOf(task: draggingItem),
                              let toIndex = indexOf(task: task) else {
                            return false
                        }
                        
                        // Don't do anything if dropped on itself
                        if fromIndex == toIndex { return false }
                        
                        // Perform the reordering with animation
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            reorderTasks(from: fromIndex, to: toIndex)
                        }
                        
                        // Reset dragging state after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.activeTask = nil
                            self.isReordering = false
                        }
                        return true
                    }
                    .contextMenu {
                        if let onDelete = onDeleteTask {
                            Button(action: {
                                onDelete(task)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    // Visual effects during drag - MATCHED EXACTLY to project view
                    .opacity(activeTask == task ? 0.6 : 1.0)
                    .offset(y: activeTask == task ? -2 : 0)
                    .scaleEffect(activeTask == task ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: activeTask)
            }
        }
        .onAppear {
            // Reset state when view appears
            activeTask = nil
            isReordering = false
        }
    }
    
    // Find the index of a task
    private func indexOf(task: Item) -> Int? {
        for i in 0..<tasks.count {
            if tasks[i].id == task.id {
                return i
            }
        }
        return nil
    }
    
    // Reorder the tasks with the same logic as project view
    private func reorderTasks(from: Int, to: Int) {
        print("📲 Reordering inbox tasks from \(from) to \(to)")
        
        guard from < tasks.count else { return }
        
        // Create a mutable copy of the task array
        var taskArray = Array(tasks)
        
        // Remove the task from its current position
        let taskToMove = taskArray.remove(at: from)
        
        // Insert the task at the new position
        let safeToIndex = min(to, taskArray.count)
        taskArray.insert(taskToMove, at: safeToIndex)
        
        // Update display order values (using 10-point increments)
        for (index, task) in taskArray.enumerated() {
            let newOrder = Int32(index * 10)
            print("  Setting inbox task '\(task.title ?? "Untitled")' display order: \(newOrder)")
            task.setValue(newOrder, forKey: "displayOrder")
        }
        
        // Save changes with our enhanced persistence mechanism
        PersistentOrder.saveAllContexts()
        
        // Force a notification to update all views
        NotificationCenter.default.post(
            name: NSNotification.Name.NSManagedObjectContextDidSave,
            object: viewContext
        )
        
        // Also post a notification for full UI refresh
        NotificationCenter.default.post(
            name: NSNotification.Name("ForceUIRefresh"),
            object: nil
        )
    }
}
