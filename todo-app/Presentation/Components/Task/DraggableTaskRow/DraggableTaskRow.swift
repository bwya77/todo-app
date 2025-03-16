//
//  DraggableTaskRow.swift
//  todo-app
//
//  Created on 3/15/25.
//

import SwiftUI
import CoreData

struct DraggableTaskRow: View {
    let task: Item
    let onToggleComplete: (Item) -> Void
    let viewType: ViewType
    let onReorder: ((Item, Item) -> Void)?
    
    @State private var isTargeted = false
    @State private var isDragging = false
    
    init(task: Item, 
         onToggleComplete: @escaping (Item) -> Void, 
         viewType: ViewType, 
         onReorder: ((Item, Item) -> Void)? = nil) {
        self.task = task
        self.onToggleComplete = onToggleComplete
        self.viewType = viewType
        self.onReorder = onReorder
    }
    
    var body: some View {
        TaskRow(task: task, onToggleComplete: onToggleComplete, viewType: viewType)
            .opacity(isDragging ? 0.5 : 1.0)
            .background(isTargeted ? Color.blue.opacity(0.1) : Color.clear)
            .animation(.easeInOut(duration: 0.2), value: isTargeted)
            .animation(.easeInOut(duration: 0.2), value: isDragging)
            .onDrag {
                // Start drag operation
                self.isDragging = true
                
                // Create a data representation with the task ID
                let itemData = ["taskID": task.id?.uuidString ?? "unknown"]
                let itemProvider = NSItemProvider()
                
                if let data = try? JSONEncoder().encode(itemData) {
                    itemProvider.registerDataRepresentation(forTypeIdentifier: "com.todoapp.taskid", 
                                                         visibility: .all) { completion in
                        completion(data, nil)
                        return nil
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.isDragging = true
                }
                
                return itemProvider
            }
            .onDrop(of: ["com.todoapp.taskid"], isTargeted: $isTargeted) { items -> Bool in
                guard let item = items.first else { return false }
                
                item.loadDataRepresentation(forTypeIdentifier: "com.todoapp.taskid") { data, error in
                    guard 
                        let data = data,
                        let itemData = try? JSONDecoder().decode([String: String].self, from: data),
                        let sourceTaskID = itemData["taskID"],
                        let sourceTaskUUID = UUID(uuidString: sourceTaskID),
                        let sourceTask = findTask(with: sourceTaskUUID),
                        let onReorder = self.onReorder 
                    else {
                        return
                    }
                    
                    // Call the reorder callback on the main thread
                    DispatchQueue.main.async {
                        onReorder(sourceTask, self.task)
                        
                        // Reset UI state after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.isDragging = false
                            self.isTargeted = false
                        }
                    }
                }
                
                return true
            }
            .onChange(of: isTargeted) { newValue in
                // No haptic feedback for macOS
            }
    }
    
    // Helper function to find a task by ID
    private func findTask(with id: UUID) -> Item? {
        guard let context = task.managedObjectContext else { return nil }
        
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error finding task with ID \(id): \(error)")
            return nil
        }
    }
}
