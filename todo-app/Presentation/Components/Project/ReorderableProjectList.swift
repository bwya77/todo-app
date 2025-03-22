//
//  ReorderableProjectList.swift
//  todo-app
//
//  Created on 3/20/25.
//

import SwiftUI
import CoreData

/// Custom drop delegate for mixed items reordering
struct MixedItemDropDelegate: DropDelegate {
    let index: Int
    var items: [Any]
    @Binding var draggedItem: Any?
    var moveAction: (Int, Int) -> Void
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem else { return }
        
        // Find the source index
        let sourceIndex = findIndex(for: draggedItem)
        guard sourceIndex != index else { return } // Don't do anything if dropping on self
        guard sourceIndex >= 0 else { return } // Invalid source
        
        // Perform the move
        moveAction(sourceIndex, index)
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        // Reset the dragged item when the drop is complete
        draggedItem = nil
        return true
    }
    
    // Helper to find the index of an item
    private func findIndex(for item: Any) -> Int {
        if let area = item as? Area, let index = items.firstIndex(where: { ($0 as? Area)?.id == area.id }) {
            return index
        } else if let project = item as? Project, let index = items.firstIndex(where: { ($0 as? Project)?.id == project.id }) {
            return index
        }
        return -1
    }
}

/// A reorderable list of projects and areas that supports drag and drop reordering
struct ReorderableProjectList: View {
    /// Selected view type
    @Binding var selectedViewType: ViewType
    
    /// Selected project
    @Binding var selectedProject: Project?
    
    /// Selected area
    @Binding var selectedArea: Area?
    
    /// Access to managed object context
    @Environment(\.managedObjectContext) private var viewContext
    
    /// Initialize with selections
    /// - Parameters:
    ///   - selectedViewType: Binding to the selected view type
    ///   - selectedProject: Binding to the selected project
    ///   - selectedArea: Binding to the selected area
    init(selectedViewType: Binding<ViewType> = .constant(.project),
         selectedProject: Binding<Project?> = .constant(nil),
         selectedArea: Binding<Area?> = .constant(nil)) {
        self._selectedViewType = selectedViewType
        self._selectedProject = selectedProject
        self._selectedArea = selectedArea
    }
    
    /// The view model for project reordering
    @StateObject private var projectViewModel = ProjectReorderingViewModel()
    
    /// The view model for area reordering
    @StateObject private var areaViewModel = AreaReorderingViewModel()
    
    /// Whether to show completed projects
    @State private var showCompletedProjects = false
    
    // State for drag and hover tracking
    @State private var hoveredProject: Project? = nil
    @State private var hoveredArea: Area? = nil
    @State private var draggedItem: Any? = nil
    
    // Helper function to determine the background color for a project
    private func backgroundColorFor(project: Project) -> Color {
        let isSelected = selectedViewType == .project && selectedProject?.id == project.id
        let isHovered = hoveredProject?.id == project.id
        
        if isSelected {
            // Selected state - use the lighter shade of project color
            return AppColors.lightenColor(AppColors.getColor(from: project.color), by: 0.7)
        } else if isHovered {
            // Hover state - use a very light shade of project color
            return AppColors.lightenColor(AppColors.getColor(from: project.color), by: 0.9)
        } else {
            // Normal state - transparent
            return Color.clear
        }
    }
    
    // Helper function to determine the background color for an area
    private func backgroundColorFor(area: Area) -> Color {
        let isSelected = selectedViewType == .area && selectedArea?.id == area.id
        let isHovered = hoveredArea?.id == area.id
        
        if isSelected {
            // Selected state - use the lighter shade of area color
            return AppColors.lightenColor(AppColors.getColor(from: area.color), by: 0.7)
        } else if isHovered {
            // Hover state - use a very light shade of area color
            return AppColors.lightenColor(AppColors.getColor(from: area.color), by: 0.9)
        } else {
            // Normal state - transparent
            return Color.clear
        }
    }
    
