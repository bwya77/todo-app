//
//  InboxDetailView.swift
//  todo-app
//
//  Created on 3/20/25.
//

import SwiftUI
import CoreData

/// Dedicated view for the Inbox tasks, mirroring the ProjectDetailView structure
struct InboxDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taskViewModel: TaskViewModel
    
    // UI states
    @State private var activeTask: Item?
    @State private var taskUpdateCounter: Int = 0
    @State private var dropTargetId: UUID?
    
    // Task list using optimized fetch request
    @FetchRequest private var inboxTasks: FetchedResults<Item>
    
    // Initialize with context
    init(context: NSManagedObjectContext) {
        self._taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
        
        // Initialize fetch request using the InboxTasksRequest helper
        let request = InboxTasksRequest.inboxTasksRequest()
        // Add predicate to exclude completed tasks
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "project == nil"),
            NSPredicate(format: "completed == NO")
        ])
        
        self._inboxTasks = FetchRequest(fetchRequest: request)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Inbox header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    // Inbox icon matching the sidebar
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.inboxColor)
                    
                    Text("Inbox")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.primary)
                }
                .padding(.vertical, 8)
                
                Spacer()
                    .frame(height: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 8)
            .background(Color.white)
            
            // Divider after title
            CustomDivider()
                .padding(.horizontal, 16)
                .padding(.bottom, 0)
            
            // Tasks content
            if inboxTasks.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Inbox tasks with reordering
                        UnifiedTaskListView(
                            viewType: .inbox,
                            title: "Inbox",
                            tasks: Array(inboxTasks),
                            project: nil,
                            activeTask: $activeTask,
                            onToggleComplete: toggleTaskCompletion,
                            onDeleteTask: { task in
                                withAnimation {
                                    taskViewModel.deleteTask(task)
                                    taskUpdateCounter += 1
                                }
                            },
                            dropTargetId: $dropTargetId
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .animation(nil, value: taskUpdateCounter)
                }
                .background(Color.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .id("inbox-detail-view")
        .onAppear {
            // Ensure inbox tasks have display order initialized
            InitializeDisplayOrderMigration.initializeInboxDisplayOrder(in: viewContext)
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text("No tasks in your Inbox")
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
                    .background(AppColors.inboxColor.opacity(0.2))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // Task completion toggle with animations
    private func toggleTaskCompletion(_ task: Item) {
        // Simply toggle the task state
        taskViewModel.toggleTaskCompletion(task)
        
        // Update the counter so it refreshes the view
        taskUpdateCounter += 1
    }
    
    // Show add task popup
    private func showAddTaskPopup() {
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowAddTaskPopup"),
            object: nil,
            userInfo: nil
        )
    }
}

