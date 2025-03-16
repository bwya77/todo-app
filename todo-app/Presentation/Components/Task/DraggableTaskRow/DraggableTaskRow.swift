//
//  DraggableTaskRow.swift
//  todo-app
//
//  Created on 3/15/25.
//
import SwiftUI
import CoreData
import AppKit
import UniformTypeIdentifiers

/// A view that wraps TaskRow with drag and drop functionality
struct DraggableTaskRow: View {
    let task: Item
    let onToggleComplete: (Item) -> Void
    let viewType: ViewType
    let onReorder: ((Item, Item) -> Void)?
    
    @State private var isDragging = false
    @State private var isDragTarget = false
    @State private var viewHeight: CGFloat = 40
    @State private var isDisplaced = false
    
    // Environment variables for coordination between rows
    @EnvironmentObject private var dragContext: DragDropContext
    
    // Reference to viewContext for finding tasks
    @Environment(\.managedObjectContext) private var viewContext
    
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
        VStack(spacing: 0) {
            // Insert indicator when dragging above this task
            if isDragTarget, 
               dragContext.isDragging,
               dragContext.getInsertPosition(for: task.id?.uuidString ?? "") == .above {
                insertionIndicator
            }
            
            // The actual task row
            TaskRow(task: task, onToggleComplete: onToggleComplete, viewType: viewType)
                .opacity(isDragging ? 0.4 : 1.0)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ViewSizePreferenceKey.self, value: geo.size)
                            .onPreferenceChange(ViewSizePreferenceKey.self) { size in
                                self.viewHeight = size.height
                            }
                            .onAppear {
                                // Register this row's frame with the drag context
                                DispatchQueue.main.async {
                                    if let taskId = task.id?.uuidString {
                                        dragContext.registerRow(taskId: taskId, frame: geo.frame(in: .named("TaskListCoordinateSpace")))
                                    }
                                }
                            }
                    }
                )
                .offset(y: calculateOffset())
                .animation(.easeInOut(duration: 0.2), value: calculateOffset())
            
            // Insert indicator when dragging below this task
            if isDragTarget,
               dragContext.isDragging,
               dragContext.getInsertPosition(for: task.id?.uuidString ?? "") == .below {
                insertionIndicator
            }
        }
        .onChange(of: dragContext.isDragging) { _, isDragging in
            // Reset our dragging state when global drag state ends
            if !isDragging {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isDragging = false
                }
            }
        }
        .onChange(of: dragContext.targetTaskId) { _, newValue in
            // Update isDragTarget when this becomes the target
            withAnimation(.easeInOut(duration: 0.15)) {
                isDragTarget = (newValue == task.id?.uuidString)
            }
        }
        .onChange(of: dragContext.displacedTasks) { _, newValue in
            withAnimation(.easeInOut(duration: 0.15)) {
                isDisplaced = newValue.contains(task.id?.uuidString ?? "")
            }
        }
        .onDrag {
            // Start drag operation
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isDragging = true
                dragContext.startDragging(taskId: task.id?.uuidString ?? "")
            }
            
            // Create a data representation with the task ID
            let itemData = ["taskID": task.id?.uuidString ?? "unknown"]
            let itemProvider = NSItemProvider()
            
            if let data = try? JSONEncoder().encode(itemData) {
                itemProvider.registerDataRepresentation(
                    forTypeIdentifier: UTType.data.identifier, 
                    visibility: .all
                ) { completion in
                    completion(data, nil)
                    return nil
                }
            }
            
            return itemProvider
        }
        .onDrop(of: [UTType.data.identifier], isTargeted: $isDragTarget) { items, location -> Bool in
            // Ignore drops onto the item being dragged
            guard !isDragging else { return false }
            
            // Update the drag context with the current drag position
            DispatchQueue.main.async {
                dragContext.updateTargetForPosition(location)
            }
            
            // Process the drop data
            guard let item = items.first else { return false }
            
            item.loadDataRepresentation(forTypeIdentifier: UTType.data.identifier) { data, error in
                if let error = error {
                    print("Error loading drag data: \(error)")
                    return
                }
                
                guard 
                    let data = data,
                    let itemData = try? JSONDecoder().decode([String: String].self, from: data),
                    let sourceTaskID = itemData["taskID"],
                    let sourceTaskUUID = UUID(uuidString: sourceTaskID),
                    let onReorder = self.onReorder 
                else {
                    return
                }
                
                // Find the source task
                let sourceTask = findTask(with: sourceTaskUUID)
                
                // Execute the reordering on the main thread
                DispatchQueue.main.async {
                    if let sourceTask = sourceTask, sourceTask.id != self.task.id {
                        // Perform the actual reorder operation
                        onReorder(sourceTask, self.task)
                        
                        // Reset all drag states immediately after reordering
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.isDragging = false
                            self.dragContext.endDragging()
                        }
                    }
                }
            }
            
            return true
        }
    }
    
    /// Visual indicator for insertion points
    private var insertionIndicator: some View {
        Rectangle()
            .fill(Color.blue)
            .frame(height: 2)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity)
            .transition(.opacity)
    }
    
    /// Calculate vertical offset for tasks during drag operations
    private func calculateOffset() -> CGFloat {
        // If this task is being dragged, no offset needed
        if isDragging {
            return 0
        }
        
        // If not in a drag operation, no offset needed
        if !dragContext.isDragging {
            return 0
        }
        
        // If this task should be displaced, move it down
        if isDisplaced {
            return viewHeight
        }
        
        return 0
    }
    
    // Helper function to find a task by ID
    private func findTask(with id: UUID) -> Item? {
        // Try using the task's context first
        if let context = task.managedObjectContext {
            let request: NSFetchRequest<Item> = Item.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            do {
                let results = try context.fetch(request)
                if let foundTask = results.first {
                    return foundTask
                }
            } catch {
                print("Error finding task with ID \(id): \(error)")
            }
        }
        
        // Fall back to view context
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            return results.first
        } catch {
            print("Error finding task with ID \(id) in view context: \(error)")
            return nil
        }
    }
}

// Preference key for tracking view size
struct ViewSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// Custom view for the drag preview
struct TaskDragPreview: View {
    let task: Item
    
    var body: some View {
        HStack {
            // Project color indicator
            if let project = task.project, let color = project.color {
                Circle()
                    .fill(AppColors.getColor(from: color))
                    .frame(width: 12, height: 12)
                    .padding(.trailing, 5)
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 12, height: 12)
                    .padding(.trailing, 5)
            }
            
            // Task details
            VStack(alignment: .leading) {
                Text(task.title ?? "Untitled Task")
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.9))
        .cornerRadius(6)
        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
    }
}
