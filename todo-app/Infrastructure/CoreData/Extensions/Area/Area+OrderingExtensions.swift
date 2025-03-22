//
//  Area+OrderingExtensions.swift
//  todo-app
//
//  Created on 3/22/25.
//

import Foundation
import CoreData

extension Area: Displayable {
    /// The default sort order attribute name in the data model
    static let orderAttributeName = "displayOrder"
    
    /// Update the display order for a set of areas
    /// - Parameters:
    ///   - areas: An array of areas to reorder
    ///   - context: The managed object context
    static func updateDisplayOrder(for areas: [Area], in context: NSManagedObjectContext) {
        for (index, area) in areas.enumerated() {
            area.displayOrder = Int32(index)
        }
        
        try? context.save()
    }
    
    /// Reorder areas based on source and destination indices
    /// - Parameters:
    ///   - sourceIndices: The source indices of the areas to be moved
    ///   - destinationIndex: The destination index
    ///   - context: The managed object context
    static func reorder(from sourceIndices: IndexSet, to destinationIndex: Int, in context: NSManagedObjectContext) {
        // Fetch all areas, ordered by display order
        let fetchRequest: NSFetchRequest<Area> = Area.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Area.displayOrder, ascending: true)]
        
        do {
            let areas = try context.fetch(fetchRequest)
            
            // Convert the areas to a mutable array
            var mutableAreas = areas
            
            // Perform the reordering
            mutableAreas.move(fromOffsets: sourceIndices, toOffset: destinationIndex)
            
            // Update the display order for each area
            Area.updateDisplayOrder(for: mutableAreas, in: context)
        } catch {
            print("Error reordering areas: \(error.localizedDescription)")
        }
    }
    
    /// Direct access method for display order (adding to avoid conflict with generated property)
    func getDisplayOrder() -> Int32 {
        // Use direct access to the property
        return self.value(forKey: "displayOrder") as? Int32 ?? 9999
    }
    
    /// Direct setting method for display order
    func setDisplayOrder(_ newValue: Int32) {
        // Use direct access to set the property
        self.setValue(newValue, forKey: "displayOrder")
    }
    
    /// Updates display order and persists changes
    func updateDisplayOrder(_ newOrder: Int32, save: Bool = true) {
        // Set the display order directly
        self.setDisplayOrder(newOrder)
        
        if save, let context = managedObjectContext {
            do {
                try context.save()
                print("Saved display order \(newOrder) for area \(name ?? "unknown")")
            } catch {
                print("Error saving display order: \(error)")
            }
        }
    }
}
