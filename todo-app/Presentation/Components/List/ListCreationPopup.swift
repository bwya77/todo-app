//
//  ListCreationPopup.swift
//  todo-app
//
//  Created on 3/20/25.
//

import SwiftUI
import CoreData

struct ListCreationPopup: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var taskViewModel: TaskViewModel
    
    enum ListType {
        case project
        case area
    }
    
    // MARK: - List Properties
    @State private var selectedType: ListType = .project
    
    init(taskViewModel: TaskViewModel) {
        self._taskViewModel = ObservedObject(wrappedValue: taskViewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Used a simplified layout that matches the mockup
            VStack(alignment: .leading, spacing: 20) {
                // Project Option
                Button(action: {
                    selectedType = .project
                    createList()
                }) {
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "circle.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("New Project")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Define a goal, then work towards it one to-do at a time.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Area Option
                Button(action: {
                    selectedType = .area
                    createList()
                }) {
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "cube.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("New Area")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Group your projects and to-dos based on different responsibilities, such as Family or Work.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(24)
        }
        .frame(width: 350)
        .background(Color(red: 0.15, green: 0.15, blue: 0.17)) // Dark background matching the mockup
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // The simplified design no longer needs these components
    
    // MARK: - Helper Methods
    
    /// Show a prompt to get name and color for the project/area
    private func createList() {
        let alert = NSAlert()
        alert.messageText = selectedType == .project ? "Create New Project" : "Create New Area"
        alert.informativeText = "Enter a name for your \(selectedType == .project ? "project" : "area")"
        
        let nameField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        nameField.placeholderString = "Name"
        
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
                // Create either a project or area based on the selected type
                if selectedType == .project {
                    taskViewModel.addProject(name: name, color: color)
                } else {
                    taskViewModel.addArea(name: name, color: color)
                }
            }
        }
        
        // Use animation when dismissing
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ListCreationPopup_Previews: PreviewProvider {
    static var previews: some View {
        ListCreationPopup(taskViewModel: TaskViewModel(context: PersistenceController.preview.container.viewContext))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
