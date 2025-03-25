//
//  AreaDetailView.swift
//  todo-app
//
//  Created on 3/22/25.
//

import SwiftUI
import CoreData

struct AreaDetailView: View {
    // Keep reference to monitors
    private let clickMonitor = GlobalClickMonitor.shared
    private let textFieldMonitor = TextFieldMonitor.shared
    private let mouseMonitor = NSEventMonitor.shared
    
    // State for editing area title
    @State private var isEditingTitle: Bool = false
    @State private var editedTitle: String = ""
    @ObservedObject var area: Area
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taskViewModel: TaskViewModel
    
    // FetchRequest for projects in this area
    @FetchRequest private var projects: FetchedResults<Project>
    
    init(area: Area, context: NSManagedObjectContext) {
        self.area = area
        self._taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
        self._editedTitle = State(initialValue: area.name ?? "Unnamed Area")
        
        // Initialize the fetch request to get projects for this area
        let request: NSFetchRequest<Project> = Project.fetchRequest()
        request.predicate = NSPredicate(format: "area == %@", area)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Project.displayOrder, ascending: true)
        ]
        self._projects = FetchRequest(fetchRequest: request, animation: .default)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Area header with editable title and controls
            VStack(alignment: .leading, spacing: 8) {
                // Title section with simpler editing approach
                ZStack(alignment: .leading) {
                    if isEditingTitle {
                        HStack(spacing: 10) {
                            // Keep the area icon visible during editing
                            ZStack {
                                Circle()
                                    .fill(AppColors.getColor(from: area.color ?? "gray"))
                                    .frame(width: 20, height: 20)
                                
                                Image(systemName: "cube.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                            // Add a unique ID to force recreation when area changes
                            .id("area-indicator-edit-mode-\(area.id?.uuidString ?? UUID().uuidString)")
                            
                            // Text field for editing
                            NoSelectionTextField(text: $editedTitle, onCommit: saveAreaTitle, onStartEditing: { textField in
                                // Start monitoring for clicks outside the text field
                                self.clickMonitor.startMonitoring(view: textField) {
                                    if self.isEditingTitle {
                                        self.saveAreaTitle()
                                    }
                                }
                                
                                // Also start monitoring for clicks inside the field to correctly position cursor
                                self.textFieldMonitor.startMonitoring(textField: textField)
                            })
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    } else {
                        HStack(spacing: 10) {
                            // Area icon
                            ZStack {
                                Circle()
                                    .fill(AppColors.getColor(from: area.color ?? "gray"))
                                    .frame(width: 20, height: 20)
                                
                                Image(systemName: "cube.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                            // Add a unique ID to force recreation when area changes
                            .id("area-indicator-\(area.id?.uuidString ?? UUID().uuidString)")
                            
                            Text(area.name ?? "Unnamed Area")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color.primary) // Make sure text color is normal
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .help("Click to edit area title")
                        .onHover { hovering in
                            if hovering {
                                NSCursor.iBeam.set()
                            } else {
                                NSCursor.arrow.set()
                            }
                        }
                        .background(
                            // Add a subtle highlight on hover to indicate it's clickable
                            Color.gray.opacity(0.0001) // Nearly invisible but catches clicks
                        )
                        .onTapGesture { location in
                            // Get and store the current mouse position directly for cursor positioning
                            if let windowRef = NSApp.keyWindow {
                                let screenPoint = NSEventMonitor.shared.getCurrentMousePosition()
                                let windowPoint = windowRef.convertPoint(fromScreen: screenPoint)
                                
                                // Store the click location for cursor positioning
                                CursorLocationTracker.lastClickLocation = windowPoint
                                
                                // Start editing title
                                startEditingTitle()
                            }
                        }
                    }
                }
                
                HStack {
                    Text("\(projects.count) Projects")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            // Add the new project to this area
                            showProjectCreationPopup()
                        }) {
                            Label("Add Project", systemImage: "plus")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            // Edit area details
                            showAreaEditPopup()
                        }) {
                            Label("Edit Area", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            // Delete area confirmation
                            showDeleteAreaConfirmation()
                        }) {
                            Label("Delete Area", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Space for padding
                Spacer()
                    .frame(height: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 8)
            .background(Color.white)
            
            // Area Notes - Using the same pattern as ProjectNotesEditor
            VStack(alignment: .leading) {
                ProjectNotesEditor(
                    text: Binding(
                        get: { self.area.notes ?? "" },
                        set: { newValue in
                            self.area.notes = newValue
                            do {
                                try self.viewContext.save()
                            } catch {
                                print("Error saving area notes: \(error)")
                            }
                        }
                    ),
                    placeholder: "Notes", 
                    font: .system(size: 14, weight: .regular)
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            // Force complete recreation of text editor when area changes
            .id("area-notes-editor-\(self.area.id?.uuidString ?? UUID().uuidString)")
            
            // Divider after title and notes
            CustomDivider()
                .padding(.horizontal, 16)
                .padding(.bottom, 0)
            
            // Projects in this area
            ScrollView {
                VStack(spacing: 16) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 16)], spacing: 16) {
                        ForEach(projects) { project in
                            ProjectCard(project: project)
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                        }
                        
                        // Add Project card
                        Button(action: {
                            showProjectCreationPopup()
                        }) {
                            VStack {
                                Image(systemName: "plus.circle")
                                    .font(.largeTitle)
                                    .foregroundColor(AppColors.getColor(from: area.color ?? "gray"))
                                
                                Text("Add Project")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                                    .background(Color.white.cornerRadius(8))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Empty state if no projects
                    if projects.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                                .frame(height: 20)
                            
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 48))
                                .foregroundColor(Color.gray.opacity(0.5))
                            
                            Text("No projects in this area")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Add a project to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showProjectCreationPopup()
                            }) {
                                Text("Add Project")
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(AppColors.getColor(from: area.color ?? "gray").opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                                .frame(height: 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .background(Color.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        // Add handlers for keyboard events and blur events
        .onSubmit(of: .text) {
            if isEditingTitle {
                saveAreaTitle()
            }
        }
        // Force a unique ID for the view to properly re-render when the area changes
        .id("area-detail-view-\(area.id?.uuidString ?? UUID().uuidString)")
        // Add escape key handler for the text field
        .onExitCommand {
            if isEditingTitle {
                // Cancel edit and revert to original title
                isEditingTitle = false
                clickMonitor.stopMonitoring()
                textFieldMonitor.stopMonitoring()
            }
        }
    }
    
    // MARK: - Title Editing Methods
    
    private func startEditingTitle() {
        // Set up the editing state
        editedTitle = area.name ?? "Unnamed Area"
        
        // Set editing to true
        isEditingTitle = true
    }
    
    private func saveAreaTitle() {
        guard isEditingTitle else { return }
        
        // Don't save or stop editing if emoji picker might be active
        if clickMonitor.isEmojiPickerActive {
            // We don't want to save while emoji picker is active
            return
        }
        
        finalizeSaveAreaTitle()
    }
    
    private func finalizeSaveAreaTitle() {
        guard isEditingTitle else { return }
        
        // Mark as not editing
        isEditingTitle = false
        
        // Stop all monitoring
        clickMonitor.stopMonitoring()
        textFieldMonitor.stopMonitoring()
        
        // Trim whitespace and ensure we have a valid title
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty, trimmedTitle != area.name {
            // Update the area name using the TaskViewModel
            taskViewModel.updateArea(area, name: trimmedTitle)
        }
    }
    
    // Shows a popup to create a new project in this area
    private func showProjectCreationPopup() {
        let alert = NSAlert()
        alert.messageText = "Create New Project"
        alert.informativeText = "Enter a name for your project in the '\(area.name ?? "Unnamed Area")' area"
        
        let nameField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        nameField.placeholderString = "Project Name"
        
        let colorPopup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        for color in AppColors.colorMap.keys.sorted() {
            colorPopup.addItem(withTitle: color.capitalized)
        }
        
        let accessoryView = NSStackView(frame: NSRect(x: 0, y: 0, width: 300, height: 54))
        accessoryView.orientation = .vertical
        accessoryView.spacing = 8
        accessoryView.addArrangedSubview(nameField)
        accessoryView.addArrangedSubview(colorPopup)
        
        alert.accessoryView = accessoryView
        
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        
        nameField.becomeFirstResponder()
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            let name = nameField.stringValue
            let color = AppColors.colorMap.keys.sorted()[colorPopup.indexOfSelectedItem]
            
            if !name.isEmpty {
                // Create the project and assign it to this area
                taskViewModel.addProject(name: name, color: color, area: area)
            }
        }
    }
    
    // Shows a popup to edit area details
    private func showAreaEditPopup() {
        let alert = NSAlert()
        alert.messageText = "Edit Area"
        alert.informativeText = "Update area details"
        
        let nameField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        nameField.stringValue = area.name ?? ""
        nameField.placeholderString = "Area Name"
        
        let colorPopup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        for (index, color) in AppColors.colorMap.keys.sorted().enumerated() {
            colorPopup.addItem(withTitle: color.capitalized)
            if color == area.color {
                colorPopup.selectItem(at: index)
            }
        }
        
        let accessoryView = NSStackView(frame: NSRect(x: 0, y: 0, width: 300, height: 54))
        accessoryView.orientation = .vertical
        accessoryView.spacing = 8
        accessoryView.addArrangedSubview(nameField)
        accessoryView.addArrangedSubview(colorPopup)
        
        alert.accessoryView = accessoryView
        
        alert.addButton(withTitle: "Update")
        alert.addButton(withTitle: "Cancel")
        
        nameField.becomeFirstResponder()
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            let name = nameField.stringValue
            let color = AppColors.colorMap.keys.sorted()[colorPopup.indexOfSelectedItem]
            
            if !name.isEmpty {
                // Update the area using the TaskViewModel
                taskViewModel.updateArea(area, name: name, color: color)
            }
        }
    }
    
    // Shows a confirmation dialog to delete the area
    private func showDeleteAreaConfirmation() {
        let alert = NSAlert()
        alert.messageText = "Delete Area"
        alert.informativeText = "Are you sure you want to delete this area?\nThis will not delete the projects in this area."
        alert.alertStyle = .warning
        
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Delete the area but keep the projects (detach them from the area)
            if let projects = area.projects as? Set<Project> {
                for project in projects {
                    project.area = nil
                }
            }
            
            taskViewModel.deleteArea(area)
        }
    }
}

struct AreaDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let area = Area(context: context)
        area.id = UUID()
        area.name = "Work"
        area.color = "blue"
        
        // Create some projects
        let project1 = Project(context: context)
        project1.id = UUID()
        project1.name = "Project 1"
        project1.color = "red"
        project1.area = area
        
        let project2 = Project(context: context)
        project2.id = UUID()
        project2.name = "Project 2"
        project2.color = "green"
        project2.area = area
        
        return AreaDetailView(area: area, context: context)
            .environment(\.managedObjectContext, context)
            .frame(width: 800, height: 600)
    }
}
