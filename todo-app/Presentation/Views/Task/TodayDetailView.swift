//
//  TodayDetailView.swift
//  todo-app
//
//  Created on 3/20/25.
//

import SwiftUI
import CoreData

/// Dedicated view for Today's tasks, mirroring the InboxDetailView structure
struct TodayDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taskViewModel: TaskViewModel
    
    // UI states
    @State private var activeTask: Item?
    @State private var taskUpdateCounter: Int = 0
    @State private var dropTargetId: UUID?
    
    // Task lists using optimized fetch requests
    @FetchRequest private var todayTasks: FetchedResults<Item>
    
    // Initialize with context
    init(context: NSManagedObjectContext) {
        self._taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
        
        // Initialize fetch requests using the helper from TaskFetchRequestFactory
        self._todayTasks = FetchRequest(fetchRequest: TaskFetchRequestFactory.todayTasks(in: context))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Today header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    // Today icon matching the sidebar
                    let dayNumber = Calendar.current.component(.day, from: Date())
                    Image(systemName: "\(dayNumber).square.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                    
                    Text("Today")
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
            if todayTasks.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Today tasks with reordering
                        UnifiedTaskListView(
                            viewType: .today,
                            title: "Today",
                            tasks: Array(todayTasks),
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
        .id("today-detail-view")
        .onAppear {
            // Ensure today tasks have display order initialized
            InitializeDisplayOrderMigration.initializeTodayDisplayOrder(in: viewContext)
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            let dayNumber = Calendar.current.component(.day, from: Date())
            Image(systemName: "\(dayNumber).square")
                .font(.system(size: 48))
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text("No tasks for today")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Add a task due today to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                showAddTaskPopup()
            }) {
                Text("Add Task")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.2))
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
        
        // If task is being completed, remove it from the list with animation
        if !task.completed { // Check the state after toggling
            // Move the task out of view with animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                taskUpdateCounter += 1
            }
        }
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
