//
//  ReorderableProjectList.swift
//  todo-app
//
//  Created on 3/20/25.
//

import SwiftUI
import CoreData

struct DragState {
    var isDragging: Bool = false
    var draggedProject: Project?
    var draggedArea: Area?
    var isDraggingOver: UUID? = nil
    var isHoveringOverNoAreaSection: Bool = false
    var isDraggingFromAreaToNoArea: Bool = false
    var dropTargetIndex: Int? = nil  // Store the index where item would be dropped
    var lastPosition: CGPoint?
    
    // Reset all drag state
    mutating func reset() {
        isDragging = false
        draggedProject = nil
        draggedArea = nil
        isDraggingOver = nil
        isHoveringOverNoAreaSection = false
        isDraggingFromAreaToNoArea = false
        dropTargetIndex = nil
        lastPosition = nil
    }
}

/// Project drop delegate for efficient project-to-project reordering
struct ProjectDropDelegate: DropDelegate {
    let project: Project
    var projects: [Project]
    @Binding var draggedProject: Project?
    @Binding var isDraggingOver: UUID?
    @Binding var isHoveringOverNoAreaSection: Bool
    @Binding var isDraggingFromAreaToNoArea: Bool
    var moveAction: (Int, Int) -> Void
    var removeFromAreaAction: (Project) -> Void
    var assignToAreaAction: (Project, Project) -> Void
    
    func dropEntered(info: DropInfo) {
        guard let draggedProject = draggedProject else { return }
        guard draggedProject.id != project.id else { return }
        
        // Find the indices for the move operation
        guard let fromIndex = projects.firstIndex(where: { $0.id == draggedProject.id }),
              let toIndex = projects.firstIndex(where: { $0.id == project.id }) else { return }
        
        // Store the drop target index in state but don't actually move yet
        withAnimation(nil) {
            isDraggingOver = project.id // Just highlight the target
        }
        
        // Highlight target area if it's a different area
        if draggedProject.area != project.area, let projectAreaId = project.area?.id {
            withAnimation(nil) {
                isDraggingOver = projectAreaId
            }
        }
    }
    
    func dropExited(info: DropInfo) {
        withAnimation(nil) {
            isDraggingOver = nil
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedProject = draggedProject else { return false }
        
        // Find the indices for the actual move operation
        guard let fromIndex = projects.firstIndex(where: { $0.id == draggedProject.id }),
              let toIndex = projects.firstIndex(where: { $0.id == project.id }) else { return false }
        
        // Now actually perform the move with animation
        moveAction(fromIndex, toIndex)
        
        // If dragging to a standalone project with no area
        if project.area == nil {
            // Remove from area if coming from an area
            if draggedProject.area != nil {
                removeFromAreaAction(draggedProject)
            }
        }
        // If dragging between different areas
        else if draggedProject.area != project.area {
            // Assign to target project's area
            assignToAreaAction(draggedProject, project)
        }
        
        // Reset all drag state
        withAnimation(nil) {
            isDraggingOver = nil
            isHoveringOverNoAreaSection = false
            isDraggingFromAreaToNoArea = false
            self.draggedProject = nil
        }
        
        return true
    }
}

/// Area drop delegate for efficient area-to-area reordering in project list
struct ProjectListAreaDropDelegate: DropDelegate {
    let area: Area
    var areas: [Area]
    @Binding var draggedArea: Area?
    @Binding var draggedProject: Project?
    @Binding var expandedAreas: [UUID: Bool]
    @Binding var areaBeingDragged: UUID?
    @Binding var isDraggingOver: UUID?
    var moveAction: (Int, Int) -> Void
    var assignProjectAction: (Project, Area) -> Void
    
    func dropEntered(info: DropInfo) {
        // Handle area dragging
        if let draggedArea = draggedArea, draggedArea.id != area.id {
            // Find the indices for the move operation
            guard let fromIndex = areas.firstIndex(where: { $0.id == draggedArea.id }),
                  let toIndex = areas.firstIndex(where: { $0.id == area.id }) else { return }
            
            // Perform the move without animation
            moveAction(fromIndex, toIndex)
        }
        
        // Handle project dragging - highlight area
        if draggedProject != nil, let areaId = area.id {
            withAnimation(nil) {
                isDraggingOver = areaId
            }
        }
    }
    
