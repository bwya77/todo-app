//
//  ProjectSelector.swift
//  todo-app
//
//  Created on 3/9/25.
//

import SwiftUI
import CoreData
import Combine

/// A progress indicator for project completion that resembles a filling circle/pie chart
fileprivate struct ProjectCompletionIndicator: View {
    @ObservedObject var project: Project
    @Environment(\.managedObjectContext) private var viewContext
    
    private var taskViewModel: TaskViewModel
    private var isSelected: Bool
    private var size: CGFloat
    
    /// Progress value from 0.0 to 1.0
    @State private var completionPercentage: Double = 0.0
    @State private var cancellables = Set<AnyCancellable>()
    
    init(project: Project, isSelected: Bool = false, size: CGFloat = 16, viewContext: NSManagedObjectContext) {
        self.project = project
        self.isSelected = isSelected
        self.size = size
        self.taskViewModel = TaskViewModel(context: viewContext)
    }
    
    var body: some View {
        ZStack {
            // Empty circle (background/outline)
            Circle()
                .strokeBorder(
                    isSelected ? AppColors.selectedIconColor : AppColors.getColor(from: project.color),
                    lineWidth: 1
                )
                .frame(width: size, height: size)
            
            // Progress pie
            if completionPercentage > 0 {
                ProgressPie(
                    progress: completionPercentage,
                    color: isSelected ? AppColors.selectedIconColor : AppColors.getColor(from: project.color)
                )
                .frame(width: size - 2, height: size - 2)
            }
        }
        .onAppear {
            updateCompletionPercentage()
            
            // Set up notification observer for context changes
            NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext)
                .sink { _ in 
                    updateCompletionPercentage()
                }
                .store(in: &cancellables)
        }
        .onDisappear {
            cancellables.removeAll()
        }
        .onChange(of: project) { newValue, oldValue in
            updateCompletionPercentage()
        }
    }
    
    private func updateCompletionPercentage() {
        // Calculate the percentage of completed tasks
        completionPercentage = taskViewModel.getProjectCompletionPercentage(project: project)
    }
}

/// A custom pie chart view for showing progress as a slice
fileprivate struct ProgressPie: View {
    var progress: Double  // 0.0 to 1.0
    var color: Color
    
    var body: some View {
        Canvas { context, size in
            // Define the center and radius of the circle
            let center = CGPoint(x: size.width/2, y: size.height/2)
            let radius = min(size.width, size.height) / 2
            
            // Create a path for the pie slice
            var path = Path()
            path.move(to: center)
            path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(-90) + .degrees(360 * progress), clockwise: false)
            path.closeSubpath()
            
            // Fill the path
            context.fill(path, with: .color(color))
        }
    }
}

struct ProjectSelector: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var selectedProject: Project?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.name, ascending: true)]
    ) private var allProjects: FetchedResults<Project>
    
    @State private var newProjectName = ""
    @State private var newProjectColor = "blue"
    @State private var showAddNewProject = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Select Project")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showAddNewProject.toggle()
                }) {
                    Label("Add New", systemImage: "plus")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 8)
            
            if showAddNewProject {
                // New project form
                VStack(spacing: 12) {
                    TextField("Project Name", text: $newProjectName)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Text("Color:")
                        
                        ForEach(["red", "orange", "yellow", "green", "blue", "purple", "pink"], id: \.self) { color in
                            Circle()
                                .fill(AppColors.getColor(from: color))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(newProjectColor == color ? Color.gray : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    newProjectColor = color
                                }
                        }
                    }
                    
                    HStack {
                        Button("Cancel") {
                            withAnimation {
                                showAddNewProject = false
                                newProjectName = ""
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button("Create") {
                            createNewProject()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newProjectName.isEmpty)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: showAddNewProject)
            }
            
            // Project list
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // No project option
                    HStack {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 12, height: 12)
                        
                        Text("Inbox (No Project)")
                        
                        Spacer()
                        
                        Image(systemName: selectedProject == nil ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedProject == nil ? .blue : .gray)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedProject = nil
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color.clear)
                    .cornerRadius(8)
                    
                    // Divider
                    Divider().padding(.vertical, 8)
                    
                    // Project list
                    ForEach(allProjects) { project in
                        HStack {
                            // Re-using the same project completion indicator as in sidebar
                            ProjectCompletionIndicator(
                                project: project,
                                size: 12,
                                viewContext: viewContext
                            )
                            
                            Text(project.name ?? "Unknown Project")
                            
                            Spacer()
                            
                            if let selectedProject = selectedProject, selectedProject.id == project.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.selectedProject = project
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color.clear)
                        .cornerRadius(8)
                    }
                }
            }
            
            // Footer
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300, height: 400)
    }
    
    private func createNewProject() {
        guard !newProjectName.isEmpty else { return }
        
        let project = Project(context: viewContext)
        project.id = UUID()
        project.name = newProjectName
        project.color = newProjectColor
        
        // Save the context
        do {
            try viewContext.save()
            selectedProject = project
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving project: \(error)")
        }
    }
}
