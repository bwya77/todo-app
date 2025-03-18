//
//  TaskDragModifier.swift
//  todo-app
//
//  Created on 3/17/25.
//

import SwiftUI

/// A custom modifier for handling drag gestures within List views
struct TaskDragModifier: ViewModifier {
    let item: Item
    
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle()) // Ensure entire cell is draggable
    }
}

extension View {
    /// Applies a drag gesture modifier for task items
    /// - Parameter item: The task item to modify
    /// - Returns: Modified view
    func taskDraggable(item: Item) -> some View {
        modifier(TaskDragModifier(item: item))
    }
}
