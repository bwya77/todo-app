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
    @Binding var dropTargetId: UUID?

    var moveAction: (IndexSet, Int) -> Void
    
    // MARK: - DropDelegate Methods
    
    /// Called when a drag operation enters a drop area
    func dropEntered(info: DropInfo) {
        print("🔄 Drop entered")
        // Ensure we have distinct active and target items
        guard item != active, let current = active else { 
            print("⚠️ Cannot reorder: active and target are the same or active is nil")
            return 
        }
        
        // Clear any previous drop target and set the current one
        // Set the ID as the drop target ID - centralizing to ensure only one line appears
        if let itemId = item.id as? UUID {
            DispatchQueue.main.async {
                // Use async to break potential binding cycles
                self.dropTargetId = itemId
            }
        }
        
        // Find the item indices
        guard let from = items.firstIndex(of: current) else { 
            print("⚠️ Cannot find source index")
            return 
        }
        guard let to = items.firstIndex(of: item) else { 
            print("⚠️ Cannot find target index")
            return 
        }
        
        hasChangedLocation = true
        print("✅ Found source: \(from) and target: \(to)")
        
        if items[to] != current {
            // This gives the same smooth experience as the project view
            // For vertical list dragging, this produces the best visual effect
            let adjustedTargetPosition = to > from ? to + 1 : to
            
            // Ensure the target position is within bounds
            let safePosition = min(adjustedTargetPosition, items.count)
            
            print("🔄 Moving item from \(from) to \(safePosition)")
            
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
        print("✅ Drop completed")
        hasChangedLocation = false
        
        // Clear drop target and active state
        DispatchQueue.main.async {
            self.dropTargetId = nil
            self.active = nil
        }
        return true
    }
}

/// Handles drag operations that end outside the ReorderableForEach
struct ReorderableDropOutsideDelegate<Item: Reorderable>: DropDelegate {
    
    // MARK: - Properties
    
    @Binding
    var active: Item?
    
    @Binding
    var dropTargetId: UUID?
    
    // MARK: - DropDelegate Methods
    
    /// Called periodically while a drag operation continues over a drop area
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    /// Called when a drag operation is completed within this drop area
    func performDrop(info: DropInfo) -> Bool {
        print("🔄 Drop outside completed")
        
        // Clear drop target and active
        DispatchQueue.main.async {
            self.dropTargetId = nil
            self.active = nil
        }
        return true
    }
}
