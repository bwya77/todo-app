//
//  CalendarTaskViews.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI
import CoreData

// Task view for time-specific tasks
struct TaskEventView: View {
    let task: Item
    
    var body: some View {
        HStack {
            // Left border showing task status
            Rectangle()
                .fill(task.completed ? Color.gray : getTaskColor())
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title ?? "")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(task.completed ? Color.gray.opacity(0.6) : .primary)
                    .lineLimit(1)
                
                if let dueDate = task.dueDate {
                    Text(timeString(from: dueDate))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            
            Spacer()
        }
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        )
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // Helper to get the task color
    private func getTaskColor() -> Color {
        if let project = task.project, let colorName = project.color {
            return AppColors.getColor(from: colorName)
        } else {
            // Use the sidebar selection blue color for consistency
            return task.completed ? Color.gray : AppColors.selectedIconColor
        }
    }
}

// All Day Task View for the Day view All Day section
struct AllDayTaskView: View {
    let task: Item
    
    // Helper to get the task color
    private func getTaskColor() -> Color {
        if let project = task.project, let colorName = project.color {
            return AppColors.getColor(from: colorName)
        } else {
            // Use the sidebar selection blue color for consistency
            return task.completed ? Color.gray : AppColors.selectedIconColor
        }
    }
    
    var body: some View {
        HStack {
            ZStack {
                // Get color based on project or default to pink
                let checkboxColor = getTaskColor()
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(task.completed ? checkboxColor.opacity(0.7) : Color.clear)
                    .frame(width: 10, height: 10)
                
                RoundedRectangle(cornerRadius: 2)
                    .stroke(task.completed ? checkboxColor : checkboxColor.opacity(0.8), lineWidth: 1.2)
                    .frame(width: 10, height: 10)
                
                if task.completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text(task.title ?? "")
                .font(.subheadline)
                .foregroundColor(task.completed ? Color.gray.opacity(0.6) : .primary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }
}

// Compact All Day Task Row for Week view - more compact design
struct AllDayTaskRow: View {
    let task: Item
    
    // Helper to get the task color
    private func getTaskColor() -> Color {
        if let project = task.project, let colorName = project.color {
            return AppColors.getColor(from: colorName)
        } else {
            // Use the sidebar selection blue color for consistency
            return task.completed ? Color.gray : AppColors.selectedIconColor
        }
    }
    
    var body: some View {
        HStack(spacing: 3) { // Reduced spacing
            ZStack {
                // Get color based on project or default to red
                let checkboxColor = getTaskColor()
                
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(task.completed ? checkboxColor : Color.clear)
                    .frame(width: 6, height: 6) // Smaller indicator
                
                RoundedRectangle(cornerRadius: 1.5)
                    .stroke(task.completed ? checkboxColor : checkboxColor, lineWidth: 1)
                    .frame(width: 6, height: 6)
                
                // For this small size, just use a filled square when completed since a checkmark would be too small to see clearly
            }
            
            Text(task.title ?? "")
                .font(.system(size: 10)) // Smaller font
                .foregroundColor(task.completed ? Color.gray.opacity(0.6) : .black)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.vertical, 1) // Reduced vertical padding
        .padding(.horizontal, 4) // Reduced horizontal padding
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 3) // Smaller corner radius
                .fill(AppColors.selectedIconColor.opacity(0.1)) // Lighter background with app blue
        )
        .padding(.horizontal, 1) // Smaller outer horizontal padding
        .padding(.vertical, 0) // No outer vertical padding
    }
}
