//
//  ProjectHeaderView.swift
//  todo-app
//
//  Created on 3/26/25.
//

import SwiftUI
import CoreData

struct ProjectHeaderView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var header: ProjectHeader
    @Binding var expandedHeaders: Set<UUID>
    @Binding var activeTask: Item?
    
    // Computed property to get active task count
    private var activeTaskCount: Int {
        // Filter to count only incomplete tasks
        return header.tasks().filter { !$0.completed }.count
    }
    
    // Check if this header is expanded
    private var isExpanded: Bool {
        guard let headerId = header.id else { return true }
        return expandedHeaders.contains(headerId)
    }
    
    // Track hover state
    @State private var isHovered = false
    @State private var isDragTarget = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Expand/collapse button
                Button(action: toggleExpand) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 14, height: 14)
                }
                .buttonStyle(.plain)
                
                // Header title
                Text(header.title ?? "Untitled Header")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.getColor(from: header.project?.color ?? "gray"))
                
                Spacer()
                
                // Task count badge (only show if there are active tasks)
                if activeTaskCount > 0 {
                    Text("\(activeTaskCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.getColor(from: header.project?.color ?? "gray"))
                        )
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isDragTarget ? Color.blue.opacity(0.1) : (isHovered ? Color.gray.opacity(0.1) : Color.clear))
            )
            .onHover { hovering in
                isHovered = hovering
            }
            .contentShape(Rectangle())
            .onDrop(of: [.text], isTargeted: $isDragTarget) { providers, _ in
                return handleTaskDrop(providers: providers)
            }
            
            // Grey divider line added underneath the header
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.top, 2)
                .padding(.bottom, 2)
        }
    }
    
    // Toggle expand/collapse
    private func toggleExpand() {
        guard let headerId = header.id else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedHeaders.contains(headerId) {
                expandedHeaders.remove(headerId)
            } else {
                expandedHeaders.insert(headerId)
            }
        }
    }
    
    // Handle task drop onto header
    private func handleTaskDrop(providers: [NSItemProvider]) -> Bool {
        guard let activeTask = activeTask else { return false }
        
        // Safety check - if the task is already in this header, just return true
        if activeTask.header == header {
            return true
        }
        
        // Move the active task to this header
        let oldHeader = activeTask.header
        activeTask.header = header
        
        // Update display order to be at the end of this header's tasks
        let allTasks = header.tasks()
        activeTask.displayOrder = allTasks.isEmpty ? 0 : (allTasks.map { $0.displayOrder }.max() ?? 0) + 10
        
        // Save changes
        do {
            try viewContext.save()
            
            // Ensure the header is expanded when a task is dropped on it
            if let headerId = header.id {
                expandedHeaders.insert(headerId)
            }
            
            // Reset active task
            self.activeTask = nil
            return true
        } catch {
            print("Error moving task to header: \(error)")
            // Attempt to revert the change
            activeTask.header = oldHeader
            return false
        }
    }
}
