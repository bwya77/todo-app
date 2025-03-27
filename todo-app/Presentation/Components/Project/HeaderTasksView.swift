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
    
    init(header: ProjectHeader, onToggleComplete: @escaping (Item) -> Void, activeTask: Binding<Item?>) {
        self.header = header
        self.onToggleComplete = onToggleComplete
        self._activeTask = activeTask
        
        // Initialize fetch request for tasks in this header
        self._tasks = FetchRequest(fetchRequest: ProjectHeadersRequest.tasksForHeaderRequest(header: header))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !tasks.isEmpty {
                ReorderableForEach(Array(tasks), active: $activeTask) { task in
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
                .reorderableForEachContainer(active: $activeTask)
                .padding(.leading, 8) // Indent tasks under header
            } else {
                // Empty state - placeholder text removed as requested
                EmptyView()
            }
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
}
