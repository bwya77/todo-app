//
//  ProjectCard.swift
//  todo-app
//
//  Created on 3/25/25.
//

import SwiftUI
import CoreData

/// Project card for the grid view in the Area detail screen
struct ProjectCard: View {
    @ObservedObject var project: Project
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Use ProjectCompletionIndicator for a consistent look
                ProjectCompletionIndicator(
                    project: project,
                    size: 20,
                    viewContext: viewContext
                )
                .id("project-card-indicator-\(project.id?.uuidString ?? UUID().uuidString)")
                
                Text(project.name ?? "Unnamed Project")
                    .font(.headline)
                    .lineLimit(1)
                    .padding(.leading, 4)
                
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
                
                // Tasks count badge
                if project.totalTaskCount > 0 {
                    Text("\(project.completedTaskCount)/\(project.totalTaskCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
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
