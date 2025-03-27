//
//  UnifiedTaskListView.swift
//  todo-app
//
//  Created on 3/20/25.
//

import SwiftUI
import CoreData

/// A unified task list view that provides consistent reordering behavior
/// across all view types (Inbox, Projects, Today, etc.)
struct UnifiedTaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let viewType: ViewType
    let title: String
    let tasks: [Item]
    let project: Project?
    
    @Binding var activeTask: Item?
    let onToggleComplete: (Item) -> Void
    let onDeleteTask: ((Item) -> Void)?
    
    // For improved animations
    @State private var isDragging = false
    
    var body: some View {
        LazyVStack(spacing: 0) {
            // Use ReorderableForEach with consistent behavior
            ReorderableForEach(tasks, active: $activeTask) { task in
                TaskRow(task: task, onToggleComplete: onToggleComplete, viewType: viewType)
                    .id("task-\(task.id?.uuidString ?? UUID().uuidString)")
                    .contentShape(Rectangle())
                    // Enhanced animation behavior like in project view
                    .padding(.vertical, 2)
                    .background(Color.white)
                    .scaleEffect(activeTask == task ? 1.03 : 1.0)
                    .shadow(color: activeTask == task ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: activeTask == task ? 2 : 0)
                    .zIndex(activeTask == task ? 1 : 0)
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1), value: activeTask)
                    .contextMenu {
                        if let onDelete = onDeleteTask {
                            Button(action: {
                                onDelete(task)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onChange(of: activeTask) { _, newValue in
                        isDragging = newValue != nil
                    }
            } moveAction: { fromOffsets, toOffset in
                print("📲 UnifiedTaskList: Moving from \(fromOffsets) to \(toOffset) in \(title)")
                
                // Use smooth animation with a slightly longer duration for the slide effect
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                    reorderTasks(from: fromOffsets.first ?? 0, to: toOffset)
                }
            }
        }
        .reorderableForEachContainer(active: $activeTask)
    }
    
    // Consistent reordering logic for all task views
    private func reorderTasks(from: Int, to: Int) {
        guard from < tasks.count else { return }
        
        // Safe array operations
        var taskArray = tasks
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
        
        // Update the parent project's modification date if applicable
        if let project = project ?? taskToMove.project {
            project.modifiedAt = Date()
        }
        
        // Notify UI to refresh
        NotificationCenter.default.post(
            name: NSNotification.Name.NSManagedObjectContextDidSave,
            object: viewContext
        )
        
        // Debug logging
        print("✅ Reordered tasks in \(title)")
    }
}
