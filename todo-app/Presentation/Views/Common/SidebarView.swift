//
//  SidebarView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//  Refactored according to improvement plan on 3/7/25.
//

import SwiftUI
import CoreData
import Foundation
import Combine
import Dispatch

/// A custom pie chart view for showing progress as a slice with animation
fileprivate struct ProgressPie: View {
    var progress: Double  // 0.0 to 1.0
    var color: Color
    
    // Use a unique ID to force recreation when needed
    let id = UUID()
    
    @StateObject private var animator = CircleProgressAnimator()
    
    var body: some View {
        Canvas { context, size in
            // Define the center and radius of the circle
            let center = CGPoint(x: size.width/2, y: size.height/2)
            let radius = min(size.width, size.height) / 2
            
            // Create a path for the pie slice
            var path = Path()
            path.move(to: center)
            path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(-90) + .degrees(360 * animator.currentProgress), clockwise: false)
            path.closeSubpath()
            
            // Fill the path
            context.fill(path, with: .color(color))
        }
        .id(id) // Force view recreation when the instance is recreated
        .onAppear {
            // Reset animator when view appears (handles reuse)
            animator.reset()
            animator.animateTo(progress)
        }
        .onChange(of: progress) { newValue, _ in
            animator.animateTo(newValue)
        }
    }
}

struct CustomSidebarButtonStyle: ButtonStyle {
    let isSelected: Bool
    var projectColor: Color? = nil
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(backgroundForState(isSelected: isSelected, isPressed: configuration.isPressed))
        .cornerRadius(4)
    }
    
    /// Determines the appropriate background color based on selection state and project color
    /// - Parameters:
    ///   - isSelected: Whether this item is currently selected
    ///   - isPressed: Whether this item is currently being pressed
    /// - Returns: The appropriate background color
    private func backgroundForState(isSelected: Bool, isPressed: Bool) -> Color {
        if isSelected {
            if let projectColor = projectColor {
                // For projects, use a lighter shade of the project color
                return AppColors.lightenColor(projectColor, by: 0.7)
            } else {
                // For standard items, use the blue highlight
                return AppColors.todayHighlight.opacity(0.3)
            }
        } else {
            // For non-selected items, use the hover color when pressed
            return isPressed ? AppColors.sidebarHover : Color.clear
        }
    }
}

