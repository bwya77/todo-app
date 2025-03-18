//
//  EnhancedTaskListView.swift
//  todo-app
//
//  Created on 3/13/25.
//

import SwiftUI
import CoreData
import AppKit
import Combine

/// An enhanced version of TaskListView that uses NSFetchedResultsController for improved performance
struct EnhancedTaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: EnhancedTaskViewModel
    
    @State private var showingAddTask = false
    @State private var showingAddTaskPopup = false
    @State private var newTaskProject: Project?
    
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
            // When in project mode, show the project detail view
            if viewType == .project && selectedProject != nil {
                ProjectDetailView(project: selectedProject!, context: viewContext)
            } else {
                VStack(spacing: 0) {
                    // Additional whitespace at the top
                    Spacer().frame(height: 24)
                    
                    // Header
                    HStack {
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .padding(.bottom, 8)
                    
                    // Tasks list grouped by section
                    List {
                        // Break up complex expressions to help compiler
                        ForEach(0..<viewModel.numberOfSections, id: \.self) { section in
                            let sectionTitle = viewModel.titleForSection(section)
                            let sectionTasks = viewModel.tasksForSection(section)
                            let isExpanded = expandedGroups.contains(sectionTitle)
                            
                            Section(
                                header: createSectionHeader(title: sectionTitle, isExpanded: isExpanded, itemCount: sectionTasks.count)
                            ) {
                                if isExpanded {
                                    // Task rows
                                    createTaskRows(tasks: sectionTasks, section: section)
                                }
                            }
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .background(Color.white)
                }
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
            viewModel.configureFetch(
                for: viewType,
                project: selectedProject,
                groupByProject: viewType != .project // Group by project except when in project view
            )
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
    
    // Helper methods to break up complex expressions for the compiler
    
    @ViewBuilder
    private func createSectionHeader(title: String, isExpanded: Bool, itemCount: Int) -> some View {
        Button(action: {
            withAnimation {
                if expandedGroups.contains(title) {
                    expandedGroups.remove(title)
                } else {
                    expandedGroups.insert(title)
                }
            }
        }) {
            SectionHeaderView(
                title: title, 
                isExpanded: isExpanded,
                itemCount: itemCount,
                viewContext: viewContext
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func createTaskRows(tasks: [Item], section: Int) -> some View {
        ForEach(tasks) { task in
            TaskRow(task: task, onToggleComplete: { _ in viewModel.toggleTaskCompletion(task) }, viewType: viewType)
                .contextMenu {
                    Button(action: {
                        viewModel.deleteTask(task)
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
        .onMove { source, destination in
            viewModel.moveItems(in: section, from: source, to: destination)
        }
    }
}

// MARK: - Section View

/// A view representing a section of tasks
struct SectionView: View {
    let section: Int
    let title: String
    let tasks: [Item]
    @Binding var expandedGroups: Set<String>
    let onToggleComplete: (Item) -> Void
    let onDeleteTask: (Item) -> Void
    let viewType: ViewType
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Project.name, ascending: true)])
    private var projects: FetchedResults<Project>
    
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
                        // Add a unique ID for this instance to force recreation when project changes
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
            
            // Tasks content
            if expandedGroups.contains(title) {
                ForEach(tasks) { task in
                    TaskRow(task: task, onToggleComplete: onToggleComplete, viewType: viewType)
                        .contextMenu {
                            Button(action: {
                                onDeleteTask(task)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
    
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
