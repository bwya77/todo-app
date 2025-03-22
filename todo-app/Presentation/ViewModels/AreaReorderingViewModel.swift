import Foundation
import CoreData
import SwiftUI
import Combine

/// View model for area reordering in the sidebar
class AreaReorderingViewModel: ObservableObject {
    @Published var areas: [Area] = []
    private var context: NSManagedObjectContext?
    private var cancellables = Set<AnyCancellable>()
    
    init(context: NSManagedObjectContext? = nil) {
        self.context = context
        
        let viewContext = PersistenceController.shared.container.viewContext
        self.context = viewContext
        self.fetchAreas()
        
        // Set up a notification to refresh areas when Core Data changes
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.fetchAreas()
            }
            .store(in: &cancellables)
    }
    
    /// Fetches all areas ordered by display order
    func fetchAreas() {
        guard let context = self.context else { return }
        
        let fetchRequest: NSFetchRequest<Area> = Area.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Area.displayOrder, ascending: true)]
        
        do {
            self.areas = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching areas: \(error.localizedDescription)")
        }
    }
    
    /// Reorders areas based on source and destination indices
    /// - Parameters:
    ///   - fromOffsets: The source indices
    ///   - toOffset: The destination index
    func reorderAreas(fromOffsets: IndexSet, toOffset: Int) {
        guard let context = self.context else { return }
        
        // Create a mutable copy of the areas
        var mutableAreas = self.areas
        
        // Apply the move in the local array
        mutableAreas.move(fromOffsets: fromOffsets, toOffset: toOffset)
        
        // Update the display order
        for (index, area) in mutableAreas.enumerated() {
            area.displayOrder = Int32(index)
        }
        
        // Save the changes to Core Data
        do {
            try context.save()
            
            // Update the published property
            self.areas = mutableAreas
        } catch {
            print("Error saving area reordering: \(error.localizedDescription)")
        }
    }
    
    /// Adds a new area with the given name and color
    /// - Parameters:
    ///   - name: The name of the area
    ///   - color: The color for the area
    func addArea(name: String, color: String) {
        guard let context = self.context else { return }
        
        _ = Area.create(name: name, color: color, in: context)
        
        do {
            try context.save()
            fetchAreas()
        } catch {
            print("Error adding area: \(error.localizedDescription)")
        }
    }
    
    /// Deletes the specified area
    /// - Parameter area: The area to delete
    func deleteArea(_ area: Area) {
        guard let context = self.context else { return }
        
        context.delete(area)
        
        do {
            try context.save()
            fetchAreas()
        } catch {
            print("Error deleting area: \(error.localizedDescription)")
        }
    }
}
