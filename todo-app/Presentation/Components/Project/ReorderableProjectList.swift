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
        isDraggingOver = nil
        
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
        draggedItem = nil
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
                    .overlay(
                        // Show a border when hovering with a project
                        isDraggingOver == area.id ?
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(AppColors.getColor(from: area.color), lineWidth: 1.5)
                            : nil
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
                        isDraggingOver: $isDraggingOver,
                        moveAction: { fromIndex, toIndex in
                            withAnimation {
                                reorderItems(from: fromIndex, to: toIndex)
                            }
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
                        self.draggedItem = project
                        return NSItemProvider(object: "project-\(index)" as NSString)
                    }
                    .onDrop(of: [.text], delegate: MixedItemDropDelegate(
                        index: index,
                        items: combinedItems,
                        draggedItem: $draggedItem,
                        isDraggingOver: $isDraggingOver,
                        moveAction: { fromIndex, toIndex in
                            withAnimation {
                                reorderItems(from: fromIndex, to: toIndex)
                            }
                        },
                        assignToAreaAction: { project, area in
                            assignProjectToArea(project: project, area: area)
                        }
                    ))
                }
            }
        }
    }
    
    // Helper method to get combined list of areas and projects sorted by displayOrder
    private func getCombinedItems() -> [Any] {
        var combinedItems: [(item: Any, order: Int32, level: Int)] = []
        
        // Dictionary to keep track of areas by ID for quick lookup
        var areaMap: [UUID: Area] = [:]
        
        // Add areas with their display order
        for area in areaViewModel.areas {
            if let areaId = area.id {
                combinedItems.append((item: area, order: area.displayOrder, level: 0))
                areaMap[areaId] = area
            }
        }
        
        // Sort items so far by display order (just areas at this point)
        combinedItems.sort { $0.order < $1.order }
        
        // Add projects, keeping track of which area they belong to
        var projectsByArea: [UUID?: [(Project, Int32)]] = [:]
        
        // Group projects by area ID
        for project in projectViewModel.projects {
            let areaId = project.area?.id
            let existingProjects = projectsByArea[areaId] ?? []
            projectsByArea[areaId] = existingProjects + [(project, project.displayOrder)]
        }
        
        // Sort projects by display order within each area
        for (areaId, projects) in projectsByArea {
            projectsByArea[areaId] = projects.sorted(by: { $0.1 < $1.1 })
        }
        
        // Now build a new combined array that puts projects under their areas
        var result: [(item: Any, order: Int32, level: Int)] = []
        
        // For each area in the sorted list
        for (item, order, _) in combinedItems {
            if let area = item as? Area, let areaId = area.id {
                // Add the area
                result.append((item: area, order: order, level: 0))
                
                // Add all projects belonging to this area with indentation
                if let projects = projectsByArea[areaId] {
                    for (project, projectOrder) in projects {
                        result.append((item: project, order: projectOrder, level: 1))
                    }
                }
            }
        }
        
        // Add any projects not in areas
        if let projectsWithoutArea = projectsByArea[nil] {
            for (project, projectOrder) in projectsWithoutArea {
                result.append((item: project, order: projectOrder, level: 0))
            }
        }
        
        // Return just the items - we'll use the level for indentation
        return result.map { $0.item }
    }
    
    // Reorder items within the combined list
    private func reorderItems(from sourceIndex: Int, to destinationIndex: Int) {
        let updatedItems = getCombinedItems()
        
        // Get the items we're moving
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
    
    // Assign a project to an area (or remove it from one)
    private func assignProjectToArea(project: Project, area: Area?) {
        // Update the project's area reference
        project.area = area
        
        // Save changes
        do {
            try viewContext.save()
            
            // Refresh data
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.projectViewModel.fetchProjects()
                self.areaViewModel.fetchAreas()
            }
        } catch {
            print("Error assigning project to area: \(error)")
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
