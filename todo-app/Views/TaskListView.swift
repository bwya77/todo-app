//
//  TaskListView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//

import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taskViewModel: TaskViewModel
    
    @FetchRequest private var tasks: FetchedResults<Item>
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingAddTask = true
                    newTaskProject = selectedProject
                }) {
                    Label("Add Task", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Tasks list
            List {
                ForEach(tasks) { task in
                    TaskRowView(task: task, onToggleComplete: toggleTaskCompletion)
                }
                .onDelete(perform: deleteTasks)
            }
            .listStyle(PlainListStyle())
        }
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
    
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { tasks[$0] }.forEach { task in
                taskViewModel.deleteTask(task)
            }
        }
    }
}
