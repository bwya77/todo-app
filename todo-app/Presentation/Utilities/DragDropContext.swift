//
//  DragDropContext.swift
//  todo-app
//
//  Created on 3/15/25.
//

import SwiftUI
import Combine

/// Shared context for coordinating drag and drop operations across the app
class DragDropContext: ObservableObject {
    @Published var isDragging: Bool = false
    @Published var draggedTaskId: String? = nil
    @Published var targetTaskId: String? = nil
    
    // Track the vertical position of the mouse during drag operations
    @Published var currentDragPosition: CGPoint = .zero
    
    // For calculating insertion locations
    @Published var rows: [String: CGRect] = [:]
    
    // Multiple drop targets can register themselves
    @Published var dropTargetIds: [String: CGRect] = [:]
    
    // Task being currently dragged over
    @Published var currentTaskUnderDrag: String? = nil
    
    // Animation properties for temporary displacement
    @Published var displacedTasks: Set<String> = []
    
    /// Start a dragging operation
    func startDragging(taskId: String) {
        self.isDragging = true
        self.draggedTaskId = taskId
    }
    
    /// Update the current target task for insertion
    func setTargetTask(taskId: String) {
        if targetTaskId != taskId {
            withAnimation(.easeInOut(duration: 0.15)) {
                self.targetTaskId = taskId
            }
        }
    }
    
    /// End the current dragging operation and reset all state
    func endDragging() {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.isDragging = false
            self.draggedTaskId = nil
            self.targetTaskId = nil
            self.currentTaskUnderDrag = nil
            self.displacedTasks = []
        }
    }
    
    /// Register a row with its geometry for drop target calculation
    func registerRow(taskId: String, frame: CGRect) {
        rows[taskId] = frame
    }
    
    /// Called when the drag is successful
    func showSuccessFeedback() {
        // Future: add haptic feedback or animations
    }
    
    /// Calculate the task that should be displaced based on current drag position
    func updateTargetForPosition(_ position: CGPoint) {
        // Get the closest task to the current position
        if let (taskId, _) = rows.min(by: { 
            abs($0.value.midY - position.y) < abs($1.value.midY - position.y)
        }) {
            self.setTargetTask(taskId: taskId)
        }
    }
    
    /// Check if a task should be displaced during drag
    func shouldDisplaceTask(taskId: String) -> Bool {
        return targetTaskId == taskId
    }
}