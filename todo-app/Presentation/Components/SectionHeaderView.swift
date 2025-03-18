//
//  SectionHeaderView.swift
//  todo-app
//
//  Created on 3/17/25.
//

import SwiftUI
import CoreData

/// A reusable section header view for task lists
struct SectionHeaderView: View {
    let title: String
    let isExpanded: Bool
    let itemCount: Int
    let viewContext: NSManagedObjectContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Project.name, ascending: true)])
    private var projects: FetchedResults<Project>
    
    var body: some View {
        HStack {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .foregroundColor(.gray)
                .frame(width: 16)
                
            if title == "Default" || title == "No Project" {
                Circle()
                    .fill(getGroupColor(for: title))
                    .frame(width: 10, height: 10)
            } else if let project = getProjectForGroupName(title) {
                ProjectCompletionIndicator(
                    project: project,
                    size: 10,
                    viewContext: viewContext
                )
                // Add a unique ID for this instance to force recreation when project changes
                .id("task-list-indicator-\(project.id?.uuidString ?? UUID().uuidString)")
            } else {
                Circle()
                    .fill(getGroupColor(for: title))
                    .frame(width: 10, height: 10)
            }
            
            Text(title)
                .fontWeight(.medium)
            
            Text("\(itemCount) items")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.white)
    }
    
    private func getGroupColor(for groupName: String) -> Color {
        if groupName == "Default" || groupName == "No Project" {
            return .red
        } else if let project = getProjectForGroupName(groupName) {
            return AppColors.getColor(from: project.color)
        } else {
            return .gray
        }
    }
    
    /// Helper method to get project object by its name
    /// - Parameter groupName: The name of the project group
    /// - Returns: The Project instance if found, nil otherwise
    private func getProjectForGroupName(_ groupName: String) -> Project? {
        return projects.first(where: { $0.name == groupName })
    }
}
