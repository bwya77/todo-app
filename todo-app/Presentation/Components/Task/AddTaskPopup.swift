//
//  AddTaskPopup.swift
//  todo-app
//
//  Created on 3/9/25.
//

import SwiftUI
import CoreData
import AppKit

struct AddTaskPopup: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var taskViewModel: TaskViewModel
    
    // MARK: - Task Properties
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var hasDeadline: Bool = false
    @State private var deadline: Date = Date()
    @State private var priority: Int16 = 0
    @State private var selectedProject: Project?
    @State private var isAllDay: Bool = false
    @State private var selectedTags: Set<Tag> = []
    
    // MARK: - UI States
    @State private var selectedTab = 0
    @State private var showProjectPicker = false
    @State private var showTagPicker = false
    
    // FetchRequest for all available projects
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.name, ascending: true)]
    ) private var allProjects: FetchedResults<Project>
    
    // FetchRequest for all available tags
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
    ) private var allTags: FetchedResults<Tag>
    
    // Transition namespace for smooth animations
    @Namespace private var formTransition
    
    // Initialize with an optional selected project
    init(taskViewModel: TaskViewModel, selectedProject: Project? = nil) {
        self._taskViewModel = ObservedObject(wrappedValue: taskViewModel)
        self._selectedProject = State(initialValue: selectedProject)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            header
                .padding(.bottom, 16)
            
            // MARK: - Content
            content
                .padding(.horizontal, 24)
            
            // MARK: - Footer
            footer
                .padding(.top, 16)
        }
        .padding(.vertical, 20)
        .frame(width: 500)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Header Component
    private var header: some View {
        VStack(spacing: 8) {
            Text("Add New Task")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 8)
            
            Picker("Task Type", selection: $selectedTab) {
                Text("Basic").tag(0)
                Text("Details").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Content Component
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title field (always visible)
                titleSection
                
                if selectedTab == 0 {
                    // Basic tab
                    basicInfoSection
                } else {
                    // Details tab
                    detailsSection
                }
            }
            .padding(.vertical, 8)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
        .frame(height: 320)
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.headline)
                .foregroundColor(.secondary)
            
            TextField("Task title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
        }
        .matchedGeometryEffect(id: "titleSection", in: formTransition)
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Due Date
            dueDateSection
            
            // Priority
            prioritySection
            
            // Project Selection
            projectSection
        }
    }
    
    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Notes
            notesSection
            
            // Tags
            tagsSection
            
            // Deadline (separate from due date)
            deadlineSection
        }
    }
    
    // MARK: - Due Date Section
    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Due Date", isOn: $hasDueDate)
                .font(.headline)
                .foregroundColor(.secondary)
            
            if hasDueDate {
                HStack {
                    DatePicker("", selection: $dueDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                    
                    Toggle("All Day", isOn: $isAllDay)
                        .toggleStyle(SwitchToggleStyle())
                        .padding(.leading, 8)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.2), value: hasDueDate)
            }
        }
    }
    
    // MARK: - Priority Section
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Priority")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Picker("Priority", selection: $priority) {
                Text("None").tag(Int16(0))
                Text("Low").tag(Int16(1))
                Text("Medium").tag(Int16(2))
                Text("High").tag(Int16(3))
            }
            .pickerStyle(SegmentedPickerStyle())
            .colorMultiply(priorityColor)
            
            // Show selected priority label
            if priority > 0 {
                HStack {
                    TaskPriorityUtils.priorityLabel(priority)
                        .padding(.top, 4)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Project Section
    private var projectSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Project")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                if let project = selectedProject {
                    HStack {
                        Circle()
                            .fill(AppColors.getColor(from: project.color))
                            .frame(width: 12, height: 12)
                        
                        Text(project.name ?? "Unknown Project")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            selectedProject = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    Button(action: {
                        showProjectPicker = true
                    }) {
                        HStack {
                            Text("Select Project")
                                .foregroundColor(.secondary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .sheet(isPresented: $showProjectPicker) {
            ProjectSelector(selectedProject: $selectedProject)
                .environment(\.managedObjectContext, taskViewModel.viewContext)
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $notes)
                .frame(height: 80)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary.opacity(0.3))
                )
                .cornerRadius(4)
        }
    }
    
    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Array(selectedTags)) { tag in
                        HStack {
                            Circle()
                                .fill(AppColors.getColor(from: tag.color))
                                .frame(width: 8, height: 8)
                            
                            Text(tag.name ?? "")
                                .font(.caption)
                            
                            Button(action: {
                                selectedTags.remove(tag)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                    showTagPicker = true
                    }) {
                    Image(systemName: "plus")
                    .font(.caption)
                    .padding(6)
                    .background(Circle().fill(Color.secondary.opacity(0.1)))
                    }
                    .buttonStyle(PlainButtonStyle())
            .help("Add tags")
                }
            }
        }
        .sheet(isPresented: $showTagPicker) {
            TagPicker(selectedTags: $selectedTags)
                .environment(\.managedObjectContext, taskViewModel.viewContext)
        }
    }
    
    // MARK: - Priority Picker
    private var priorityColor: Color {
        TaskPriorityUtils.getPriorityColor(priority).opacity(0.2)
    }
    
    // MARK: - Deadline Section
    private var deadlineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Deadline", isOn: $hasDeadline)
                .font(.headline)
                .foregroundColor(.secondary)
            
            if hasDeadline {
                HStack {
                    DatePicker("", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.2), value: hasDeadline)
            }
        }
    }
    
    // MARK: - Footer Component
    private var footer: some View {
        HStack {
            Button("Cancel") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Add Task") {
                addTask()
            }
            .buttonStyle(.borderedProminent)
            .disabled(title.isEmpty)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Helper Methods
    
    /// Add task to CoreData and dismiss the popup
    private func addTask() {
        taskViewModel.addTask(
            title: title,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority,
            project: selectedProject,
            notes: notes.isEmpty ? nil : notes
        )
        
        // Add tags to the task if any are selected
        if let createdTask = fetchNewlyCreatedTask() {
            for tag in selectedTags {
                taskViewModel.addTagToTask(tag, task: createdTask)
            }
        }
        
        // Use the same animation as the opening animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    /// Helper to fetch the most recently created task
    private func fetchNewlyCreatedTask() -> Item? {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdDate, ascending: false)]
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        
        do {
            let results = try taskViewModel.viewContext.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching newly created task: \(error)")
            return nil
        }
    }
}

// Preview provider
struct AddTaskPopup_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskPopup(taskViewModel: TaskViewModel(context: PersistenceController.preview.container.viewContext))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
