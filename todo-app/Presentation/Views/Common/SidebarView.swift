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

struct CustomSidebarButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(isSelected ? AppColors.todayHighlight.opacity(0.3) : 
                   (configuration.isPressed ? AppColors.sidebarHover : Color.clear))
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
                                Text("\(taskViewModel.getInboxTaskCount())")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                            }
                        }
                        .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .inbox))
                        
                        Spacer().frame(height: 16)
                        
                        Button(action: {
                            showingAddTask = true
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
                                Text("\(taskViewModel.getTodayTaskCount())")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
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
                                        Circle()
                                            .fill(selectedViewType == .project && selectedProject?.id == project.id ? AppColors.selectedIconColor : AppColors.getColor(from: project.color))
                                            .frame(width: 16, height: 16)
                                    }
                                }
                            }
                            .buttonStyle(CustomSidebarButtonStyle(isSelected: selectedViewType == .project && selectedProject?.id == project.id))
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
