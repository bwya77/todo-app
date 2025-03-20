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
    @State private var showLoggedItems: Bool = false
    @State private var activeTask: Item?
    @State private var taskUpdateCounter: Int = 0
    
    // Task lists using optimized fetch requests
    @FetchRequest private var activeTasks: FetchedResults<Item>
    @FetchRequest private var loggedTasks: FetchedResults<Item>
    
    // Initialize with context
    init(context: NSManagedObjectContext) {
        self._taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
        
        // Initialize fetch requests using the InboxTasksRequest helpers
        self._activeTasks = FetchRequest(fetchRequest: InboxTasksRequest.inboxTasksRequest())
        self._loggedTasks = FetchRequest(fetchRequest: InboxTasksRequest.completedTasksRequest())
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
            if activeTasks.isEmpty && loggedTasks.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Active tasks with reordering
                        UnifiedTaskListView(
                            viewType: .inbox,
                            title: "Inbox",
                            tasks: Array(activeTasks),
                            project: nil,
                            activeTask: $activeTask,
                            onToggleComplete: toggleTaskCompletion,
                            onDeleteTask: { task in
                                withAnimation {
                                    taskViewModel.deleteTask(task)
                                    taskUpdateCounter += 1
                                }
                            }
                        )
                        
                        // Logged tasks section
                        if !loggedTasks.isEmpty {
                            CompletedTasksToggle(isExpanded: $showLoggedItems, itemCount: loggedTasks.count)
                                .padding(.horizontal, 4)
                                .padding(.top, 8)
                                
                            if showLoggedItems {
                                ForEach(loggedTasks) { task in
                                    TaskRow(task: task, onToggleComplete: toggleTaskCompletion, viewType: .inbox)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .id("inbox-detail-view")
        .onAppear {
            // Reset UI states
            showLoggedItems = false
            
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
        let wasCompleted = task.completed
        
        // Simply toggle the task state
        taskViewModel.toggleTaskCompletion(task)
        
        // If task is being completed, schedule to be logged after delay
        if !wasCompleted {
            if let taskId = task.id {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    // Verify task still exists and is still completed
                    let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", taskId as CVarArg)
                    
                    do {
                        if let updatedTask = try self.viewContext.fetch(fetchRequest).first,
                           updatedTask.completed && !updatedTask.logged {
                            
                            // Animate the task to logged section
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                self.taskViewModel.markTaskAsLogged(updatedTask)
                                self.taskUpdateCounter += 1
                            }
                        }
                    } catch {
                        print("Error handling task logging: \(error)")
                    }
                }
            }
        }
        
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

// Reuse CompletedTasksToggle from ProjectTasksView
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
