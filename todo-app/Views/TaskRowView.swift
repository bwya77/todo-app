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
            // Status indicator
            Circle()
                .fill(task.completed ? Color.green : Color.gray)
                .frame(width: 16, height: 16)
            
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
