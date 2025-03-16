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
    
    // Task being currently dragged over
    @Published var currentTaskUnderDrag: String? = nil
    
    // Animation properties for temporary displacement
    @Published var displacedTasks: Set<String> = []
    
    /// Start a dragging operation
    func startDragging(taskId: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.isDragging = true
            self.draggedTaskId = taskId
            self.targetTaskId = nil
            self.currentTaskUnderDrag = nil
            self.displacedTasks.removeAll()
        }
    }
    
    /// End the current dragging operation and reset all state
    func endDragging() {
        // Clean up immediately without animation to avoid stale visual states
        self.isDragging = false
        self.draggedTaskId = nil
        self.targetTaskId = nil
        self.currentTaskUnderDrag = nil
        self.displacedTasks.removeAll()
        self.currentDragPosition = .zero
    }
    
    /// Register a row with its geometry for drop target calculation
    func registerRow(taskId: String, frame: CGRect) {
        rows[taskId] = frame
    }
    
    /// Calculate the task that should be displaced based on current drag position
    func updateTargetForPosition(_ position: CGPoint) {
        self.currentDragPosition = position
        
        // Sort rows by vertical position
        let sortedRows = rows.sorted { $0.value.minY < $1.value.minY }
        
        // Find the insertion point between tasks
        for (index, (taskId, frame)) in sortedRows.enumerated() {
            // Skip if this is the task being dragged
            if taskId == draggedTaskId { continue }
            
            let threshold = frame.minY + (frame.height / 2)
            
            // If the drag position is above the middle of this task
            if position.y < threshold {
                // We found our target - this is where we want to insert
                setTargetTask(taskId: taskId, isAbove: true)
                return
            }
            
            // If this is the last task and we're below its midpoint
            if index == sortedRows.count - 1 && position.y >= threshold {
                setTargetTask(taskId: taskId, isAbove: false)
                return
            }
        }
    }
    
    /// Update the current target task for insertion
    private func setTargetTask(taskId: String, isAbove: Bool) {
        if targetTaskId != taskId {
            withAnimation(.easeInOut(duration: 0.15)) {
                self.targetTaskId = taskId
                updateDisplacedTasks(for: taskId, insertAbove: isAbove)
            }
        }
    }
    
    /// Check if a task should be displaced during drag
    func shouldDisplaceTask(taskId: String) -> Bool {
        guard let draggedId = draggedTaskId, draggedId != taskId else { return false }
        return displacedTasks.contains(taskId)
    }
    
    /// Get the insert position relative to a task (above or below)
    func getInsertPosition(for taskId: String) -> InsertPosition? {
        guard taskId == targetTaskId else { return nil }
        
        if let targetFrame = rows[taskId] {
            let threshold = targetFrame.minY + (targetFrame.height / 2)
            return currentDragPosition.y < threshold ? .above : .below
        }
        
        return nil
    }
    
    /// Update the set of tasks that should be displaced
    private func updateDisplacedTasks(for targetId: String, insertAbove: Bool) {
        displacedTasks.removeAll()
        
        // Sort rows by vertical position
        let sortedRows = rows.sorted { $0.value.minY < $1.value.minY }
        
        // Find the target index
        guard let targetIndex = sortedRows.firstIndex(where: { $0.0 == targetId }) else { return }
        
        // If inserting above the target, displace the target and everything below
        // If inserting below, only displace everything below the target
        let startIndex = insertAbove ? targetIndex : targetIndex + 1
        
        // Add all tasks from the start index to the end to displaced tasks
        for i in startIndex..<sortedRows.count {
            if sortedRows[i].0 != draggedTaskId {
                displacedTasks.insert(sortedRows[i].0)
            }
        }
    }
}

enum InsertPosition {
    case above
    case below
}