//
//  ReorderableProjectList.swift
//  todo-app
//
//  Created on 3/20/25.
//

import SwiftUI
import CoreData

/// Custom drop delegate for mixed items reordering with area support
struct MixedItemDropDelegate: DropDelegate {
    let index: Int
    var items: [Any]
    @Binding var draggedItem: Any?
    @Binding var isDraggingOver: UUID?
    var moveAction: (Int, Int) -> Void
    var assignToAreaAction: ((Project, Area?) -> Void)? = nil
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem else { return }
        
        // Check for area and enable visual feedback
        if let targetItem = items[index] as? Area, let areaId = targetItem.id {
            // Only show feedback when dragging a project onto an area
            if draggedItem is Project {
                isDraggingOver = areaId
            }
        }
        
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
        // Clear the dragging over state
        withAnimation {
            isDraggingOver = nil
        }
        
        // Handle area assignment if we're dropping a project onto an area
        if let project = draggedItem as? Project,
           let targetItem = items[index] as? Area,
           let assignAction = assignToAreaAction {
            assignAction(project, targetItem)
        }
        // Or handle removing from area if we're dropping a project between items
        else if let project = draggedItem as? Project,
                project.area != nil,
                items[index] is Project,
                let assignAction = assignToAreaAction {
            // Check if the destination is a different area's project
            if let destProject = items[index] as? Project, 
               destProject.area != project.area {
                // Set the project to the same area as the destination project
                assignAction(project, destProject.area)
            } else {
                // This is a project being moved out of an area to top level
                assignAction(project, nil)
            }
        }
        
