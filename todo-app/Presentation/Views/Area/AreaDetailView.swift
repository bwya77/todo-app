//
//  AreaDetailView.swift
//  todo-app
//
//  Created on 3/22/25.
//

import SwiftUI
import CoreData

struct AreaDetailView: View {
    @ObservedObject var area: Area
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taskViewModel: TaskViewModel
    
    // FetchRequest for projects in this area
    @FetchRequest private var projects: FetchedResults<Project>
    
    init(area: Area, context: NSManagedObjectContext) {
        self.area = area
        self._taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
        
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
            // Area header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(AppColors.getColor(from: area.color ?? "gray"))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "cube.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    
                    Text(area.name ?? "Unnamed Area")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.leading, 8)
                }
                .padding(.bottom, 4)
                
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
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .background(
                Color(NSColor.windowBackgroundColor)
                    .opacity(0.5)
            )
            
            // Projects in this area
            ScrollView {
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
                .padding()
            }
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
                // Update the area
                area.name = name
                area.color = color
                
                try? viewContext.save()
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

// Project card for the grid view
struct ProjectCard: View {
    @ObservedObject var project: Project
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Project color and completion indicator
                ZStack {
                    Circle()
                        .fill(AppColors.getColor(from: project.color ?? "gray"))
                        .frame(width: 24, height: 24)
                    
                    if project.activeTaskCount == 0 && project.completedTaskCount > 0 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
                
                Text(project.name ?? "Unnamed Project")
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
            }
            
            Spacer()
            
            HStack {
                if project.activeTaskCount > 0 {
                    Text("\(project.activeTaskCount) active tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if project.completedTaskCount > 0 {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("No tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress indicator
                if project.totalTaskCount > 0 {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 16, height: 16)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(project.completedTaskCount) / CGFloat(project.totalTaskCount))
                            .stroke(AppColors.getColor(from: project.color ?? "gray"), lineWidth: 2)
                            .frame(width: 16, height: 16)
                            .rotationEffect(.degrees(-90))
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            // Navigate to the project when tapped
            NotificationCenter.default.post(
                name: NSNotification.Name("SelectProject"),
                object: nil,
                userInfo: ["project": project]
            )
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
