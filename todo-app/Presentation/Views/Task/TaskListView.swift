//
//  TaskListView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//  Refactored according to improvement plan on 3/7/25.
//

import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taskViewModel: TaskViewModel
    
    @FetchRequest private var tasks: FetchedResults<Item>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Project.name, ascending: true)])
    private var projects: FetchedResults<Project>
    
    @State private var showingAddTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate = Date()
    @State private var newTaskHasDueDate = false
    @State private var newTaskPriority: Int16 = 0
    @State private var newTaskProject: Project?
    
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
            
        case .addTask:
            title = "Add Task"
            // No specific predicate for this view
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
        VStack(spacing: 0) {
            // Additional whitespace at the top
            Spacer().frame(height: 24)
            
            // Header
            HStack {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                
                Spacer()
                
                // Add Task button only appears in Project view
                if viewType == .project {
                    Button(action: {
                        showingAddTask = true
                        newTaskProject = selectedProject
                    }) {
                        Label("Add Task", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 8)
            
            // Tasks list grouped by project
            List {
                ForEach(groupTasks().keys.sorted(), id: \.self) { groupName in
                    if let groupTasks = groupTasks()[groupName] {
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedGroups.contains(groupName) },
                                set: { isExpanded in
                                    if isExpanded {
                                        expandedGroups.insert(groupName)
                                    } else {
                                        expandedGroups.remove(groupName)
                                    }
                                }
                            ),
                            content: {
                                ForEach(groupTasks) { task in
                                    TaskRow(task: task, onToggleComplete: toggleTaskCompletion)
                                }
                                .onDelete(perform: { offsets in
                                    deleteTasks(from: groupName, at: offsets)
                                })
                            },
                            label: {
                                HStack {
                                    Label(groupName, systemImage: "circle.fill")
                                        .foregroundColor(getGroupColor(for: groupName))
                                    
                                    Text("\(groupTasks.count) items")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        )
                    }
                }
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .sheet(isPresented: $showingAddTask) {
            VStack(spacing: 20) {
                Text("Add Task")
                    .font(.headline)
                
                TextField("Task Title", text: $newTaskTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Toggle("Due Date", isOn: $newTaskHasDueDate)
                
                if newTaskHasDueDate {
                    DatePicker("Due Date", selection: $newTaskDueDate, displayedComponents: [.date])
                }
                
                Picker("Priority", selection: $newTaskPriority) {
                    Text("None").tag(Int16(0))
                    Text("High").tag(Int16(1))
                    Text("Medium").tag(Int16(2))
                    Text("Low").tag(Int16(3))
                }
                .pickerStyle(SegmentedPickerStyle())
                
                HStack {
                    Button("Cancel") {
                        showingAddTask = false
                        resetNewTaskFields()
                    }
                    
                    Spacer()
                    
                    Button("Add") {
                        addTask()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newTaskTitle.isEmpty)
                }
                .padding(.top)
            }
            .padding()
            .frame(width: 400)
        }
    }
    
    private func addTask() {
        guard !newTaskTitle.isEmpty else { return }
        
        taskViewModel.addTask(
            title: newTaskTitle,
            dueDate: newTaskHasDueDate ? newTaskDueDate : nil,
            priority: newTaskPriority,
            project: newTaskProject
        )
        
        resetNewTaskFields()
        showingAddTask = false
    }
    
    private func resetNewTaskFields() {
        newTaskTitle = ""
        newTaskDueDate = Date()
        newTaskHasDueDate = false
        newTaskPriority = 0
        newTaskProject = nil
    }
    
    private func toggleTaskCompletion(_ task: Item) {
        taskViewModel.toggleTaskCompletion(task)
    }
    
    private func getGroupColor(for groupName: String) -> Color {
        if groupName == "Default" {
            return .red
        } else if let project = projects.first(where: { $0.name == groupName }) {
            return AppColors.getColor(from: project.color)
        } else {
            return .gray
        }
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
}
