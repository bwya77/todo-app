//
//  AppColors.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/8/25.
//

import SwiftUI

struct AppColors {
    // Main app colors
    static let background = Color.white
    static let secondaryBackground = Color.gray.opacity(0.05)
    
    // UI colors from legacy implementation
    static let selectedIconColor = Color(red: 41/255, green: 122/255, blue: 188/255) // RGB(41,122,188)
    static let sidebarBackground = Color(red: 248/255, green: 250/255, blue: 251/255) // RGB(248,250,251)
    static let sidebarHover = Color(red: 223/255, green: 237/255, blue: 251/255) // RGB(223,237,251)
    static let contentBackground = Color.white
    static let headerBackground = Color.white
    static let addTaskButtonColor = Color(red: 52/255, green: 152/255, blue: 219/255) // RGB(52,152,219)
    
    // Calendar-specific colors
    static let calendarGridlineColor = Color.gray.opacity(0.2)
    static let calendarTodayHighlight = Color.blue.opacity(0.15)
    static let calendarTimeIndicator = Color.red
    static let weekendBackground = Color(red: 248/255, green: 248/255, blue: 248/255) // Very light grey
    static let weekendGridlineColor = Color(nsColor: NSColor(calibratedRed: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1.0)) // Darker for weekend
    static let todayHighlight = Color(red: 0.0, green: 0.47, blue: 0.9)
    
    // Priority colors
    static let priorityHigh = Color.red
    static let priorityMedium = Color.orange
    static let priorityLow = Color.blue
    static let priorityNone = Color.gray
    
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
    
    // Text colors
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    
    // Get priority color based on value
    static func priorityColor(_ priority: Int16) -> Color {
        switch priority {
        case 3: return priorityHigh
        case 2: return priorityMedium
        case 1: return priorityLow
        default: return priorityNone
        }
    }
}
