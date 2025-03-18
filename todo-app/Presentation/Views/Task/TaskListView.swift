//
//  TaskListView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//  Refactored according to improvement plan on 3/7/25.
//

import SwiftUI
import CoreData
import AppKit
import Combine

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taskViewModel: TaskViewModel
    
    @FetchRequest private var tasks: FetchedResults<Item>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Project.name, ascending: true)])
    private var projects: FetchedResults<Project>
    
    @State private var showingAddTask = false
    @State private var showingAddTaskPopup = false
    @State private var newTaskProject: Project?
    
    // This is used for animations
    @State private var animatePopup = false
    
    var viewType: ViewType
    var selectedProject: Project?
    var title: String
    
    init(viewType: ViewType, selectedProject: Project?, context: NSManagedObjectContext) {
        self.viewType = viewType
        self.selectedProject = selectedProject
        self._taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
        
        var title = "Tasks"
        var predicate: NSPredicate?
        
        // Create a fetch request based on view type
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        switch viewType {
        case .inbox:
            title = "Inbox"
            predicate = NSPredicate(format: "project == nil")
            
        case .today:
            title = "Today"
            let startOfDay = Calendar.current.startOfDay(for: Date())
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@", startOfDay as NSDate, endOfDay as NSDate)
            
        case .upcoming:
            title = "Upcoming"
            let startOfDay = Calendar.current.startOfDay(for: Date())
            predicate = NSPredicate(format: "dueDate >= %@", startOfDay as NSDate)
            
        case .completed:
            title = "Completed"
            predicate = NSPredicate(format: "completed == YES")
            
        case .filters:
            title = "Filters & Labels"
            // No specific filter for now
            
        case .project:
            if let project = selectedProject {
                title = project.name ?? "Project"
                predicate = NSPredicate(format: "project == %@", project)
            }
        }
        
        // Set predicate and sort
        request.predicate = predicate
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false),
            NSSortDescriptor(keyPath: \Item.title, ascending: true)
        ]
        
        self._tasks = FetchRequest(fetchRequest: request)
        self.title = title
    }
    
    @State private var expandedGroups: Set<String> = ["Default"]
    
    func groupTasks() -> [String: [Item]] {
        var groups: [String: [Item]] = [:]
        
        for task in tasks {
            let groupName = task.project?.name ?? "Default"
            if groups[groupName] == nil {
                groups[groupName] = []
            }
            groups[groupName]?.append(task)
        }
        
        return groups
    }
    
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
                    
                    // Tasks list grouped by project
                    List {
                        ForEach(groupTasks().keys.sorted(), id: \.self) { groupName in
                            if let groupTasks = groupTasks()[groupName] {
                                Section {
                                    // Only show tasks content if the group is expanded
                                    if expandedGroups.contains(groupName) {
                                        ForEach(groupTasks) { task in
                                            TaskRow(task: task, onToggleComplete: toggleTaskCompletion, viewType: viewType)
                                                .contextMenu {
                                                    Button(action: {
                                                        if let index = groupTasks.firstIndex(of: task) {
                                                            deleteTasks(from: groupName, at: IndexSet(integer: index))
                                                        }
                                                    }) {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                        }
                                        .onMove { from, to in
                                            // Handle moving tasks within the group
                                            moveItems(in: groupName, from: from, to: to)
                                        }
                                    }
                                } header: {
                                    Button(action: {
                                        withAnimation {
                                            if expandedGroups.contains(groupName) {
                                                expandedGroups.remove(groupName)
                                            } else {
                                                expandedGroups.insert(groupName)
                                            }
                                        }
                                    }) {
                                            HStack {
                                                Image(systemName: expandedGroups.contains(groupName) ? "chevron.down" : "chevron.right")
                                                    .foregroundColor(.gray)
                                                    .frame(width: 16)
                                                    
                                                if groupName == "Default" {
                                                    Circle()
                                                        .fill(getGroupColor(for: groupName))
                                                        .frame(width: 10, height: 10)
                                                } else if let project = getProjectForGroupName(groupName) {
                                                    ProjectCompletionIndicator(
                                                        project: project,
                                                        size: 10,
                                                        viewContext: viewContext
                                                    )
                                                    // Add a unique ID for this instance to force recreation when project changes
                                                    .id("task-list-indicator-\(project.id?.uuidString ?? UUID().uuidString)")
                                                } else {
                                                    Circle()
                                                        .fill(getGroupColor(for: groupName))
                                                        .frame(width: 10, height: 10)
                                                }
                                                
                                                Text(groupName)
                                                    .fontWeight(.medium)
                                                
                                                Text("\(groupTasks.count) items")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(Color.white)
                                        }
                                        .buttonStyle(PlainButtonStyle())
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
                        AddTaskPopup(taskViewModel: taskViewModel)
                            .environment(\.managedObjectContext, viewContext)
                    }
                }
                .transition(.opacity)
                .zIndex(100)
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
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
    
    private func toggleTaskCompletion(_ task: Item) {
        taskViewModel.toggleTaskCompletion(task)
    }
    
    private func getGroupColor(for groupName: String) -> Color {
        if groupName == "Default" {
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
    
    private func deleteTasks(from group: String, at offsets: IndexSet) {
        let groupTasks = self.groupTasks()[group] ?? []
        withAnimation {
            offsets.map { groupTasks[$0] }.forEach { task in
                taskViewModel.deleteTask(task)
            }
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { tasks[$0] }.forEach { task in
                taskViewModel.deleteTask(task)
            }
        }
    }
    
    private func moveItems(in group: String, from source: IndexSet, to destination: Int) {
        // Get the tasks for this group
        guard var groupTasks = self.groupTasks()[group] else { return }
        
        // Create a mutable copy of the tasks
        var items = groupTasks
        
        // Perform the move operation
        items.move(fromOffsets: source, toOffset: destination)
        
        // Store the new ordering in UserDefaults since we don't have an 'order' property
        // This is a temporary solution until we can update the Core Data model
        var orderDict = UserDefaults.standard.dictionary(forKey: "TaskOrdering") as? [String: Int] ?? [:]
        
        // Update the ordering for each task
        for (index, task) in items.enumerated() {
            if let taskId = task.id?.uuidString {
                orderDict[taskId] = index
            }
        }
        
        // Save the ordering
        UserDefaults.standard.set(orderDict, forKey: "TaskOrdering")
        
        // Save the context for any other changes
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context after reordering: \(error)")
        }
    }
}
