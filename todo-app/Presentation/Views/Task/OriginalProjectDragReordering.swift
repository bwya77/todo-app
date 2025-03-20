//
//  OriginalProjectDragReordering.swift
//  todo-app
//
//  Created on 3/20/25.
//

import SwiftUI
import CoreData

// This is a direct copy of the original project task reordering implementation
// We'll use this to ensure inbox reordering works exactly the same way
struct ProjectOriginalTaskList: View {
    @Environment(\.managedObjectContext) private var viewContext
    let tasks: [Item]
    let onToggleComplete: (Item) -> Void
    let project: Project?
    
    @Binding var activeTask: Item?
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(tasks) { task in
                TaskRow(task: task, onToggleComplete: onToggleComplete)
                    .id("task-\(task.id?.uuidString ?? UUID().uuidString)")
                    .contentShape(Rectangle())
                    .onDrag {
                        // Set the item being dragged
                        self.activeTask = task
                        
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
                        
                        // Reset dragging state
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.activeTask = nil
                        }
                        return true
                    }
                    .padding(.vertical, 4)
                    // Visual effects during drag
                    .opacity(activeTask == task ? 0.6 : 1.0)
                    .offset(y: activeTask == task ? -2 : 0)
                    .scaleEffect(activeTask == task ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: activeTask)
            }
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
        print("📲 Reordering tasks from \(from) to \(to)")
        
        // Create a mutable copy of the task array
        var taskArray = tasks
        
        // Remove the task from its current position
        let taskToMove = taskArray[from]
        taskArray.remove(at: from)
        
        // Insert the task at the new position
        taskArray.insert(taskToMove, at: to)
        
        // Update display order values (using 10-point increments)
        for (index, task) in taskArray.enumerated() {
            task.setValue(Int32(index * 10), forKey: "displayOrder")
        }
        
        // Save changes
        PersistentOrder.save(context: viewContext)
    }
}