struct SidebarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taskViewModel: TaskViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.name, ascending: true)],
        animation: .default)
    private var projects: FetchedResults<Project>
    
    // Cache for task counts to improve performance
    @State private var projectTaskCounts: [UUID: Int] = [:]
    @State private var inboxTaskCount: Int = 0
    @State private var todayTaskCount: Int = 0
    
    // For debouncing count updates
    private let debounceInterval: DispatchTimeInterval = .milliseconds(300)
    @State private var lastUpdateTime: Date = Date()
    @Binding var selectedViewType: ViewType
    @Binding var selectedProject: Project?
    
    // Reference to ContentView for showing popup
    var onShowTaskPopup: () -> Void
    
    @State private var showingAddProject = false
    @State private var newProjectName = ""
    @State private var newProjectColor = "blue"
    
    init(selectedViewType: Binding<ViewType>, selectedProject: Binding<Project?>, context: NSManagedObjectContext, onShowTaskPopup: @escaping () -> Void) {
        self._selectedViewType = selectedViewType
        self._selectedProject = selectedProject
        self._taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
        self.onShowTaskPopup = onShowTaskPopup
    }
    
    // Updates the cache of task counts for better performance
    private func updateTaskCounts() {
        // Update inbox count
        inboxTaskCount = taskViewModel.getInboxTaskCount()
        
        // Update today count
        todayTaskCount = taskViewModel.getTodayTaskCount()
        
        // Update project counts
        for project in projects {
            if let projectId = project.id {
                let count = taskViewModel.getProjectTaskCount(project: project)
                projectTaskCounts[projectId] = count
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: 248/255, green: 250/255, blue: 251/255).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Main list content
                List {
                    // Add top padding to push Inbox lower
                    Spacer().frame(height: 12)
                    
                    Group {
                        Button(action: {
                            selectedViewType = .inbox
                            selectedProject = nil
                        }) {
                            HStack {
                                Label("Inbox", systemImage: "tray")
                                    .font(.system(size: 14))
                                    .imageScale(.medium)
                                    .foregroundStyle(selectedViewType == .inbox ? AppColors.selectedIconColor : .black)
                                Spacer()
                                if inboxTaskCount > 0 {
                                    Text("\(inboxTaskCount)")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                        .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .inbox))
                        
                        Spacer().frame(height: 16)
                        
                        Button(action: {
                            onShowTaskPopup()
                        }) {
                            HStack {
                                Label {
                                    Text("Add task")
                                } icon: {
                                    ZStack {
                                        Circle()
                                            .fill(AppColors.addTaskButtonColor)
                                            .frame(width: 20, height: 20)
                                        Image(systemName: "plus")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    }
                                }
                                .font(.system(size: 14))
                            }
                        }
                        .buttonStyle(CustomSidebarButtonStyle(isSelected: false))
                        .keyboardShortcut("n", modifiers: [.command])
                        
                        Button(action: {
                            selectedViewType = .today
                            selectedProject = nil
                        }) {
                            HStack {
                                Label {
                                    Text("Today")
                                } icon: {
                                    CalendarDayIcon(selected: selectedViewType == .today)
                                }
                                .font(.system(size: 14))
                                Spacer()
                                if todayTaskCount > 0 {
                                    Text("\(todayTaskCount)")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                        .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .today))
                        
                        Button(action: {
                            selectedViewType = .upcoming
                            selectedProject = nil
                        }) {
                            HStack {
                                Label("Upcoming", systemImage: "calendar")
                                    .font(.system(size: 14))
                                    .imageScale(.medium)
                                    .foregroundStyle(selectedViewType == .upcoming ? AppColors.selectedIconColor : .black)
                            }
                        }
                        .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .upcoming))
                        
                        Button(action: {
                            selectedViewType = .filters
                            selectedProject = nil
                        }) {
                            HStack {
                                Label("Filters & Labels", systemImage: "tag")
                                    .font(.system(size: 14))
                                    .imageScale(.medium)
                                    .foregroundStyle(selectedViewType == .filters ? AppColors.selectedIconColor : .black)
                            }
                        }
                        .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .filters))
                        
                        Button(action: {
                            selectedViewType = .completed
                            selectedProject = nil
                        }) {
                            HStack {
                                Label("Completed", systemImage: "checkmark.circle")
                                    .font(.system(size: 14))
                                    .imageScale(.medium)
                                    .foregroundStyle(selectedViewType == .completed ? AppColors.selectedIconColor : .black)
                            }
                        }
                        .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .completed))
                    }
                    
                    Group {
                        Text("Projects")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                        
                        ForEach(projects) { project in
                            Button(action: {
                                selectedViewType = .project
                                selectedProject = project
                            }) {
                                HStack {
                                    Label {
                                        Text(project.name ?? "Unnamed Project")
                                    } icon: {
                                        ProjectCompletionIndicator(
                                            project: project,
                                            isSelected: selectedViewType == .project && selectedProject?.id == project.id,
                                            viewContext: viewContext
                                        )
                                        // Add a unique ID for this instance to force recreation when project changes
                                        .id("sidebar-indicator-\(project.id?.uuidString ?? UUID().uuidString)")
                                    }
                                    Spacer()
                                    let taskCount = projectTaskCounts[project.id ?? UUID()] ?? 0
                                    if taskCount > 0 {
                                        Text("\(taskCount)")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 14))
                                    }
                                }
                            }
                            .buttonStyle(CustomSidebarButtonStyle(
                                isSelected: selectedViewType == .project && selectedProject?.id == project.id,
                                projectColor: AppColors.getColor(from: project.color)
                            ))
                        }
                        .onDelete(perform: deleteProjects)
                        
                        Button(action: {
                            showingAddProject = true
                        }) {
                            HStack {
                                Label("Add Project", systemImage: "plus")
                                    .font(.system(size: 14))
                                    .imageScale(.medium)
                                    .foregroundColor(.black)
                            }
                        }
                        .buttonStyle(CustomSidebarButtonStyle(isSelected: false))
                    }
                }
                .listStyle(SidebarListStyle())
                .scrollContentBackground(.hidden)
                .background(AppColors.sidebarBackground)
                .font(.system(size: 14))
                
                // Bottom Bar with New List button
                VStack(spacing: 0) {
                    Divider().padding(.trailing, -20)  // Extend divider past the right edge
                    HStack {
                        Button(action: {
                            // New list action
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                    .font(.system(size: 14))
                                Text("New List")
                                    .font(.system(size: 14))
                            }
                            .padding(8)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button(action: {
                            // Settings action
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14))
                                .padding(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 36)
                    .background(AppColors.sidebarBackground)
                }
            }
        }
        .onAppear(perform: updateTaskCounts)
        // Observe changes to projects and items to update counts
        .onChange(of: projects.count) { _, _ in 
            updateTaskCounts()
        }
        // Use NotificationCenter to detect Core Data changes with debouncing
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext)) { _ in
            let now = Date()
            if now.timeIntervalSince(lastUpdateTime) > 0.3 { // 300ms
                updateTaskCounts()
                lastUpdateTime = now
            }
        }
        .sheet(isPresented: $showingAddProject) {
            VStack(spacing: 20) {
                Text("Add Project")
                    .font(.headline)
                
                TextField("Project Name", text: $newProjectName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("Color", selection: $newProjectColor) {
                    ForEach(Array(AppColors.colorMap.keys), id: \.self) { colorName in
                        HStack {
                            Circle()
                                .fill(AppColors.colorMap[colorName] ?? .gray)
                                .frame(width: 16, height: 16)
                            Text(colorName.capitalized)
                        }
                        .tag(colorName)
                    }
                }
                
                HStack {
                    Button("Cancel") {
                        showingAddProject = false
                        newProjectName = ""
                    }
                    
                    Spacer()
                    
                    Button("Add") {
                        guard !newProjectName.isEmpty else { return }
                        taskViewModel.addProject(name: newProjectName, color: newProjectColor)
                        newProjectName = ""
                        showingAddProject = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top)
            }
            .padding()
            .frame(width: 300)
        }
    }
    
    private func deleteProjects(offsets: IndexSet) {
        withAnimation {
            offsets.map { projects[$0] }.forEach { project in
                if selectedProject?.id == project.id {
                    selectedProject = nil
                    selectedViewType = .inbox
                }
                taskViewModel.deleteProject(project)
            }
        }
    }
}

struct CalendarDayIcon: View {
    var selected: Bool = false
    
    var body: some View {
        ZStack {
            Image(systemName: "calendar")
                .font(.system(size: 14))
                .foregroundColor(selected ? AppColors.selectedIconColor : .black)
            
            Text(String(Calendar.current.component(.day, from: Date())))
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
                .offset(y: 1)
        }
    }
}
