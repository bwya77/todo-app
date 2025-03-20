//
//  DebugTaskView.swift
//  todo-app
//
//  Created on 3/19/25.
//

import SwiftUI
import CoreData

struct DebugTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    var body: some View {
        VStack {
            Text("Debug Task View")
                .font(.title)
                .padding()
            
            Text("Number of tasks: \(items.count)")
                .padding()
            
            List {
                ForEach(items) { item in
                    VStack(alignment: .leading) {
                        Text(item.title ?? "Untitled")
                            .font(.headline)
                        
                        Text("Display Order: \(item.displayOrder)")
                        
                        if let dueDate = item.dueDate {
                            Text("Due: \(dueDate, formatter: dateFormatter)")
                                .font(.subheadline)
                        }
                        
                        Text("Completed: \(item.completed ? "Yes" : "No")")
                            .font(.subheadline)
                        
                        if let project = item.project {
                            Text("Project: \(project.name ?? "Unknown")")
                                .font(.subheadline)
                        } else {
                            Text("Project: None")
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Button("Repair Tasks") {
                repairTasks()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding()
        }
        .frame(width: 500, height: 600)
    }
    
    private func repairTasks() {
        DisplayOrderManager.ensureDisplayOrderExists()
        DisplayOrderManager.repairAllTaskOrder()
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