    func dropExited(info: DropInfo) {
        // Clear highlight without animation
        withAnimation(nil) {
            isDraggingOver = nil
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        // Handle area drop
        if let areaId = areaBeingDragged, let wasExpanded = expandedAreas[areaId] {
            // Re-expand the area that was being dragged
            // The animation is now controlled in the view hierarchy
            expandedAreas[areaId] = wasExpanded
            areaBeingDragged = nil
            draggedArea = nil
        }
        
        // Handle project drop into area
        if let project = draggedProject {
            assignProjectAction(project, area)
            draggedProject = nil
        }
        
        // Clear the dragging over state
        isDraggingOver = nil
        
        return true
    }
}

/// Container drop delegate for dropping into empty space (to remove from area)
struct EmptySpaceDropDelegate: DropDelegate {
    @Binding var draggedProject: Project?
    @Binding var isDraggingOver: UUID?
    @Binding var isHoveringOverNoAreaSection: Bool
    @Binding var isDraggingFromAreaToNoArea: Bool
    var removeFromAreaAction: (Project) -> Void
    
    func dropEntered(info: DropInfo) {
        if let project = draggedProject, project.area != nil {
            withAnimation(nil) {
                // Use a special value to indicate hovering over empty space
                isDraggingOver = UUID(uuidString: "00000000-0000-0000-0000-000000000000")
                // Set flag to show outline around no-area projects section
                isHoveringOverNoAreaSection = true
                isDraggingFromAreaToNoArea = true
            }
        }
    }
    
