//
//  ProjectSelector.swift
//  todo-app
//
//  Created on 3/9/25.
//

import SwiftUI
import CoreData
import Combine
import Dispatch

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
                            // Re-using the shared project completion indicator
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
