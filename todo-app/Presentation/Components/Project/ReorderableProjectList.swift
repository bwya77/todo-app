//
//  ReorderableProjectList.swift
//  todo-app
//
//  Created on 3/20/25.
//

import SwiftUI
import CoreData

/// Drag state for manual reordering implementation
enum DragState {
    case inactive
    case dragging
    case moving(fromIndex: Int, toIndex: Int)
}

/// Custom drop delegate for project reordering
struct ProjectDropDelegate: DropDelegate {
    let item: Project
    var items: [Project]
    @Binding var draggedItem: Project?
    var moveAction: (Int, Int) -> Void
    
    func dropEntered(info: DropInfo) {
        // Only proceed if we have a dragged item that's different from the current one
        guard let draggedItem = draggedItem else { return }
        guard draggedItem != item else { return }
        
        // Find the indices for the move operation
        guard let fromIndex = items.firstIndex(of: draggedItem),
              let toIndex = items.firstIndex(of: item) else { return }
        
        // Perform the move
        moveAction(fromIndex, toIndex)
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        // Reset the dragged item when the drop is complete
        draggedItem = nil
        return true
    }
}

/// A reorderable list of projects that supports drag and drop reordering
struct ReorderableProjectList: View {
    /// Selected view type
    @Binding var selectedViewType: ViewType
    
    /// Selected project
    @Binding var selectedProject: Project?
    
    /// Initialize with selections
    /// - Parameters:
    ///   - selectedViewType: Binding to the selected view type
    ///   - selectedProject: Binding to the selected project
    init(selectedViewType: Binding<ViewType> = .constant(.project),
         selectedProject: Binding<Project?> = .constant(nil)) {
        self._selectedViewType = selectedViewType
        self._selectedProject = selectedProject
    }
    
    /// The view model for project reordering
    @StateObject private var viewModel = ProjectReorderingViewModel()
    
    /// The currently active (being dragged) project
    @State private var activeProject: Project? = nil
    
    /// Whether to show completed projects
    @State private var showCompletedProjects = false
    
    // State for drag and hover tracking
    @State private var hoveredProject: Project? = nil
    @State private var draggingProject: Project? = nil
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.projects, id: \.id) { project in
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
                    self.draggingProject = project
                    return NSItemProvider(object: "\(viewModel.projects.firstIndex(of: project) ?? 0)" as NSString)
                }
                .onDrop(of: [.text], delegate: ProjectDropDelegate(
                    item: project,
                    items: viewModel.projects,
                    draggedItem: $draggingProject,
                    moveAction: { fromIndex, toIndex in
                        viewModel.reorderProjects(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex)
                    }
                ))
            }
        }
        .padding(.horizontal, 6)
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