    func dropExited(info: DropInfo) {
        withAnimation(nil) {
            isDraggingOver = nil
            isHoveringOverNoAreaSection = false
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        // If dropping a project into empty space, remove it from its area
        if let project = draggedProject, project.area != nil {
            removeFromAreaAction(project)
            draggedProject = nil
            isDraggingOver = nil
            isHoveringOverNoAreaSection = false
            isDraggingFromAreaToNoArea = false
            return true
        }
        return false
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
    
    // Add state for tracking drag animations
    @State private var dragState = DragState()
    
    // State for drag and hover tracking
    @State private var hoveredProject: Project? = nil
    @State private var hoveredArea: Area? = nil
    @State private var draggedProject: Project? = nil
    @State private var draggedArea: Area? = nil
    @State private var isDraggingOver: UUID? = nil
    @State private var expandedAreas: [UUID: Bool] = [:]
    @State private var areaBeingDragged: UUID? = nil
    @State private var expandedStateBeforeDrag: Bool = true
    @State private var isHoveringOverNoAreaSection: Bool = false
    @State private var isDraggingFromAreaToNoArea: Bool = false
    
    // Cache animations and transitions - using simpler animations to prevent layout issues
    private let expandTransition = AnyTransition.opacity
    private let expandAnimation = Animation.easeInOut(duration: 0.2)
    private let dragAnimation = Animation.easeInOut(duration: 0.2)
    private func backgroundColorFor(project: Project) -> Color {
        let isSelected = selectedViewType == .project && selectedProject?.id == project.id
        let isHovered = hoveredProject?.id == project.id
        let emptySpaceUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")
        let isDraggingToEmptySpace = isDraggingOver == emptySpaceUUID && draggedProject?.id == project.id
        
        if isSelected {
            // Selected state - use the lighter shade of project color
            return AppColors.lightenColor(AppColors.getColor(from: project.color), by: 0.7)
        } else if isHovered || isDraggingToEmptySpace {
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
        VStack(spacing: 6) {
            // Standalone projects first with optional border
            VStack(spacing: 6) {
                ForEach(projectViewModel.projects.filter { $0.area == nil }, id: \.id) { project in
                    renderProjectRow(project: project)
                    
                    // Add drop indicator line if this is where we're dragging
                    if draggedProject != nil && isDraggingOver == project.id {
                        Rectangle()
                            .fill(AppColors.todayHighlight)
                            .frame(height: 2)
                            .padding(.horizontal, 10)
                            .transition(.opacity)
                    }
                }
            }
            .padding((isHoveringOverNoAreaSection || isDraggingFromAreaToNoArea) ? 4 : 0)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isHoveringOverNoAreaSection || isDraggingFromAreaToNoArea ? AppColors.todayHighlight : Color.clear, lineWidth: 2)
                    .background(isHoveringOverNoAreaSection || isDraggingFromAreaToNoArea ? AppColors.todayHighlight.opacity(0.1) : Color.clear)
                    .cornerRadius(6)
            )
            
            if !projectViewModel.projects.filter({ $0.area == nil }).isEmpty && !areaViewModel.areas.isEmpty {
                Spacer().frame(height: 16)
            }
            
            // Then areas with their child projects
            ForEach(areaViewModel.areas, id: \.id) { area in
                VStack(spacing: 6) {
                    renderAreaRow(area: area)
                    
                    if let areaId = area.id {
                        if expandedAreas[areaId, default: true] {
                            // No transition or animation for the project content
                            // Just show/hide the projects instantly
                            VStack(spacing: 6) {
                                ForEach(projectViewModel.projects.filter { $0.area?.id == areaId }, id: \.id) { project in
                                    renderProjectRow(project: project)
                                    
                                    // Add drop indicator line if this is where we're dragging
                                    if draggedProject != nil && isDraggingOver == project.id {
                                        Rectangle()
                                            .fill(AppColors.getColor(from: area.color ?? "blue"))
                                            .frame(height: 2)
                                            .padding(.horizontal, 10)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(isDraggingOver == area.id ? 4 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isDraggingOver == area.id ? AppColors.getColor(from: area.color ?? "blue") : Color.clear, lineWidth: 2)
                        .background(isDraggingOver == area.id ? AppColors.getColor(from: area.color ?? "blue").opacity(0.1) : Color.clear)
                        .cornerRadius(6)
                )
            }
        }
        .onDrop(of: [.text], delegate: EmptySpaceDropDelegate(
            draggedProject: $draggedProject,
            isDraggingOver: $isDraggingOver,
            isHoveringOverNoAreaSection: $isHoveringOverNoAreaSection,
            isDraggingFromAreaToNoArea: $isDraggingFromAreaToNoArea,
            removeFromAreaAction: { project in
                assignProjectToArea(project: project, area: nil)
            }
        ))
        .onAppear {
            initializeExpandedAreas()
        }
    }
    
    // Helper method to render an area row
    @ViewBuilder
    private func renderAreaRow(area: Area) -> some View {
        HStack(spacing: 10) {
            // Icon for the area type
            if let areaId = area.id {
                let isExpanded = expandedAreas[areaId, default: true]
                Image(systemName: isExpanded ? "cube" : "shippingbox.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.getColor(from: area.color ?? "gray"))
            }
            
            Text(area.name ?? "Unnamed Area")
                .lineLimit(1)
                .foregroundStyle(selectedViewType == .area && selectedArea?.id == area.id ? AppColors.selectedTextColor : .black)
                .font(.system(size: 14, weight: .bold))
                
            Spacer()
            
            // Task count badge
            if area.totalTaskCount > 0 {
                Text("\(area.totalTaskCount)")
                    .foregroundColor(selectedViewType == .area && selectedArea?.id == area.id ? AppColors.selectedTextColor : .secondary)
                    .font(.system(size: 14))
            }
            
            // Add caret icon to indicate expanded/collapsed state
            if let areaId = area.id {
                let isExpanded = expandedAreas[areaId, default: true]
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
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
        // Replaced the overlay with a group-level background
        .onTapGesture {
            if let areaId = area.id {
                // Toggle expansion on tap with no animation
                // This ensures nothing bounces or jiggles
                expandedAreas[areaId] = !(expandedAreas[areaId, default: true])
                
                // Don't change the selection on expand/collapse
                if selectedArea?.id != area.id {
                    // Use withAnimation(nil) to disable animations for selection changes
                    withAnimation(nil) {
                        selectedViewType = .area
                        selectedArea = area
                    }
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
            // Set the dragged area and remember expanded state
            if let areaId = area.id {
                // Set the dragged area using optimized state update
                updateAreaDragState(area: area, areaId: areaId)
                
                // Collapse the area during drag with no animation
                expandedAreas[areaId] = false
            }
            return NSItemProvider(object: "area-\(area.id?.uuidString ?? "")" as NSString)
        }
        .onDrop(of: [.text], delegate: ProjectListAreaDropDelegate(
            area: area,
            areas: areaViewModel.areas,
            draggedArea: $draggedArea,
            draggedProject: $draggedProject,
            expandedAreas: $expandedAreas,
            areaBeingDragged: $areaBeingDragged,
            isDraggingOver: $isDraggingOver,
            moveAction: { fromIndex, toIndex in
                reorderAreas(from: fromIndex, to: toIndex)
            },
            assignProjectAction: { project, area in
                assignProjectToArea(project: project, area: area)
            }
        ))
    }
    
    // Helper method to render a project row
    @ViewBuilder
    private func renderProjectRow(project: Project) -> some View {
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
        // No longer showing individual project borders - we use group borders instead
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
            // Set the dragged project with no animation
            dragState.isDragging = true
            updateDragState(project: project)
            return NSItemProvider(object: "project-\(project.id?.uuidString ?? "")" as NSString)
        }
        .onDrop(of: [.text], delegate: ProjectDropDelegate(
            project: project,
            projects: projectViewModel.projects,
            draggedProject: $draggedProject,
            isDraggingOver: $isDraggingOver,
            isHoveringOverNoAreaSection: $isHoveringOverNoAreaSection,
            isDraggingFromAreaToNoArea: $isDraggingFromAreaToNoArea,
            moveAction: { fromIndex, toIndex in
                reorderProjects(from: fromIndex, to: toIndex)
            },
            removeFromAreaAction: { project in
                assignProjectToArea(project: project, area: nil)
            },
            assignToAreaAction: { draggedProject, targetProject in
                // Assign to the same area as the target project
                assignProjectToArea(project: draggedProject, area: targetProject.area)
            }
        ))
    }
    
    // Use performant batch update for state changes during drag
    private func updateDragState(project: Project?, isDragging: Bool = false, highlightArea: UUID? = nil) {
        withAnimation(nil) {
            self.draggedProject = project
            self.isDraggingOver = highlightArea
            if project == nil {
                self.isHoveringOverNoAreaSection = false
                self.isDraggingFromAreaToNoArea = false
            }
        }
    }
    
    // Reorder projects efficiently
    private func reorderProjects(from sourceIndex: Int, to destinationIndex: Int) {
        // Disable animations during reordering
        withAnimation(nil) {
            Project.reorderProjects(
                from: sourceIndex,
                to: destinationIndex,
                projects: projectViewModel.projects,
                context: viewContext,
                notifyOrderChange: false // We'll handle the refresh ourselves
            )
        }
        
        // Force a UI refresh using a dispatch async for better performance
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceUIRefresh"),
                object: nil
            )
        }
    }
    
    // Reorder areas efficiently
    private func reorderAreas(from sourceIndex: Int, to destinationIndex: Int) {
        // Disable animations during reordering
        withAnimation(nil) {
            // Get all areas
            let areas = areaViewModel.areas
            
            // Get the area being moved
            let areaToMove = areas[sourceIndex]
            
            // Create a mutable copy of the areas array
            var mutableAreas = areas
            
            // Remove the area from its current position
            mutableAreas.remove(at: sourceIndex)
            
            // Insert the area at the new position
            mutableAreas.insert(areaToMove, at: destinationIndex)
            
            // Update display orders - use 10-spacing for future insertions
            for (index, area) in mutableAreas.enumerated() {
                area.setValue(Int32(index * 10), forKey: "displayOrder")
            }
            
            // Save changes directly
            do {
                try viewContext.save()
            } catch {
                // Silent error handling for performance
            }
        }
        
        // Force a UI refresh using a dispatch async for better performance
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceUIRefresh"),
                object: nil
            )
        }
    }
    
    // Efficient method to update area drag state
    private func updateAreaDragState(area: Area?, areaId: UUID? = nil) {
        withAnimation(nil) {
            self.draggedArea = area
            if let id = areaId {
                self.areaBeingDragged = id
                expandedStateBeforeDrag = expandedAreas[id, default: true]
            } else {
                self.areaBeingDragged = nil
            }
        }
    }
    
    private func assignProjectToArea(project: Project, area: Area?) {
        // Update the project's area reference
        project.area = area
        
        // Save changes directly
        do {
            try viewContext.save()
            
            // Use batch updates to avoid multiple refreshes
            withAnimation(nil) {
                draggedProject = nil
                isDraggingOver = nil
                isHoveringOverNoAreaSection = false
                isDraggingFromAreaToNoArea = false
            }
                
            // Use a dispatch async to improve perceived performance
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ForceUIRefresh"),
                    object: nil
                )
            }
        } catch {
            // Silent error handling for performance
        }
    }
}

// Add the modifier conformance to enable animations but only for the expanding/collapsing elements
extension View {
    @ViewBuilder
    func animateExpandCollapse(using expandedAreas: [UUID: Bool]) -> some View {
        // We don't apply animation at this level anymore
        // Instead, we apply it directly to the child content that needs to animate
        self
    }
}

extension ReorderableProjectList {
    var animatedView: some View {
        self
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

// Preview provider for SwiftUI canvas
struct ReorderableProjectList_Previews: PreviewProvider {
    static var previews: some View {
        ReorderableProjectList()
            .frame(width: 250, height: 400)
    }
}
