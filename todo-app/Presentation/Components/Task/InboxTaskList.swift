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
    
    // Use binding for active task to maintain drag state
    @Binding var activeTask: Item?
    
    var body: some View {
        // Use the UnifiedTaskListView for consistent behavior with Projects
        UnifiedTaskListView(
            viewType: .inbox,
            title: "Inbox",
            tasks: tasks,
            project: nil, // Inbox tasks don't have a project
            activeTask: $activeTask,
            onToggleComplete: onToggleComplete,
            onDeleteTask: onDeleteTask
        )
        .onAppear {
            // Reset active task when view appears
            activeTask = nil
        }
    }
}
