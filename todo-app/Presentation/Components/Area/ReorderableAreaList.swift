//
//  ReorderableAreaList.swift
//  todo-app
//
//  Created on 3/22/25.
//

import SwiftUI
import CoreData

/// Custom drop delegate for area reordering
struct AreaDropDelegate: DropDelegate {
    let item: Area
    var items: [Area]
    @Binding var draggedItem: Area?
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

/// A reorderable list of areas that supports drag and drop reordering
struct ReorderableAreaList: View {
    /// Selected view type
    @Binding var selectedViewType: ViewType
    
    /// Selected area
    @Binding var selectedArea: Area?
    
    /// The view model for area reordering
    @StateObject private var viewModel = AreaReorderingViewModel()
    
    /// The currently active (being dragged) area
    @State private var activeArea: Area? = nil
    
    // State for drag and hover tracking
    @State private var hoveredArea: Area? = nil
    @State private var draggingArea: Area? = nil
    
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
        VStack(spacing: 6) { // Add spacing between areas
            ForEach(viewModel.areas, id: \.id) { area in
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
                    self.draggingArea = area
                    return NSItemProvider(object: "\(viewModel.areas.firstIndex(of: area) ?? 0)" as NSString)
                }
                .onDrop(of: [.text], delegate: AreaDropDelegate(
                    item: area,
                    items: viewModel.areas,
                    draggedItem: $draggingArea,
                    moveAction: { fromIndex, toIndex in
                        viewModel.reorderAreas(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex)
                    }
                ))
            }
        }
    }
}

// AreaRowView is now in a separate file: AreaRowView.swift

// Preview provider for SwiftUI canvas
struct ReorderableAreaList_Previews: PreviewProvider {
    static var previews: some View {
        ReorderableAreaList(
            selectedViewType: .constant(.area),
            selectedArea: .constant(nil)
        )
        .frame(width: 250, height: 400)
    }
}
