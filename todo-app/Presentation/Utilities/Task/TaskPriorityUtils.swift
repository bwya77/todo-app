//
//  TaskPriorityUtils.swift
//  todo-app
//
//  Created on 3/9/25.
//

import SwiftUI

/// Utility class for working with task priorities
public struct TaskPriorityUtils {
    /// Get a human-readable label for a priority value
    public static func getPriorityLabel(_ priority: Int16) -> String {
        switch priority {
        case 3: return "High"
        case 2: return "Medium"
        case 1: return "Low"
        default: return "None"
        }
    }
    
    /// Get the color for a priority value
    public static func getPriorityColor(_ priority: Int16) -> Color {
        switch priority {
        case 3: return AppColors.priorityHigh
        case 2: return AppColors.priorityMedium
        case 1: return AppColors.priorityLow
        default: return AppColors.priorityNone
        }
    }
    
    /// Get the SF Symbol icon name for a priority value
    public static func getPriorityIcon(_ priority: Int16) -> String {
        switch priority {
        case 3: return "exclamationmark.triangle.fill"
        case 2: return "exclamationmark.circle.fill"
        case 1: return "arrow.down.circle.fill"
        default: return "minus.circle.fill"
        }
    }
    
    /// Create a visual display for a priority
    public static func priorityLabel(_ priority: Int16) -> some View {
        let color = getPriorityColor(priority)
        
        return HStack(spacing: 4) {
            if priority > 0 {
                Image(systemName: getPriorityIcon(priority))
                    .font(.system(size: 12))
                Text(getPriorityLabel(priority))
                    .font(.caption)
            } else {
                EmptyView()
            }
        }
        .foregroundColor(priority == 0 ? .clear : color)
    }
}
