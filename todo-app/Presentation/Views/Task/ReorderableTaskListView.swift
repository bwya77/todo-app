//
//  ReorderableTaskListView.swift
//  todo-app
//
//  Created on 3/19/25.
//

import SwiftUI
import CoreData
import AppKit
import Combine

/// A version of the task list view that supports drag and drop reordering
struct ReorderableTaskListView: View {
    // MARK: - Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: EnhancedTaskViewModel
    
    @State private var showingAddTask = false
    @State private var showingAddTaskPopup = false
    @State private var newTaskProject: Project?
    
    // State for drag and drop
    @State private var activeTask: Item?
    
    // This is used for animations
    @State private var animatePopup = false
    
    var viewType: ViewType
    var selectedProject: Project?
    var title: String
    
    @State private var expandedGroups: Set<String> = ["Default"]
    
    // MARK: - Initialization
    
    init(viewType: ViewType, selectedProject: Project?, context: NSManagedObjectContext) {
        self.viewType = viewType
        self.selectedProject = selectedProject
        
        // Determine title based on view type
        var title = "Tasks"
        
        switch viewType {
        case .inbox:
            title = "Inbox"
        case .today:
            title = "Today"
        case .upcoming:
            title = "Upcoming"
        case .completed:
            title = "Completed"
        case .filters:
            title = "Filters & Labels"
        case .project:
            if let project = selectedProject {
                title = project.name ?? "Project"
            }
        }
        
        self.title = title
        
        // Initialize view model
        self._viewModel = StateObject(wrappedValue: EnhancedTaskViewModel(context: context))
    }
    
    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // Show appropriate detail view based on view type
            if viewType == .project && selectedProject != nil {
                ProjectDetailView(project: selectedProject!, context: viewContext)
            } 
            else if viewType == .inbox {
                InboxDetailView(context: viewContext)
            }
            else if viewType == .today {
                TodayDetailView(context: viewContext)
            }
            else if viewType == .completed {
                CompletedDetailView(context: viewContext)
            } else {
                VStack(spacing: 0) {
                    // Additional whitespace at the top
                    Spacer().frame(height: 24)
                    
                    // Header
                    ReorderableTaskHeaderView(
                        title: title,
                        onReset: viewType == .project ? resetTaskOrder : nil
                    )
                    
                    // Content with sections
                    ReorderableTaskContentView(
                        viewModel: viewModel,
                        expandedGroups: $expandedGroups,
                        activeTask: $activeTask,
                        viewType: viewType
                    )
                }
                .withSaveOrderObserver() // Add auto-save observer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .overlay {
            if showingAddTaskPopup {
                PopupBlurView(isPresented: animatePopup, onDismiss: closePopup) {
                    if animatePopup {
                        AddTaskPopup(taskViewModel: TaskViewModel(context: viewContext))
                            .environment(\.managedObjectContext, viewContext)
                    }
                }
                .transition(.opacity)
                .zIndex(100)
                .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            // Configure the fetch when the view appears
            if viewType == .inbox {
                // For inbox, configure without groupByProject to get a flat list
                viewModel.configureFetch(
                    for: viewType,
                    project: nil,
                    groupByProject: false
                )
            } else {
                // For other views, use normal configuration
                viewModel.configureFetch(
                    for: viewType,
                    project: selectedProject,
                    groupByProject: viewType != .project // Group by project except when in project view
                )
            }
            
            // Set Default as the initially expanded group
            expandedGroups.insert("Default")
            
            // Also expand the current project group if in project view
            if viewType == .project, let projectName = selectedProject?.name {
                expandedGroups.insert(projectName)
            }
        }
        .onDisappear {
            // Ensure task ordering is saved when navigating away from this view
            viewModel.persistCurrentTaskOrder()
        }
    }
    
    // MARK: - Helper Methods
    
    private func closePopup() {
        // Animate the popup closing
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            animatePopup = false
            
            // Give it time to animate out before removing from view hierarchy
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingAddTaskPopup = false
            }
        }
    }
    
    // Emergency function to reset task order if things get corrupted
    private func resetTaskOrder() {
        if viewType == .project, let project = selectedProject {
            print("🆘 Emergency reset of task order for project: \(project.name ?? "Unknown")")
            TaskOrderDebugger.resetTaskOrder(for: project, in: viewContext)
            // Force refresh
            viewModel.refreshFetch()
        } else if viewType == .inbox {
            print("🆘 Emergency reset of task order for Inbox")
            // Initialize display order for all inbox tasks
            InitializeDisplayOrderMigration.initializeInboxDisplayOrder(in: viewContext)
            // Force refresh
            viewModel.refreshFetch()
        }
    }
}
