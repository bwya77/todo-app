//
//  TaskRow.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//  Refactored according to improvement plan on 3/7/25.
//  Updated on 3/9/25 to support the new date formatter.
//

import SwiftUI

struct TaskRow: View {
    let task: Item
    let onToggleComplete: (Item) -> Void
    var viewType: ViewType? = nil // Optional viewType to determine color
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator - Rounded square checkbox
            ZStack {
                // Get color based on view type, project, or default
                let checkboxColor = getTaskColor()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(task.completed ? checkboxColor : Color.clear)
                    .frame(width: 16, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .stroke(task.completed ? checkboxColor : Color.gray, lineWidth: 1.5)
                    .frame(width: 16, height: 16)
                
                if task.completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Task title and details
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Untitled Task")
                    .foregroundColor(task.completed ? Color.gray.opacity(0.6) : .primary)
                
                HStack(spacing: 8) {
                    // Due date if available
                    if let dueDate = task.dueDate {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(TodoAppTaskDateFormatter.formatDueDate(dueDate))
                                .font(.caption)
                                .foregroundColor(isDueDateOverdue(dueDate) && !task.completed ? .red : .secondary)
                        }
                    }
                    
                    // Priority if not None
                    if task.priority > 0 {
                        TaskPriorityUtils.priorityLabel(task.priority)
                            .font(.caption)
                    }
                    
                    // Project label if assigned
                    if let project = task.project, let projectName = project.name {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(AppColors.getColor(from: project.color))
                                .frame(width: 6, height: 6)
                            
                            Text(projectName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Actions only visible on hover
            if isHovering {
                Button(action: {
                    withAnimation(nil) {
                        onToggleComplete(task)
                    }
                }) {
                    Image(systemName: task.completed ? "arrow.uturn.backward" : "checkmark")
                        .foregroundColor(task.completed ? .blue : .green)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(isHovering ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovering = hovering
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Allow clicking anywhere on the row to toggle completion
            withAnimation(nil) {
                onToggleComplete(task)
            }
        }
        // Make task reorderable
        .taskReorderable(item: task)
    }
    
    private func isDueDateOverdue(_ date: Date) -> Bool {
        return date < Date() && !Calendar.current.isDateInToday(date)
    }
    
    private func getTaskColor() -> Color {
        // Special case for standard views (Today, Upcoming, Completed, Inbox)
        if let viewType = viewType, 
           viewType == .today || viewType == .upcoming || viewType == .completed || viewType == .inbox {
            return AppColors.selectedIconColor // Use the blue sidebar selection color
        }
        
        // If task has a project, use project color
        if let project = task.project, let colorName = project.color {
            return AppColors.getColor(from: colorName)
        } else {
            // For projects and other contexts use green
            return Color.green
        }
    }
}
