//
//  CompletedDetailView.swift
//  todo-app
//
//  Created on 3/20/25.
//

import SwiftUI
import CoreData

/// Dedicated view for Completed tasks, mirroring the InboxDetailView structure
struct CompletedDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taskViewModel: TaskViewModel
    
    // UI states
    @State private var activeTask: Item?
    @State private var taskUpdateCounter: Int = 0
    
    // Task lists using optimized fetch requests
    @FetchRequest private var completedTasks: FetchedResults<Item>
    
    // Initialize with context
    init(context: NSManagedObjectContext) {
        self._taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
        
        // Initialize fetch requests using TaskFetchRequestFactory
        let fetchRequest = TaskFetchRequestFactory.completedTasks(in: context)
        self._completedTasks = FetchRequest(fetchRequest: fetchRequest)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Completed header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    // Completed icon matching the sidebar
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                    
                    Text("Completed")
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
            if completedTasks.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Completed tasks with reordering
                        UnifiedTaskListView(
                            viewType: .completed,
                            title: "Completed",
                            tasks: Array(completedTasks),
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
        .id("completed-detail-view")
        .onAppear {
            // Ensure completed tasks have display order initialized
            InitializeDisplayOrderMigration.initializeCompletedDisplayOrder(in: viewContext)
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text("No completed tasks")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Completed tasks will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // Task completion toggle with animations
    private func toggleTaskCompletion(_ task: Item) {
        // Toggle the task state
        taskViewModel.toggleTaskCompletion(task)
        taskUpdateCounter += 1
    }
}
