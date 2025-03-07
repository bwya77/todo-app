//
//  CalendarColors.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/6/25.
//

import SwiftUI

struct CalendarColors {
    // Background colors for calendar cells
    static let weekdayBackground: Color = .white
    static let weekendBackground: Color = Color.gray.opacity(0.12) // Light grey for weekends
    
    // Check if a date is a weekend (Saturday or Sunday)
    static func isWeekend(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        // In Calendar, 1 is Sunday and 7 is Saturday
        return weekday == 1 || weekday == 7
    }
    
    // Specifically check if date is a Saturday
    static func isSaturday(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 7
    }
    
    // Specifically check if date is a Sunday
    static func isSunday(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1
    }
    
    // Get the appropriate background color for a calendar cell based on date
    static func backgroundColorForDate(_ date: Date, isCurrentMonth: Bool = true) -> Color {
        // Always use the same weekend color regardless of month
        if isWeekend(date) {
            return weekendBackground
        }
        
        // For weekdays outside current month, use slightly transparent white
        if !isCurrentMonth {
            return weekdayBackground.opacity(0.97)
        }
        
        return weekdayBackground
    }
}
