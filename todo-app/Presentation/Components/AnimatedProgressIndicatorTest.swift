//
//  AnimatedProgressIndicatorTest.swift
//  todo-app
//
//  Created on 3/11/25.
//

import SwiftUI
import CoreData

/// A test view for the animated progress indicator
struct AnimatedProgressIndicatorTest: View {
    @StateObject private var animator = CircleProgressAnimator()
    @State private var progress: Double = 0.0
    
    // For CoreData testing
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showProjectTest = false
    @State private var testProject: Project?
    @State private var taskCount = 3
    @State private var completedCount = 0
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Animated Progress Indicator Test")
                .font(.title)
                .padding()
            
            TabView {
                // Tab 1: Manual progress testing
                VStack(spacing: 40) {
                    // Progress indicator
                    ZStack {
                        // Track circle
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 30)
                            .frame(width: 200, height: 200)
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0, to: animator.currentProgress)
                            .stroke(Color.blue, lineWidth: 30)
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                        
                        // Percentage text
                        Text("\(Int(animator.currentProgress * 100))%")
                            .font(.title)
                            .bold()
                    }
                    
                    // Progress slider
                    VStack {
                        Text("Progress: \(Int(progress * 100))%")
                        Slider(value: $progress, in: 0...1, step: 0.01)
                            .padding(.horizontal)
                            .onChange(of: progress) { newValue, _ in
                                animator.animateTo(newValue)
                            }
                    }
                    .padding()
                    
