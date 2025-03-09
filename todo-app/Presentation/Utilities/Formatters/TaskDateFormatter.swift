//
//  TaskDateFormatter.swift
//  todo-app
//
//  Created on 3/9/25.
//

import Foundation

/// Utility class for formatting dates in task-related views
public struct TodoAppTaskDateFormatter {
    /// Formats a date for display in task rows and lists
    public static func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            // Format as day of week if in current week
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day of week
            return formatter.string(from: date)
        } else {
            // Otherwise use a standard date format
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    /// Formats a time component of a date
    public static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    /// Formats a date with both date and time for detailed views
    public static func formatDateWithTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
