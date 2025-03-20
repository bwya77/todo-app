//
//  ReorderableDelegates.swift
//  todo-app
//
//  Created on 3/19/25.
//

import SwiftUI
import Foundation

/// Handles the drag and drop operation within the ReorderableForEach
struct ReorderableDragRelocateDelegate<Item: Reorderable>: DropDelegate {
    
    // MARK: - Properties
    
    let item: Item
    var items: [Item]
    
    @Binding var active: Item?
    @Binding var hasChangedLocation: Bool

    var moveAction: (IndexSet, Int) -> Void
    
    // MARK: - DropDelegate Methods
    
    /// Called when a drag operation enters a drop area
    func dropEntered(info: DropInfo) {
        guard item != active, let current = active else { return }
        guard let from = items.firstIndex(of: current) else { return }
        guard let to = items.firstIndex(of: item) else { return }
        hasChangedLocation = true
        if items[to] != current {
            // This gives the same smooth experience as the project view
            // For vertical list dragging, this produces the best visual effect
            let adjustedTargetPosition = to > from ? to + 1 : to
            
            // Ensure the target position is within bounds
            let safePosition = min(adjustedTargetPosition, items.count)
            
            // Apply the move action with the more natural-feeling target position
            // Use animation with a slight delay for the smooth sliding effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                moveAction(IndexSet(integer: from), safePosition)
            }
        }
    }
    
    /// Called periodically while a drag operation continues over a drop area
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    /// Called when a drag operation is completed within this drop area
    func performDrop(info: DropInfo) -> Bool {
        hasChangedLocation = false
        active = nil
        return true
    }
}

/// Handles drag operations that end outside the ReorderableForEach
struct ReorderableDropOutsideDelegate<Item: Reorderable>: DropDelegate {
    
    // MARK: - Properties
    
    @Binding
    var active: Item?
    
    // MARK: - DropDelegate Methods
    
    /// Called periodically while a drag operation continues over a drop area
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    /// Called when a drag operation is completed within this drop area
    func performDrop(info: DropInfo) -> Bool {
        active = nil
        return true
    }
}
