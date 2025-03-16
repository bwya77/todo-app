//
//  ProjectDetailView+DragDrop.swift
//  todo-app
//
//  Created on 3/15/25.
//

import Foundation
import CoreData
import SwiftUI

// Simple extension without a static helper
extension ProjectDetailView {
    /// Handle reordering when a task is dragged and dropped onto another task
    /// - Parameters:
    ///   - sourceTask: The task being dragged
    ///   - targetTask: The task being dropped onto
    func reorderTask(_ sourceTask: Item, _ targetTask: Item) {
        // Don't reorder if it's the same task
        guard sourceTask != targetTask else { return }
        
        // Use the Item extension's moveBeforeItem method directly
        sourceTask.moveBeforeItem(targetTask)
        
        // No need to force refresh - moveBeforeItem saves the context which triggers FetchedResults to update
        // If any manual refresh is needed, it should be handled in ProjectDetailView itself
    }
}