        // Reset the dragged item when the drop is complete
        withAnimation {
            draggedItem = nil
        }
        return true
    }
    
    func dropExited(info: DropInfo) {
        // Clear the dragging over state when we exit
        isDraggingOver = nil
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
    @State private var isDraggingOver: UUID? = nil
    @State private var expandedAreas: [UUID: Bool] = [:]
    
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
        let isDraggingOnto = isDraggingOver == area.id
        
        if isSelected {
            // Selected state - use the lighter shade of area color
            return AppColors.lightenColor(AppColors.getColor(from: area.color), by: 0.7)
        } else if isDraggingOnto {
            // Dragging over state - highlight more strongly to indicate drop target
            return AppColors.lightenColor(AppColors.getColor(from: area.color), by: 0.5)
        } else if isHovered {
            // Hover state - use a very light shade of area color
            return AppColors.lightenColor(AppColors.getColor(from: area.color), by: 0.9)
        } else {
            // Normal state - transparent
            return Color.clear
        }
    }
    
    // Initialize expanded areas state
    private func initializeExpandedAreas() {
        // Initialize all areas to expanded state
        for area in areaViewModel.areas {
            if let areaId = area.id, expandedAreas[areaId] == nil {
                expandedAreas[areaId] = true
            }
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
                        // Use shippingbox for collapsed, cube.fill for expanded
                        if let areaId = area.id {
                            let isExpanded = expandedAreas[areaId, default: true]
                            Image(systemName: isExpanded ? "cube.fill" : "shippingbox")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.getColor(from: area.color ?? "gray"))
                        }
                        
                        Text(area.name ?? "Unnamed Area")
                            .lineLimit(1)
                            .foregroundStyle(selectedViewType == .area && selectedArea?.id == area.id ? AppColors.selectedTextColor : .black)
                            .font(.system(size: 14))
                            
                        Spacer()
                        
                        // Task count badge
                        if area.totalTaskCount > 0 {
                            Text("\(area.totalTaskCount)")
                                .foregroundColor(selectedViewType == .area && selectedArea?.id == area.id ? AppColors.selectedTextColor : .secondary)
                                .font(.system(size: 14))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(backgroundColorFor(area: area))
                    )
                    .overlay(
                        // Show a border when hovering with a project
                        isDraggingOver == area.id ?
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(AppColors.getColor(from: area.color), lineWidth: 1.5)
                            : nil
                    )
                    .onTapGesture {
                        if let areaId = area.id {
                            // Just toggle expansion on tap, without changing selection
                            expandedAreas[areaId] = !(expandedAreas[areaId, default: true])
                            
                            // Don't change the selection on expand/collapse
                            if selectedArea?.id != area.id {
                                selectedViewType = .area
                                selectedArea = area
                            }
                        }
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
                        // Just set the dragged item with no animation
                        self.draggedItem = area
                        return NSItemProvider(object: "area-\(index)" as NSString)
                    }
                    .onDrop(of: [.text], delegate: MixedItemDropDelegate(
                        index: index,
                        items: combinedItems,
                        draggedItem: $draggedItem,
                        isDraggingOver: $isDraggingOver,
                        moveAction: { fromIndex, toIndex in
                            // No animation during reordering
                            reorderItems(from: fromIndex, to: toIndex)
                        },
                        assignToAreaAction: { project, area in
                            assignProjectToArea(project: project, area: area)
                        }
                    ))
                } else if let project = combinedItems[index] as? Project {
                    // Render project row
                    HStack(spacing: 10) {
                        // Add indentation for projects within areas
                        if project.area != nil {
                            Spacer().frame(width: 16) // Indentation for area nesting
                        }
                        
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
                        // Just set the dragged item with no animation
                        self.draggedItem = project
                        return NSItemProvider(object: "project-\(index)" as NSString)
                    }
                    .onDrop(of: [.text], delegate: MixedItemDropDelegate(
                        index: index,
                        items: combinedItems,
                        draggedItem: $draggedItem,
                        isDraggingOver: $isDraggingOver,
                        moveAction: { fromIndex, toIndex in
                            // No animation during reordering
                            reorderItems(from: fromIndex, to: toIndex)
                        },
                        assignToAreaAction: { project, area in
                            assignProjectToArea(project: project, area: area)
                        }
                    ))
                }
            }
        }
        .onAppear {
            // Initialize expanded state for areas
            initializeExpandedAreas()
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
            // Only add projects that don't belong to an area at the top level
            if project.area == nil {
                combinedItems.append((item: project, order: project.displayOrder))
            }
        }
        
        // Sort by display order
        combinedItems.sort { $0.order < $1.order }
        
        // Next, add child projects under their respective areas
        var result: [Any] = []
        
        // First pass - add the main items
        for (item, _) in combinedItems {
            result.append(item)
            
            // If this is an area, add its child projects if area is expanded
            if let area = item as? Area, let areaId = area.id {
                // Only show children if expanded
                if expandedAreas[areaId, default: true] {
                    let childProjects = projectViewModel.projects.filter { $0.area?.id == areaId }
                                                             .sorted { $0.displayOrder < $1.displayOrder }
                    
                    // Add all child projects
                    for project in childProjects {
                        result.append(project)
                    }
                }
            }
        }
        
        return result
    }
    
    // Get all top-level items (areas and projects with no parent area)
    private func getAllTopLevelItems() -> [Any] {
        var result: [Any] = []
        
        // Add all areas
        result.append(contentsOf: areaViewModel.areas)
        
        // Add top-level projects
        for project in projectViewModel.projects {
            if project.area == nil {
                result.append(project)
            }
        }
        
        // Sort by display order
        return result.sorted { 
            let order1 = ($0 as? Area)?.displayOrder ?? ($0 as? Project)?.displayOrder ?? 0
            let order2 = ($1 as? Area)?.displayOrder ?? ($1 as? Project)?.displayOrder ?? 0
            return order1 < order2
        }
    }
    
    // Reorder items within the combined list
    private func reorderItems(from sourceIndex: Int, to destinationIndex: Int) {
        let updatedItems = getCombinedItems()
        
        // Get the item we're moving
        let sourceItem = updatedItems[sourceIndex]
        
        // If source is before destination, we need to adjust destination index
        let adjustedDestIndex = sourceIndex < destinationIndex ? destinationIndex - 1 : destinationIndex
        
        if let area = sourceItem as? Area {
            // Handle area reordering
            area.displayOrder = Int32(adjustedDestIndex * 10)
        } else if let project = sourceItem as? Project {
            // Handle project reordering
            project.displayOrder = Int32(adjustedDestIndex * 10)
        }
        
        // Save context immediately without animations
        do {
            try viewContext.save()
        } catch {
            print("Error saving reordered items: \(error)")
        }
    }
    
    // Assign a project to an area (or remove it from one)
    private func assignProjectToArea(project: Project, area: Area?) {
        // Update the project's area reference
        project.area = area
        
        // Save changes
        do {
            try viewContext.save()
        } catch {
            print("Error assigning project to area: \(error)")
        }
    }
}

// Add the modifier conformance to enable animations
extension View {
    @ViewBuilder
    func animateExpandCollapse(using expandedAreas: [UUID: Bool]) -> some View {
        self.animation(.easeInOut(duration: 0.25), value: expandedAreas)
    }
}

extension ReorderableProjectList {
    var animatedView: some View {
        self.animateExpandCollapse(using: expandedAreas)
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
            .animateExpandCollapse(using: [:])
    }
}
