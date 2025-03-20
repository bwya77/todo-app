//
//  TaskListViewFactory.swift
//  todo-app
//
//  Created on 3/19/25.
//

import SwiftUI
import CoreData

/// Factory to create the appropriate task list view based on feature flags
struct TaskListViewFactory {
    /// Creates the appropriate task list view based on feature flags
    /// - Parameters:
    ///   - viewType: The view type to display
    ///   - selectedProject: Optional selected project
    ///   - context: The managed object context
    /// - Returns: The appropriate task list view
    static func createTaskListView(
        viewType: ViewType,
        selectedProject: Project?,
        context: NSManagedObjectContext
    ) -> some View {
        if true {
            return AnyView(
                ReorderableTaskListView(
                    viewType: viewType,
                    selectedProject: selectedProject,
                    context: context
                )
            )
        } else {
            return AnyView(
                EnhancedTaskListView(
                    viewType: viewType,
                    selectedProject: selectedProject,
                    context: context
                )
            )
        }
    }
}
