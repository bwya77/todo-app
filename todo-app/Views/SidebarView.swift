//
//  SidebarView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//

import SwiftUI
import CoreData
import Foundation

struct CustomSidebarButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(isSelected ? AppColors.todayHighlight.opacity(0.3) : 
                   (configuration.isPressed ? Color(red: 226/255, green: 237/255, blue: 250/255) : Color.clear))
        .cornerRadius(4)
    }
}

struct SidebarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taskViewModel: TaskViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.name, ascending: true)],
        animation: .default)
    private var projects: FetchedResults<Project>
    
    @Binding var selectedViewType: ViewType
    @Binding var selectedProject: Project?
    
    @State private var showingAddProject = false
    @State private var showingAddTask = false
    @State private var newProjectName = ""
    @State private var newProjectColor = "blue"
    
    init(selectedViewType: Binding<ViewType>, selectedProject: Binding<Project?>, context: NSManagedObjectContext) {
        self._selectedViewType = selectedViewType
        self._selectedProject = selectedProject
        self._taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
    }
    
    var body: some View {
        ZStack {
            Color(red: 248/255, green: 250/255, blue: 251/255).edgesIgnoringSafeArea(.all)
            
            List {
            // No empty space needed since we have a proper title bar now
            Group {
                Button(action: {
                    selectedViewType = .inbox
                    selectedProject = nil
                }) {
                    Label("Inbox", systemImage: "tray")
                        .font(.system(size: 16))
                }
                .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .inbox))
                
                Button(action: {
                    showingAddTask = true
                }) {
                    Label {
                        Text("Add task")
                    } icon: {
                        ZStack {
                            Circle()
                                .fill(AppColors.todayHighlight)
                                .frame(width: 20, height: 20)
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .font(.system(size: 16))
                }
                .buttonStyle(CustomSidebarButtonStyle(isSelected: false))
                
                Button(action: {
                    selectedViewType = .today
                    selectedProject = nil
                }) {
                    Label {
                        Text("Today")
                    } icon: {
                        CalendarDayIcon()
                    }
                    .font(.system(size: 16))
                }
                .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .today))
                
                Button(action: {
                    selectedViewType = .upcoming
                    selectedProject = nil
                }) {
                    Label("Upcoming", systemImage: "calendar")
                        .font(.system(size: 16))
                }
                .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .upcoming))
                
                Button(action: {
                    selectedViewType = .filters
                    selectedProject = nil
                }) {
                    Label("Filters & Labels", systemImage: "tag")
                        .font(.system(size: 16))
                }
                .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .filters))
                
                Button(action: {
                    selectedViewType = .completed
                    selectedProject = nil
                }) {
                    Label("Completed", systemImage: "checkmark.circle")
                        .font(.system(size: 16))
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
                        Label {
                            Text(project.name ?? "Unnamed Project")
                        } icon: {
                            Circle()
                                .fill(AppColors.getColor(from: project.color))
                                .frame(width: 18, height: 18)
                        }
                    }
                    .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .project && selectedProject?.id == project.id))
                }
                .onDelete(perform: deleteProjects)
                
                Button(action: {
                    showingAddProject = true
                }) {
                    Label("Add Project", systemImage: "plus")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(CustomSidebarButtonStyle(isSelected: false))
            }
        }
        .listStyle(SidebarListStyle())
        .scrollContentBackground(.hidden) // This prevents the default background
        .background(Color(red: 248/255, green: 250/255, blue: 251/255))
        .font(.system(size: 16))
        }
        .sheet(isPresented: $showingAddTask) {
            VStack(spacing: 20) {
                Text("Add Task")
                    .font(.headline)
                
                TextField("Task Name", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                HStack {
                    Button("Cancel") {
                        showingAddTask = false
                    }
                    
                    Spacer()
                    
                    Button("Add") {
                        // Add task logic will go here
                        showingAddTask = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top)
            }
            .padding()
            .frame(width: 300)
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

enum ViewType {
    case inbox, today, upcoming, filters, completed, project, addTask
}

struct CalendarDayIcon: View {
    var body: some View {
        ZStack {
            Image(systemName: "calendar")
                .font(.system(size: 20))
                .foregroundColor(AppColors.todayHighlight)
            
            Text(String(Calendar.current.component(.day, from: Date())))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .offset(y: 1)
        }
    }
}
