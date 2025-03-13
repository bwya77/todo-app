//
//  Priority.swift
//  todo-app
//
//  Created on 3/12/25.
//

import Foundation
import SwiftUI

/// Priority enum for tasks
public enum Priority: Int16, CaseIterable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3
    
    var description: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    /// Returns the display name for UI purposes
    var displayName: String {
        switch self {
        case .none: return "No Priority"
        case .low: return "Low Priority"
        case .medium: return "Medium Priority"
        case .high: return "High Priority"
        }
    }
    
    /// Returns the SF Symbol icon name for this priority
    var iconName: String {
        switch self {
        case .none: return "minus.circle.fill"
        case .low: return "arrow.down.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .high: return "exclamationmark.triangle.fill"
        }
    }
    
    /// Returns the color for this priority
    var color: Color {
        switch self {
        case .none: return Color.gray.opacity(0.5)
        case .low: return Color.blue
        case .medium: return Color.orange
        case .high: return Color.red
        }
    }
    
    /// Returns the next priority in a cycle
    var next: Priority {
        switch self {
        case .none: return .low
        case .low: return .medium
        case .medium: return .high
        case .high: return .none
        }
    }
    
    /// Create a Priority enum from an Int16 value
    /// - Parameter value: The raw Int16 value
    /// - Returns: The corresponding Priority enum, defaulting to .none if invalid
    static func from(_ value: Int16) -> Priority {
        return Priority(rawValue: value) ?? .none
    }
}
