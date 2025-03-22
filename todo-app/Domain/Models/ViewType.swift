//
//  ViewType.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//  Refactored according to improvement plan on 3/7/25.
//  Updated on 3/9/25 to remove addTask case
//

import Foundation
import SwiftUI

enum ViewType: Hashable {
    case inbox
    case today
    case upcoming
    case completed
    case filters
    case project
    case area
    
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
        case .project:
            return "Project"
        case .area:
            return "Area"
        }
    }
    
    var iconName: String {
        switch self {
        case .inbox:
            return "tray.full.fill"
        case .today:
            let dayNumber = Calendar.current.component(.day, from: Date())
            return "\(dayNumber).square.fill"
        case .upcoming:
            return "calendar.badge.clock"
        case .completed:
            return "checkmark.circle.fill"
        case .filters:
            return "tag.fill"
        case .project:
            return "folder"
        case .area:
            return "cube.fill"
        }
    }
}