                    // Buttons for testing
                    HStack(spacing: 20) {
                        Button("0%") {
                            progress = 0.0
                            animator.animateTo(progress)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("25%") {
                            progress = 0.25
                            animator.animateTo(progress)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("50%") {
                            progress = 0.5
                            animator.animateTo(progress)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("75%") {
                            progress = 0.75
                            animator.animateTo(progress)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("100%") {
                            progress = 1.0
                            animator.animateTo(progress)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .tabItem {
                    Label("Manual Test", systemImage: "slider.horizontal.3")
                }
                
                // Tab 2: CoreData-based project testing
                VStack(spacing: 25) {
                    Text("Project Completion Test")
                        .font(.title2)
                    
                    if let project = testProject {
                        // Display project status
                        HStack(spacing: 15) {
                            // Project indicator with live CoreData status
                            ZStack {
                                // Track circle
                                Circle()
                                    .stroke(
                                        AppColors.getColor(from: project.color),
                                        lineWidth: 2
                                    )
                                    .frame(width: 30, height: 30)
                                
                                // This now uses our new tracker-based implementation
                                ProjectCompletionView(project: project)
                                    .frame(width: 28, height: 28)
                            }
                            .padding(10)
                            
                            Text(project.name ?? "Test Project")
                                .font(.headline)
                            
                            Spacer()
                            
                            // Show completion stats
                            Text("\(completedCount)/\(taskCount) completed")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Test controls
                        VStack(spacing: 15) {
                            Text("Test Controls")
                                .font(.headline)
                            
                            // Task count control
                            Stepper("Tasks: \(taskCount)", value: $taskCount, in: 1...10)
                                .onChange(of: taskCount) { newValue, _ in
                                    updateTasks(project: project)
                                }
                            
                            // Completed count control
                            Stepper("Completed: \(completedCount)", value: $completedCount, in: 0...taskCount)
                                .onChange(of: completedCount) { newValue, _ in
                                    updateCompletedTasks(project: project)
                                }
                            
                            // Color picker
                            Picker("Project Color", selection: Binding(
                                get: { project.color ?? "blue" },
                                set: { 
                                    project.color = $0
                                    try? viewContext.save()
                                }
                            )) {
                                ForEach(["blue", "green", "red", "orange", "purple", "yellow", "pink"], id: \.self) { color in
                                    HStack {
                                        Circle()
                                            .fill(AppColors.getColor(from: color))
                                            .frame(width: 16, height: 16)
                                        Text(color.capitalized)
                                    }
                                    .tag(color)
                                }
                            }
                            
                            Divider()
                            
                            
                            // Reset button
                            Button("Reset Test Project") {
                                resetTestProject()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                        .padding()
                    } else {
                        VStack(spacing: 20) {
                            Text("No test project created")
                                .foregroundColor(.secondary)
                            
                            Button("Create Test Project") {
                                createTestProject()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                .padding()
                .onAppear {
                    checkForTestProject()
                }
                .tabItem {
                    Label("CoreData Test", systemImage: "circle.hexagongrid.fill")
                }
            }
        }
        .frame(width: 500, height: 500)
        .padding()
    }
    
    // MARK: - CoreData Test Methods
    
    private func checkForTestProject() {
        // Check if we already have a test project
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Progress Test Project")
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let existing = results.first {
                testProject = existing
                updateCountsFromProject(existing)
            }
        } catch {
            print("Error fetching test project: \(error)")
        }
    }
    
    private func createTestProject() {
        let project = Project(context: viewContext)
        project.id = UUID()
        project.name = "Progress Test Project"
        project.color = "blue"
        
        // Add initial tasks
        for i in 1...taskCount {
            let task = Item(context: viewContext)
            task.id = UUID()
            task.title = "Test Task \(i)"
            task.project = project
            task.createdDate = Date()
            task.completed = false
        }
        
        // Save context
        do {
            try viewContext.save()
            testProject = project
        } catch {
            print("Error creating test project: \(error)")
        }
    }
    
    private func resetTestProject() {
        guard let project = testProject else { return }
        
        // Delete all tasks first
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project == %@", project)
        
        do {
            let tasks = try viewContext.fetch(fetchRequest)
            for task in tasks {
                viewContext.delete(task)
            }
            
            // Reset to default values
            taskCount = 3
            completedCount = 0
            
            // Create new tasks
            updateTasks(project: project)
            
            try viewContext.save()
        } catch {
            print("Error resetting test project: \(error)")
        }
    }
    
    private func updateCountsFromProject(_ project: Project) {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project == %@", project)
        
        do {
            let allTasks = try viewContext.fetch(fetchRequest)
            taskCount = allTasks.count
            completedCount = allTasks.filter { $0.completed }.count
        } catch {
            print("Error counting tasks: \(error)")
        }
    }
    
    private func updateTasks(project: Project) {
        // First, fetch current tasks
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project == %@", project)
        
        do {
            let currentTasks = try viewContext.fetch(fetchRequest)
            let currentCount = currentTasks.count
            
            // If we need to add tasks
            if currentCount < taskCount {
                for i in currentCount..<taskCount {
                    let task = Item(context: viewContext)
                    task.id = UUID()
                    task.title = "Test Task \(i + 1)"
                    task.project = project
                    task.createdDate = Date()
                    task.completed = false
                }
            } 
            // If we need to remove tasks
            else if currentCount > taskCount {
                // Sort tasks by completion (keep completed ones if possible)
                let sortedTasks = currentTasks.sorted { !$0.completed && $1.completed }
                
                // Remove tasks from the end of the list
                for i in taskCount..<currentCount {
                    viewContext.delete(sortedTasks[i])
                }
                
                // Ensure completed count is not greater than task count
                if completedCount > taskCount {
                    completedCount = taskCount
                }
            }
            
            // Update completion status
            updateCompletedTasks(project: project)
            
            try viewContext.save()
        } catch {
            print("Error updating tasks: \(error)")
        }
    }
    
    private func updateCompletedTasks(project: Project) {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "project == %@", project)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)]
        
        do {
            let tasks = try viewContext.fetch(fetchRequest)
            
            // Ensure we don't exceed task count
            let targetCompleted = min(completedCount, tasks.count)
            
            // Update task completion status - mark the first N tasks as completed
            for (index, task) in tasks.enumerated() {
                let shouldBeCompleted = index < targetCompleted
                
                // Only update if the status has changed to avoid unnecessary notifications
                if task.completed != shouldBeCompleted {
                    task.completed = shouldBeCompleted
                    print("Updated task \(index + 1) to completed: \(shouldBeCompleted)")
                }
            }
            
            try viewContext.save()
            
            // Force refresh counts after saving
            updateCountsFromProject(project)
        } catch {
            print("Error updating task completion: \(error)")
        }
    }
}

/// A specialized progress view component for CoreData-based project testing
struct ProjectCompletionView: View {
    @ObservedObject var project: Project
    @StateObject private var tracker: ProjectCompletionTracker
    @StateObject private var animator = CircleProgressAnimator()
    
    init(project: Project) {
        self.project = project
        self._tracker = StateObject(wrappedValue: ProjectCompletionTracker(project: project))
    }
    
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
            context.fill(path, with: .color(AppColors.getColor(from: project.color)))
        }
        .id("test-progress-\(project.id?.uuidString ?? "")-\(tracker.completionPercentage)")
        .onAppear {
            // Force refresh when view appears
            tracker.refresh()
            animator.reset()
            animator.animateTo(tracker.completionPercentage)
        }
        .onDisappear {
            tracker.cleanup()
        }
        .onReceive(tracker.$completionPercentage) { newPercentage in
            animator.animateTo(newPercentage)
        }
    }
}

#Preview {
    AnimatedProgressIndicatorTest()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
