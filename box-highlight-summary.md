# Project Drag and Drop Box Highlight Enhancement

## Feature Description
When dragging a project from an area to the projects section (with no area), we now display a visual box highlight around all standalone projects to indicate they're being added to this group.

## Implementation Details

1. Added state variables to track dragging from area to non-area:
   - `isHoveringOverNoAreaSection` - Tracks when hovering over the non-area projects section
   - `isDraggingFromAreaToNoArea` - Tracks when dragging a project from an area to no area

2. Added visual highlighting for standalone projects:
   - Added a RoundedRectangle with stroke and background to the standalone projects section
   - Used conditional styles based on dragging state: 
     ```swift
     .background(
         RoundedRectangle(cornerRadius: 6)
             .stroke(isHoveringOverNoAreaSection || isDraggingFromAreaToNoArea ? AppColors.todayHighlight : Color.clear, lineWidth: 2)
             .background(isHoveringOverNoAreaSection || isDraggingFromAreaToNoArea ? AppColors.todayHighlight.opacity(0.1) : Color.clear)
             .cornerRadius(6)
     )
     ```

3. Added similar visual highlighting for areas:
   - Added the same RoundedRectangle with stroke and background to each area group
   - Used the area's color for highlighting:
     ```swift
     .background(
         RoundedRectangle(cornerRadius: 6)
             .stroke(isDraggingOver == area.id ? AppColors.getColor(from: area.color ?? "blue") : Color.clear, lineWidth: 2)
             .background(isDraggingOver == area.id ? AppColors.getColor(from: area.color ?? "blue").opacity(0.1) : Color.clear)
             .cornerRadius(6)
     )
     ```

4. Updated DropDelegate implementations:
   - Modified the ProjectDropDelegate to highlight the proper area when dragging between areas
   - Added tracking for dragging from area to no area
   - Added state cleanup in performDrop

5. Removed individual project highlight styles:
   - Eliminated the individual project border overlays
   - Changed the background color logic to remove the dragging-specific highlight
   - Consolidated highlighting at the group level for clearer visual feedback

## Result
Now when dragging a project:
- If dragging from an area to the standalone projects section, the entire standalone projects section is highlighted with a blue box
- If dragging to a different area, the entire target area is highlighted with the area's color
- This provides clearer visual feedback about where the project will be moved to

The group-level highlighting makes it more obvious when moving projects between organizational units rather than just reordering within the same group.
