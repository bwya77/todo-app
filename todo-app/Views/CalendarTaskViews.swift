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
            Rectangle()
                .fill(task.completed ? Color.gray : Color.blue)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title ?? "")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(task.completed ? .secondary : .primary)
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
}

// All Day Task View for the Day view All Day section
struct AllDayTaskView: View {
    let task: Item
    
    var body: some View {
        HStack {
            Circle()
                .fill(task.completed ? Color.gray.opacity(0.7) : Color.pink.opacity(0.8))
                .frame(width: 10, height: 10)
            
            Text(task.title ?? "")
                .font(.subheadline)
                .foregroundColor(task.completed ? .secondary : .primary)
                .strikethrough(task.completed)
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

// Compact All Day Task Row for Week view
struct AllDayTaskRow: View {
    let task: Item
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(task.completed ? Color.gray : Color.red)
                .frame(width: 8, height: 8)
            
            Text(task.title ?? "")
                .font(.system(size: 11))
                .foregroundColor(.black)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.red.opacity(0.15))
        )
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
    }
}
