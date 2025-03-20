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
    
    // Use binding instead of local state for drag operation
    @Binding var activeTask: Item?
    
    // Initialize with binding
    init(tasks: FetchedResults<Item>, onToggleComplete: @escaping (Item) -> Void, projectId: UUID?, activeTask: Binding<Item?>) {
        self.tasks = tasks
        self.onToggleComplete = onToggleComplete
        self.projectId = projectId
        self._activeTask = activeTask
    }
    
    var body: some View {
        // Use our unified task list for consistent behavior
        UnifiedTaskListView(
            viewType: .project,
            title: "Project Tasks",
            tasks: Array(tasks),
            project: tasks.first?.project,
            activeTask: $activeTask,
            onToggleComplete: onToggleComplete,
            onDeleteTask: nil
        )
    }
}
