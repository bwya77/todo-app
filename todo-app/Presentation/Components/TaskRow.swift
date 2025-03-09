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
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(task.completed ? Color.green : Color.gray)
                .frame(width: 16, height: 16)
            
            // Task title and details
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Untitled Task")
                    .strikethrough(task.completed)
                    .foregroundColor(task.completed ? .gray : .primary)
                
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
                    onToggleComplete(task)
                }) {
                    Image(systemName: task.completed ? "arrow.uturn.backward" : "checkmark")
                        .foregroundColor(task.completed ? .blue : .green)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isHovering ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovering = hovering
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Allow clicking anywhere on the row to toggle completion
            onToggleComplete(task)
        }
    }
    
    private func isDueDateOverdue(_ date: Date) -> Bool {
        return date < Date() && !Calendar.current.isDateInToday(date)
    }
}
