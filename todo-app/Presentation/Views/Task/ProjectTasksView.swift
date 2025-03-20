//
//  ProjectTasksView.swift
//  todo-app
//
//  Created on 3/19/25.
//

import SwiftUI
import CoreData

// Simple inline toggle component for now (no separate file)
private struct CompletedTasksToggle: View {
    @Binding var isExpanded: Bool
    let itemCount: Int
    
    var body: some View {
        Button(action: {
            withAnimation {
                isExpanded.toggle()
            }
        }) {
            HStack {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text("Completed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("(\(itemCount))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ProjectTasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var project: Project
    let onToggleComplete: (Item) -> Void
    
    // Task lists using the optimized fetch request
    @FetchRequest private var activeTasks: FetchedResults<Item>
    @FetchRequest private var loggedTasks: FetchedResults<Item>
    
    // UI state
    @State private var showLoggedItems: Bool = false
    @State private var pendingLoggedTaskIds: [UUID] = []
    @State private var taskUpdateCounter: Int = 0
    @State private var activeTask: Item?
    
    init(project: Project, onToggleComplete: @escaping (Item) -> Void) {
        self.project = project
        self.onToggleComplete = onToggleComplete
        
        // Initialize fetch requests using the helper
        self._activeTasks = FetchRequest(fetchRequest: ProjectTasksRequest.activeTasksRequest(for: project))
        self._loggedTasks = FetchRequest(fetchRequest: ProjectTasksRequest.loggedTasksRequest(for: project))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Empty state
            if activeTasks.isEmpty && loggedTasks.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Active tasks with reordering
                        ReorderableTaskList(
                            tasks: activeTasks,
                            onToggleComplete: onToggleComplete,
                            projectId: project.id,
                            activeTask: $activeTask
                        )
                        
                        // Logged tasks section
                        if !loggedTasks.isEmpty {
                            CompletedTasksToggle(isExpanded: $showLoggedItems, itemCount: loggedTasks.count)
                                .padding(.horizontal, 4)
                                .padding(.top, 8)
                                
                            if showLoggedItems {
                                ForEach(loggedTasks) { task in
                                    TaskRow(task: task, onToggleComplete: onToggleComplete)
                                        .id("logged-task-\(task.id?.uuidString ?? UUID().uuidString)")
                                        .opacity(0.7)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .animation(nil, value: taskUpdateCounter)
                    .animation(.easeInOut(duration: 0.3), value: showLoggedItems)
                }
                .background(Color.white)
            }
        }
        .onAppear {
            // Reset pending tasks state
            pendingLoggedTaskIds.removeAll()
            
            // Verify logged items are collapsed by default
            showLoggedItems = false
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text("No tasks in this project")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Add a task to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                showAddTaskPopup()
            }) {
                Text("Add Task")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.getColor(from: project.color).opacity(0.2))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // Show add task popup
    private func showAddTaskPopup() {
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowAddTaskPopup"),
            object: nil,
            userInfo: ["project": project]
        )
    }
}
