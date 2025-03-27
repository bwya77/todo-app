//
//  HeaderTasksView.swift
//  todo-app
//
//  Created on 3/26/25.
//

import SwiftUI
import CoreData

struct HeaderTasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var header: ProjectHeader
    let onToggleComplete: (Item) -> Void
    
    @FetchRequest private var tasks: FetchedResults<Item>
    @Binding var activeTask: Item?
    @Binding var expandedHeaders: Set<UUID>
    
    // Global drop target ID binding
    @Binding var dropTargetId: UUID?
    
    // Check if this header is expanded
    private var isExpanded: Bool {
        guard let headerId = header.id else { return true }
        return expandedHeaders.contains(headerId)
    }
    
    init(header: ProjectHeader, onToggleComplete: @escaping (Item) -> Void, activeTask: Binding<Item?>, expandedHeaders: Binding<Set<UUID>>, dropTargetId: Binding<UUID?>) {
        self.header = header
        self.onToggleComplete = onToggleComplete
        self._activeTask = activeTask
        self._expandedHeaders = expandedHeaders
        self._dropTargetId = dropTargetId
        
        // Initialize fetch request for tasks in this header
        self._tasks = FetchRequest(fetchRequest: ProjectHeadersRequest.tasksForHeaderRequest(header: header))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Only show tasks if the header is expanded
            if isExpanded {
                if !tasks.isEmpty {
                    ReorderableForEach(Array(tasks), active: $activeTask, dropTarget: $dropTargetId) { task in
                        TaskRow(task: task, onToggleComplete: onToggleComplete)
                            .id("task-\(task.id?.uuidString ?? UUID().uuidString)")
                            .contentShape(Rectangle())
                            .padding(.vertical, 2)
                            .background(Color.white)
                            .scaleEffect(activeTask == task ? 1.03 : 1.0)
                            .shadow(color: activeTask == task ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: activeTask == task ? 2 : 0)
                            .zIndex(activeTask == task ? 1 : 0)
                            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1), value: activeTask)
                    } moveAction: { fromOffsets, toOffset in
                        let fromIndex = fromOffsets.first ?? 0
                        reorderTasks(from: fromIndex, to: toOffset)
                    }
                    .reorderableForEachContainer(active: $activeTask, dropTarget: $dropTargetId)
                    .padding(.leading, 8) // Indent tasks under header
                } else {
                    // Empty placeholder to accept drops when no tasks exist
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 30)
                        .contentShape(Rectangle())
                        .onDrop(of: [.text], isTargeted: nil) { providers, _ in
                            return handleTaskDrop(providers: providers)
                        }
                        .padding(.leading, 8) // Consistent with other tasks
                }
            }
        }
        // Add drop support to the entire VStack
        .onDrop(of: [.text], isTargeted: nil) { providers, _ in
            return handleTaskDrop(providers: providers)
        }
    }
    
    private func reorderTasks(from: Int, to: Int) {
        guard from < tasks.count else { return }
        
        // Safe array operations
        var taskArray = Array(tasks)
        let safeFrom = min(from, taskArray.count - 1)
        let taskToMove = taskArray.remove(at: safeFrom)
        
        // Safe insertion
        let safeTo = min(to, taskArray.count)
        taskArray.insert(taskToMove, at: safeTo)
        
        // Update display order with spacing for future insertions
        for (index, task) in taskArray.enumerated() {
            task.setValue(Int32(index * 10), forKey: "displayOrder")
        }
        
        // Ensure changes are saved to disk
        PersistentOrder.save(context: viewContext)
    }
    
    // Helper function to set the global drop target ID
    private func setDropTarget(_ id: UUID?) {
        DispatchQueue.main.async {
            self.dropTargetId = id
        }
    }
    
    // Handle task drop from anywhere onto this header
    private func handleTaskDrop(providers: [NSItemProvider]) -> Bool {
        guard let activeTask = activeTask else { return false }
        
        // Clear drop target on drop
        setDropTarget(nil)
        
        // Safety check - if the task is already in this header, just update order
        if activeTask.header == header {
            // Move to the end of the list
            let taskArray = Array(tasks)
            if let index = taskArray.firstIndex(of: activeTask) {
                reorderTasks(from: index, to: taskArray.count)
            }
            return true
        }
        
        // Move the active task to this header
        let oldHeader = activeTask.header
        activeTask.header = header
        
        // Update display order to be at the end of this header's tasks
        let allTasks = header.tasks()
        activeTask.displayOrder = allTasks.isEmpty ? 0 : (allTasks.map { $0.displayOrder }.max() ?? 0) + 10
        
        // Save changes
        do {
            try viewContext.save()
            
            // Reset active task
            self.activeTask = nil
            return true
        } catch {
            print("Error moving task to header: \(error)")
            // Attempt to revert the change
            activeTask.header = oldHeader
            return false
        }
    }
}
