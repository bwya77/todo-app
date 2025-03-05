//
//  ColorConstants.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//

import SwiftUI

struct AppColors {
    // Make sure these colors are used consistently
    static let selectedIconColor: Color = Color(red: 41/255, green: 122/255, blue: 188/255) // RGB(41,122,188)
    static let sidebarBackground: Color = Color(red: 248/255, green: 250/255, blue: 251/255) // RGB(248,250,251)
    static let sidebarHover: Color = Color(red: 223/255, green: 237/255, blue: 251/255) // RGB(223,237,251)
    static let contentBackground: Color = Color.white
    static let headerBackground: Color = Color.white
    static let todayHighlight: Color = Color(red: 0.0, green: 0.47, blue: 0.9)
    static let addTaskButtonColor: Color = Color(red: 52/255, green: 152/255, blue: 219/255) // RGB(52,152,219)
    
    // Project and tag colors
    static let colorMap: [String: Color] = [
        "red": .red,
        "orange": .orange,
        "yellow": .yellow,
        "green": .green,
        "blue": .blue,
        "purple": .purple,
        "pink": .pink,
        "gray": .gray
    ]
    
    static func getColor(from colorName: String?) -> Color {
        guard let name = colorName, let color = colorMap[name] else {
            return .gray // Default color
        }
        return color
    }
    
    // Priority colors
    static func priorityColor(for priority: Int16) -> Color {
        switch priority {
        case 1: return .red        // High priority
        case 2: return .orange     // Medium priority
        case 3: return .blue       // Low priority
        default: return .gray      // No priority
        }
    }
}

struct AppDateFormatter {
    static let dueDateFormatter: Foundation.DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium as Foundation.DateFormatter.Style
        formatter.timeStyle = .none as Foundation.DateFormatter.Style
        return formatter
    }()
    
    static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
    
    static func formatDueDate(_ date: Date?) -> String {
        guard let date = date else { return "No due date" }
        
        let now = Date()
        let calendar = Calendar.current
        
        // If it's today
        if calendar.isDateInToday(date) {
            return "Today"
        }
        
        // If it's tomorrow
        if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        
        // If it's within the next 7 days
        if let sevenDaysFromNow = calendar.date(byAdding: .day, value: 7, to: now),
           date <= sevenDaysFromNow {
            let weekday = calendar.component(.weekday, from: date)
            let weekdaySymbols = calendar.weekdaySymbols
            return weekdaySymbols[weekday - 1] // weekday is 1-based, array is 0-based
        }
        
        // Otherwise, use the date formatter
        return dueDateFormatter.string(from: date)
    }
}
