//
//  Entity+DebugDescription.swift
//  todo-app
//
//  Created on 3/12/25.
//

import Foundation
import CoreData

// MARK: - Item Description

extension Item {
    public override var description: String {
        let projectName = project?.name ?? "No Project"
        let tagNames = (tags as? Set<Tag>)?.map { $0.name ?? "Unnamed" }.joined(separator: ", ") ?? "No Tags"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        let dueDateStr = dueDate != nil ? dateFormatter.string(from: dueDate!) : "No Due Date"
        let completionStatus = completed ? "Completed" : "Incomplete"
        let loggedStatus = logged ? "Logged" : "Not Logged"
        
        return """
        Item: \(title ?? "Untitled")
        ID: \(id?.uuidString ?? "No ID")
        Project: \(projectName)
        Tags: \(tagNames)
        Priority: \(Priority.from(priority).description)
        Due: \(dueDateStr)
        Status: \(completionStatus), \(loggedStatus)
        """
    }
}

// MARK: - Project Description

extension Project {
    public override var description: String {
        let itemCount = (items as? Set<Item>)?.count ?? 0
        // Calculate counts directly since we might not have access to the extension methods yet
        let activeCount = (items as? Set<Item>)?.filter { !$0.completed }.count ?? 0
        let completedCount = (items as? Set<Item>)?.filter { $0.completed }.count ?? 0
        
        // Calculate completion percentage
        let totalCount = activeCount + completedCount
        let percentComplete = totalCount > 0 ?
            String(format: "%.1f%%", Double(completedCount) / Double(totalCount) * 100) :
            "0.0%"
        
        return """
        Project: \(name ?? "Untitled")
        ID: \(id?.uuidString ?? "No ID")
        Color: \(color ?? "None")
        Items: \(itemCount) total, \(activeCount) active, \(completedCount) completed
        Progress: \(percentComplete)
        """
    }
}

// MARK: - Tag Description

extension Tag {
    public override var description: String {
        let itemCount = (items as? Set<Item>)?.count ?? 0
        
        return """
        Tag: \(name ?? "Untitled")
        ID: \(id?.uuidString ?? "No ID")
        Color: \(color ?? "None")
        Items: \(itemCount)
        """
    }
}