    var body: some View {
        VStack(spacing: 6) { // Add spacing between items
            // Add spacing between Completed and the first item
            Spacer().frame(height: 16)
            
            // Combine areas and projects in a single list, sorted by displayOrder
            let combinedItems = getCombinedItems()
            
            ForEach(Array(combinedItems.indices), id: \.self) { index in
                if let area = combinedItems[index] as? Area {
                    // Render area row
                    HStack(spacing: 10) {
                        AreaRowView(
                            area: area,
                            isSelected: selectedViewType == .area && selectedArea?.id == area.id
                        )
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(backgroundColorFor(area: area))
                    )
                    .onTapGesture {
                        selectedViewType = .area
                        selectedArea = area
                    }
                    .onHover { isHovered in
                        hoveredArea = isHovered ? area : nil
                        
                        if isHovered && !(selectedViewType == .area && selectedArea?.id == area.id) {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                    .onDrag {
                        self.draggedItem = area
                        return NSItemProvider(object: "area-\(index)" as NSString)
                    }
                    .onDrop(of: [.text], delegate: MixedItemDropDelegate(
                        index: index,
                        items: combinedItems,
                        draggedItem: $draggedItem,
                        moveAction: { fromIndex, toIndex in
                            reorderItems(from: fromIndex, to: toIndex)
                        }
                    ))
                } else if let project = combinedItems[index] as? Project {
                    // Render project row
                    HStack(spacing: 10) {
                        ProjectRowView(
                            project: project,
                            isSelected: selectedViewType == .project && selectedProject?.id == project.id
                        )
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(backgroundColorFor(project: project))
                    )
                    .onTapGesture {
                        selectedViewType = .project
                        selectedProject = project
                    }
                    .onHover { isHovered in
                        hoveredProject = isHovered ? project : nil
                        
                        if isHovered && !(selectedViewType == .project && selectedProject?.id == project.id) {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                    .onDrag {
                        self.draggedItem = project
                        return NSItemProvider(object: "project-\(index)" as NSString)
                    }
                    .onDrop(of: [.text], delegate: MixedItemDropDelegate(
                        index: index,
                        items: combinedItems,
                        draggedItem: $draggedItem,
                        moveAction: { fromIndex, toIndex in
                            reorderItems(from: fromIndex, to: toIndex)
                        }
                    ))
                }
            }
        }
    }
    
    // Helper method to get combined list of areas and projects sorted by displayOrder
    private func getCombinedItems() -> [Any] {
        var combinedItems: [(item: Any, order: Int32)] = []
        
        // Add areas with their display order
        for area in areaViewModel.areas {
            combinedItems.append((item: area, order: area.displayOrder))
        }
        
        // Add projects with their display order
        for project in projectViewModel.projects {
            combinedItems.append((item: project, order: project.displayOrder))
        }
        
        // Sort by display order
        combinedItems.sort { $0.order < $1.order }
        
        // Return just the items
        return combinedItems.map { $0.item }
    }
    
    // Reorder items within the combined list
    private func reorderItems(from sourceIndex: Int, to destinationIndex: Int) {
        var updatedItems = getCombinedItems()
        
        // If source is before destination, we need to adjust destination index
        let adjustedDestIndex = sourceIndex < destinationIndex ? destinationIndex - 1 : destinationIndex
        
        // Move the item within the array
        let itemToMove = updatedItems.remove(at: sourceIndex)
        updatedItems.insert(itemToMove, at: adjustedDestIndex)
        
        // Update display orders for all items
        for (idx, item) in updatedItems.enumerated() {
            if let area = item as? Area {
                area.displayOrder = Int32(idx * 10)
            } else if let project = item as? Project {
                project.displayOrder = Int32(idx * 10)
            }
        }
        
        // Save context
        do {
            try viewContext.save()
            // Refresh data
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.areaViewModel.fetchAreas()
                self.projectViewModel.fetchProjects()
            }
        } catch {
            print("Error saving reordered items: \(error)")
        }
    }
}

/// A simple row view for projects in the list
struct ProjectRowView: View {
    let project: Project
    let isSelected: Bool
    
    @Environment(\.managedObjectContext) private var viewContext
    
    init(project: Project, isSelected: Bool = false) {
        self.project = project
        self.isSelected = isSelected
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Project completion indicator or color indicator
            ProjectCompletionIndicator(
                project: project,
                isSelected: isSelected,
                viewContext: viewContext
            )
            .id("sidebar-indicator-\(project.id?.uuidString ?? UUID().uuidString)")
            
            // Project name
            Text(project.name ?? "Unnamed Project")
                .lineLimit(1)
                .foregroundStyle(isSelected ? AppColors.selectedTextColor : .black)
                .font(.system(size: 14))
            
            Spacer()
            
            // Task count badge
            if project.activeTaskCount > 0 {
                Text("\(project.activeTaskCount)")
                    .foregroundColor(isSelected ? AppColors.selectedTextColor : .secondary)
                    .font(.system(size: 14))
            }
        }
    }
}

// Using the AreaRowView from ReorderableAreaList.swift

// Preview provider for SwiftUI canvas
struct ReorderableProjectList_Previews: PreviewProvider {
    static var previews: some View {
        ReorderableProjectList()
            .frame(width: 250, height: 400)
    }
}
