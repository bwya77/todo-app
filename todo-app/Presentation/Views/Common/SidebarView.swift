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
import AppKit

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
        .environment(\.isEnabled, true) // Force enabled state regardless of app focus
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
            if isPressed {
                if let projectColor = projectColor {
                    // Use a very light shade of the project color for hover
                    return AppColors.lightenColor(projectColor, by: 0.9)
                } else {
                    // Standard hover color for non-project items
                    return AppColors.sidebarHover
                }
            } else {
                return Color.clear
            }
        }
    }
}

struct SidebarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taskViewModel: TaskViewModel
    
    // SidebarView FetchRequest for projects (replaced by ReorderableProjectList)
    // This is still needed to maintain task counts, but we don't display these directly
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.name, ascending: true)],
        animation: .default)
    private var projects: FetchedResults<Project>
    
    // FetchRequest for areas
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Area.displayOrder, ascending: true)],
        animation: .default)
    private var areas: FetchedResults<Area>
    
    // Cache for task counts to improve performance
    @State private var projectTaskCounts: [UUID: Int] = [:]
    @State private var areaTaskCounts: [UUID: Int] = [:]
    @State private var inboxTaskCount: Int = 0
    @State private var todayTaskCount: Int = 0
    
    // For debouncing count updates
    private let debounceInterval: DispatchTimeInterval = .milliseconds(300)
    @State private var lastUpdateTime: Date = Date()
    @Binding var selectedViewType: ViewType
    @Binding var selectedProject: Project?
    @Binding var selectedArea: Area?
    
    // Reference to ContentView for showing popup
    var onShowTaskPopup: () -> Void
    
    // No longer need state variables for popup since it's handled by ContentView
    
    init(selectedViewType: Binding<ViewType>, selectedProject: Binding<Project?>, selectedArea: Binding<Area?>, context: NSManagedObjectContext, onShowTaskPopup: @escaping () -> Void) {
        self._selectedViewType = selectedViewType
        self._selectedProject = selectedProject
        self._selectedArea = selectedArea
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
        
        // Update area counts
        for area in areas {
            if let areaId = area.id {
                let count = taskViewModel.getAreaTaskCount(area: area)
                areaTaskCounts[areaId] = count
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
                                Label("Inbox", systemImage: selectedViewType == .inbox ? "tray.full.fill" : "tray")
                                    .font(.system(size: 14))
                                    .imageScale(.medium)
                                    .foregroundStyle(selectedViewType == .inbox ? AppColors.selectedTextColor : .black)
                                Spacer()
                                if inboxTaskCount > 0 {
                                    Text("\(inboxTaskCount)")
                                        .foregroundColor(selectedViewType == .inbox ? AppColors.selectedTextColor : .secondary)
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
                                    // Get the current day number and use it in the square icon
                                    let dayNumber = Calendar.current.component(.day, from: Date())
                                    Image(systemName: selectedViewType == .today ? "\(dayNumber).square.fill" : "\(dayNumber).square")
                                        .font(.system(size: 16)) // Increased from 14 to 16 for better visibility
                                        .imageScale(.medium)     // Added imageScale to match other icons
                                        .foregroundStyle(selectedViewType == .today ? AppColors.selectedTextColor : .black)
                                }
                                .font(.system(size: 14))
                                Spacer()
                                if todayTaskCount > 0 {
                                    Text("\(todayTaskCount)")
                                        .foregroundColor(selectedViewType == .today ? AppColors.selectedTextColor : .secondary)
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
                                Label("Upcoming", systemImage: selectedViewType == .upcoming ? "calendar.badge.clock" : "calendar")
                                    .font(.system(size: 14))
                                    .imageScale(.medium)
                                    .foregroundStyle(selectedViewType == .upcoming ? AppColors.selectedTextColor : .black)
                            }
                        }
                        .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .upcoming))
                        
                        Button(action: {
                            selectedViewType = .filters
                            selectedProject = nil
                        }) {
                            HStack {
                                Label("Filters & Labels", systemImage: selectedViewType == .filters ? "tag.fill" : "tag")
                                    .font(.system(size: 14))
                                    .imageScale(.medium)
                                    .foregroundStyle(selectedViewType == .filters ? AppColors.selectedTextColor : .black)
                            }
                        }
                        .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .filters))
                        
                        Button(action: {
                            selectedViewType = .completed
                            selectedProject = nil
                        }) {
                            HStack {
                                Label("Completed", systemImage: selectedViewType == .completed ? "checkmark.circle.fill" : "checkmark.circle")
                                    .font(.system(size: 14))
                                    .imageScale(.medium)
                                    .foregroundStyle(selectedViewType == .completed ? AppColors.selectedTextColor : .black)
                            }
                        }
                        .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .completed))
                    }
                    
                    Spacer().frame(height: 24)
                    
                    Group {
                        // Custom ReorderableForEach for projects with selection bindings
                        // We're now including both areas and projects in a single list
                        ReorderableProjectList(
                            selectedViewType: $selectedViewType,
                            selectedProject: $selectedProject,
                            selectedArea: $selectedArea
                        )
                        // Don't apply any global animation modifier here - animation is handled internally now
                        
                        // Project buttons only - removed the Add Project button
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
                showListCreationPopup()
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
        // Note: Instead of using an overlay here, we'll post a notification to show the popup from ContentView
    }
    
    // Show the list creation popup by posting a notification to ContentView
    private func showListCreationPopup() {
        // Post notification for ContentView to show the list creation popup
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowListCreationPopup"),
            object: nil
        )
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

// CalendarDayIcon has been replaced with dynamic day.square icons
