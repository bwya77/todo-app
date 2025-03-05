//
//  TaskRowView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//

import SwiftUI

struct TaskRowView: View {
    let task: Item
    let onToggleComplete: (Item) -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Complete button
            Button(action: {
                onToggleComplete(task)
            }) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.completed ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Task title and details
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Untitled Task")
                    .strikethrough(task.completed)
                    .foregroundColor(task.completed ? .gray : .primary)
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(AppDateFormatter.formatDueDate(dueDate))
                            .font(.caption)
                            .foregroundColor(isDueDateOverdue(dueDate) && !task.completed ? .red : .secondary)
                    }
                }
            }
            
            Spacer()
            
            // Project indicator
            if let project = task.project {
                Circle()
                    .fill(AppColors.getColor(from: project.color))
                    .frame(width: 10, height: 10)
                    .opacity(isHovering ? 1.0 : 0.6)
            }
            
            // Priority indicator
            if task.priority > 0 {
                Circle()
                    .fill(AppColors.priorityColor(for: task.priority))
                    .frame(width: 10, height: 10)
                    .opacity(isHovering ? 1.0 : 0.6)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isHovering ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private func isDueDateOverdue(_ date: Date) -> Bool {
        return date < Date() && !Calendar.current.isDateInToday(date)
    }
}
