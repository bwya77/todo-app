//
//  ReorderableTaskSection.swift
//  todo-app
//
//  Created on 3/19/25.
//

import SwiftUI
import CoreData

/// A reorderable version of the task section view 
struct ReorderableTaskSection: View {
    // MARK: - Properties
    
    let section: Int
    let title: String
    let tasks: [Item]
    
    @Binding var expandedGroups: Set<String>
    @Binding var activeTask: Item?
    @Binding var dropTargetId: UUID?
    
    let onToggleComplete: (Item) -> Void
    let onDeleteTask: (Item) -> Void
    let onMoveTask: (IndexSet, Int, Int) -> Void
    
    let viewType: ViewType
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Project.name, ascending: true)])
    private var projects: FetchedResults<Project>
    
    init(section: Int, title: String, tasks: [Item], expandedGroups: Binding<Set<String>>, activeTask: Binding<Item?>, dropTargetId: Binding<UUID?>, onToggleComplete: @escaping (Item) -> Void, onDeleteTask: @escaping (Item) -> Void, onMoveTask: @escaping (IndexSet, Int, Int) -> Void, viewType: ViewType) {
        self.section = section
        self.title = title
        self.tasks = tasks
        self._expandedGroups = expandedGroups
        self._activeTask = activeTask
        self._dropTargetId = dropTargetId
        self.onToggleComplete = onToggleComplete
        self.onDeleteTask = onDeleteTask
        self.onMoveTask = onMoveTask
        self.viewType = viewType
    }
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom disclosure header
            Button(action: {
                withAnimation {
                    if expandedGroups.contains(title) {
                        expandedGroups.remove(title)
                    } else {
                        expandedGroups.insert(title)
                    }
                }
            }) {
                HStack {
                    Image(systemName: expandedGroups.contains(title) ? "chevron.down" : "chevron.right")
                        .foregroundColor(.gray)
                        .frame(width: 16)
                        
                    if title == "Default" || title == "No Project" {
                        Circle()
                            .fill(getGroupColor(for: title))
                            .frame(width: 10, height: 10)
                    } else if let project = getProjectForGroupName(title) {
                        ProjectCompletionIndicator(
                            project: project,
                            size: 10,
                            viewContext: viewContext
                        )
                        // Add a unique ID for this instance
                        .id("task-list-indicator-\(project.id?.uuidString ?? UUID().uuidString)")
                    } else {
                        Circle()
                            .fill(getGroupColor(for: title))
                            .frame(width: 10, height: 10)
                    }
                    
                    Text(title)
                        .fontWeight(.medium)
                    
                    Text("\(tasks.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Tasks content with reorderable support
            if expandedGroups.contains(title) {
                // Use the unified task list for consistent behavior across all views
                UnifiedTaskListView(
                viewType: viewType,
                title: title,
                tasks: tasks,
                project: getProjectForGroupName(title),
                activeTask: $activeTask,
                onToggleComplete: onToggleComplete,
                onDeleteTask: onDeleteTask,
                dropTargetId: $dropTargetId
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getGroupColor(for groupName: String) -> Color {
        if groupName == "Default" || groupName == "No Project" {
            return .red
        } else if let project = getProjectForGroupName(groupName) {
            return AppColors.getColor(from: project.color)
        } else {
            return .gray
        }
    }
    
    /// Helper method to get project object by its name
    /// - Parameter groupName: The name of the project group
    /// - Returns: The Project instance if found, nil otherwise
    private func getProjectForGroupName(_ groupName: String) -> Project? {
        return projects.first(where: { $0.name == groupName })
    }
}
