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
    @FetchRequest private var unheaderedTasks: FetchedResults<Item>
    @FetchRequest private var loggedTasks: FetchedResults<Item>
    @FetchRequest private var headers: FetchedResults<ProjectHeader>
    
    // UI state
    @State private var showLoggedItems: Bool = false
    @State private var pendingLoggedTaskIds: [UUID] = []
    @State private var taskUpdateCounter: Int = 0
    @State private var activeTask: Item?
    @State private var activeHeader: ProjectHeader?
    
    // Tracking which headers are expanded (by default all are expanded)
    @State private var expandedHeaders: Set<UUID> = Set()
    
    // Track a single global drop target
    @State private var dropTargetId: UUID?
    
    init(project: Project, onToggleComplete: @escaping (Item) -> Void) {
        self.project = project
        self.onToggleComplete = onToggleComplete
        
        // Initialize fetch requests for unheadered tasks (tasks not in any header)
        let unheaderedRequest: NSFetchRequest<Item> = Item.fetchRequest()
        unheaderedRequest.predicate = NSPredicate(format: "project == %@ AND header == nil AND (completed == NO OR (completed == YES AND logged == NO))", project)
        unheaderedRequest.sortDescriptors = [
            NSSortDescriptor(key: "displayOrder", ascending: true)
        ]
        self._unheaderedTasks = FetchRequest(fetchRequest: unheaderedRequest)
        
        // Fetch logged tasks
        self._loggedTasks = FetchRequest(fetchRequest: ProjectTasksRequest.loggedTasksRequest(for: project))
        
        // Fetch headers
        self._headers = FetchRequest(fetchRequest: ProjectHeadersRequest.headersRequest(for: project))
    }
    
    // MARK: - Main View Structure
    
    var body: some View {
        mainContentView
    }
    
    // MARK: - Content Views
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Empty state
            if unheaderedTasks.isEmpty && headers.isEmpty && loggedTasks.isEmpty {
                emptyStateView
            } else {
                taskListView
            }
        }
        .onAppear(perform: setupOnAppear)
    }
    
    private var taskListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Add header button
                AddHeaderButton(project: project)
                    .padding(.bottom, 4)
                    // Hide the plus sign
                    .opacity(activeTask != nil ? 0 : 1)
                
                // Tasks without headers section
                unheaderedTasksSection
                
                // Headers with tasks
                if !headers.isEmpty {
                    headersList
                }
                
                // Logged tasks section
                loggedTasksSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .animation(nil, value: taskUpdateCounter)
            .animation(.easeInOut(duration: 0.3), value: showLoggedItems)
        }
        .background(Color.white)
    }
    
    // Unheadered tasks section
    private var unheaderedTasksSection: some View {
        VStack {
            if !unheaderedTasks.isEmpty {
                unheaderedTasksList
            } else {
                // Empty placeholder for dropping tasks
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 40)
                    .contentShape(Rectangle())
            }
        }
        // Make the entire unheadered section a drop target
        .onDrop(of: [.text], isTargeted: nil) { providers, _ in
            // Set this as the drop target 
            if activeTask != nil {
                self.dropTargetId = nil // This is unheadered section - use nil for dropTargetId 
            }
            return handleUnheaderedTaskDrop(providers: providers)
        }
    }
    
    // MARK: - Unheadered Tasks List

    private var unheaderedTasksList: some View {
        ReorderableForEach(
            Array(unheaderedTasks),
            active: $activeTask,
            dropTarget: $dropTargetId,
            content: { task in
                TaskRow(task: task, onToggleComplete: onToggleComplete)
                    .id("task-\(task.id?.uuidString ?? UUID().uuidString)")
                    .contentShape(Rectangle())
                    .padding(.vertical, 2)
                    .background(Color.white)
                    .scaleEffect(activeTask == task ? 1.03 : 1.0)
                    .shadow(color: activeTask == task ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: activeTask == task ? 2 : 0)
                    .zIndex(activeTask == task ? 1 : 0)
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1), value: activeTask)
            },
            moveAction: { fromOffsets, toOffset in
                reorderUnheaderedTasks(from: fromOffsets.first ?? 0, to: toOffset)
            }
        )
        .reorderableForEachContainer(active: $activeTask, dropTarget: $dropTargetId)
    }
    
    // Logged tasks section
    private var loggedTasksSection: some View {
        Group {
            if !loggedTasks.isEmpty {
                VStack(spacing: 0) {
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
        }
    }
    
    // Setup the view when it appears
    private func setupOnAppear() {
        // Reset pending tasks state
        pendingLoggedTaskIds.removeAll()
        
        // Verify logged items are collapsed by default
        showLoggedItems = false
        
        // Set all headers as expanded by default
        expandedHeaders.removeAll()
        for header in headers {
            if let id = header.id {
                expandedHeaders.insert(id)
            }
        }
    }
    
    // Headers list with drag/drop support
    private var headersList: some View {
        VStack(spacing: 8) {
            ForEach(Array(headers), id: \.id) { header in
                VStack(spacing: 0) {
                    // Use the updated ProjectHeaderView with activeTask binding
                    ProjectHeaderView(header: header, expandedHeaders: $expandedHeaders, activeTask: $activeTask, dropTargetId: $dropTargetId)
                    
                    // Tasks under this header with expanded/collapsed support
                    HeaderTasksView(
                        header: header, 
                        onToggleComplete: onToggleComplete, 
                        activeTask: $activeTask,
                        expandedHeaders: $expandedHeaders,
                        dropTargetId: $dropTargetId
                    )
                }
            }
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            // Add padding at top to match non-empty projects
            Spacer().frame(height: 8)
            
            // Add header button - exactly like in non-empty projects
            AddHeaderButton(project: project)
                .padding(.horizontal, 16)
            
            Spacer().frame(height: 16) // Space between add header and empty state message
            
            VStack(spacing: 16) {
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
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            
            Spacer()
        }
    }
    
    // Show add task popup
    private func showAddTaskPopup() {
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowAddTaskPopup"),
            object: nil,
            userInfo: ["project": project]
        )
    }
    
    // Reorder unheadered tasks
    private func reorderUnheaderedTasks(from: Int, to: Int) {
        guard from < unheaderedTasks.count else { return }
        
        // Safe array operations
        var taskArray = Array(unheaderedTasks)
        let safeFrom = min(from, taskArray.count - 1)
        let taskToMove = taskArray.remove(at: safeFrom)
        
        // Safe insertion
        let safeTo = min(to, taskArray.count)
        taskArray.insert(taskToMove, at: safeTo)
        
        // Update display order with spacing for future insertions
        for (index, task) in taskArray.enumerated() {
            task.setValue(Int32(index * 10), forKey: "displayOrder")
        }
        
        // Ensure changes are saved to disk
        PersistentOrder.save(context: viewContext)
        
        // Update the project's modification date
        project.modifiedAt = Date()
    }
    
    // Delete header
    private func deleteHeader(_ header: ProjectHeader) {
        // First move all tasks in this header to no header
        if let project = header.project {
            let tasks = header.tasks()
            project.moveTasks(tasks, toHeader: nil, save: false)
        }
        
        // Delete header
        viewContext.delete(header)
        try? viewContext.save()
    }
    
    // Handle drop of a task onto the unheadered tasks section
    private func handleUnheaderedTaskDrop(providers: [NSItemProvider]) -> Bool {
        guard let activeTask = activeTask else { return false }
        
        // Clear drop target on drop
        dropTargetId = nil
        
        // Safety check - if the task already has no header, just update order
        if activeTask.header == nil {
            // Move to the end of the unheadered tasks
            let taskArray = Array(unheaderedTasks)
            if let index = taskArray.firstIndex(of: activeTask) {
                reorderUnheaderedTasks(from: index, to: taskArray.count)
            }
            return true
        }
        
        // Move the task out of its current header
        activeTask.header = nil
        
        // Update display order to be at the end of unheadered tasks
        let tasksWithoutHeader = project.tasksWithoutHeader()
        activeTask.displayOrder = tasksWithoutHeader.isEmpty ? 0 : (tasksWithoutHeader.map { $0.displayOrder }.max() ?? 0) + 10
        
        // Save changes
        do {
            try viewContext.save()
            
            // Reset active task
            self.activeTask = nil
            return true
        } catch {
            print("Error moving task to unheadered section: \(error)")
            return false
        }
    }
    
    // Reorder headers (unused but kept for future reference)
    private func reorderHeaders(from: Int, to: Int) {
        guard from < headers.count else { return }
        
        // Use the ProjectHeader reordering function
        ProjectHeader.reorderHeaders(
            from: from,
            to: to,
            headers: Array(headers),
            context: viewContext
        )
        
        // Update the project's modification date
        project.modifiedAt = Date()
    }
}
