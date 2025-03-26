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
    
    // State for floating menu
    @State private var showingFloatingMenu: Bool = false
    @State private var menuPosition: CGPoint = .zero
    
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
        ZStack {
        VStack(alignment: .leading, spacing: 0) {
            // Area header with editable title and controls
            VStack(alignment: .leading, spacing: 8) {
                // Title section with simpler editing approach
                ZStack(alignment: .leading) {
                    if isEditingTitle {
                        HStack(alignment: .center, spacing: 10) {
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
                        HStack(alignment: .center, spacing: 10) {
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
                            
                                // Title and menu dots in a single HStack
                                HStack(spacing: 4) {
                                    Text(area.name ?? "Unnamed Area")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(Color.primary)
                                    
                                    // Modern floating menu button with ellipsis icon
                                    Button(action: {
                                        let point = NSEvent.mouseLocation
                                        
                                        // Calculate position for the floating menu
                                        if let window = NSApp.keyWindow {
                                            // Get window position in screen coordinates
                                            let windowFrame = window.frame
                                            
                                            // Position menu right next to the ellipses button
                                            self.menuPosition = CGPoint(
                                                x: point.x - windowFrame.minX + 4, 
                                                y: windowFrame.height - (point.y - windowFrame.minY) - 10
                                            )
                                            
                                            // Show the menu
                                            self.showingFloatingMenu = true
                                            
                                            // Start monitoring clicks outside the menu
                                            FloatingMenuEventMonitor.shared.startMonitoring()
                                        }
                                    }) {
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.gray)
                                            .padding(6)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .onHover { hovering in
                                        if hovering {
                                            NSCursor.pointingHand.set()
                                        } else {
                                            NSCursor.arrow.set()
                                        }
                                    }
                                }
                            
                            Spacer()
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
                
                // Project count removed as requested
                
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
            
            // Projects in this area - List View
            List {
                if projects.isEmpty {
                    // Empty state if no projects
                    Section {
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 16) {
                                Image(systemName: "square.grid.2x2")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color.gray.opacity(0.5))
                                
                                Text("No projects in this area")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Add a project to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 20)
                        .listRowSeparator(.hidden)
                    }
                } else {
                    // Projects section with a normal list style
                    ForEach(projects) { project in
                        Button(action: {
                            // Single click action - Select the project
                            NotificationCenter.default.post(
                                name: NSNotification.Name("SelectProject"),
                                object: nil,
                                userInfo: ["project": project]
                            )
                        }) {
                            HStack(spacing: 8) {
                                // Project indicator
                                Circle()
                                    .fill(AppColors.getColor(from: project.color ?? "gray"))
                                    .frame(width: 12, height: 12)
                                
                                // Project name
                                Text(project.name ?? "Unnamed Project")
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary) // Keep text color consistent
                                
                                // Active task count badge (only show if > 0)
                                if project.activeTaskCount > 0 {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.secondary.opacity(0.15))
                                            .frame(width: 28, height: 20)
                                        
                                        Text("\(project.activeTaskCount)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .frame(height: 28) // Consistent height for all rows
                        }
                        .buttonStyle(.projectRow) // Use our custom button style
                        .listRowInsets(EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8))
                        .listRowSeparator(.hidden) // Hide separators
                        .listRowBackground(Color.clear) // Clear background for custom hover effect
                    }
                    .onDelete { indexSet in
                        // Handle delete (we'll just detach from the area)
                        for index in indexSet {
                            let project = projects[index]
                            project.area = nil
                            
                            do {
                                try viewContext.save()
                            } catch {
                                print("Error detaching project from area: \(error)")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
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
        
        // Custom floating menu overlay
        FloatingAreaMenu(
            items: [
                FloatingMenuItem(
                    title: "New Project",
                    icon: "plus",
                    action: showProjectCreationPopup
                ),
                FloatingMenuItem(
                    title: "Edit Area",
                    icon: "pencil",
                    action: showAreaEditPopup
                ),
                FloatingMenuItem(
                    title: "Delete Area",
                    icon: "trash",
                    color: .red,
                    action: showDeleteAreaConfirmation
                )
            ],
            isPresented: $showingFloatingMenu,
            position: menuPosition
        )
    }
    .onDisappear {
        // Clean up when the view disappears
        FloatingMenuEventMonitor.shared.stopMonitoring()
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
