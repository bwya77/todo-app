//
//  ViewType.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import Foundation
import SwiftUI

enum ViewType: Hashable {
    case inbox
    case today
    case upcoming
    case completed
    case filters
    case addTask
    case project
    
    var name: String {
        switch self {
        case .inbox:
            return "Inbox"
        case .today:
            return "Today"
        case .upcoming:
            return "Upcoming"
        case .completed:
            return "Completed"
        case .filters:
            return "Filters"
        case .addTask:
            return "Add Task"
        case .project:
            return "Project"
        }
    }
    
    var iconName: String {
        switch self {
        case .inbox:
            return "tray"
        case .today:
            return "calendar"
        case .upcoming:
            return "calendar.badge.clock"
        case .completed:
            return "checkmark.circle"
        case .filters:
            return "line.horizontal.3.decrease.circle"
        case .addTask:
            return "plus.circle"
        case .project:
            return "folder"
        }
    }
}
