# Project Reordering Implementation

## Overview

This feature enhances the Sidebar view to support drag-and-reorder functionality for projects, making it consistent with the existing task reordering capability. Users can now arrange projects in any order they prefer rather than being limited to alphabetical sorting.

## Implementation Details

Projects are displayed in a reorderable list in the sidebar, with smooth animations for drag-and-drop operations. The custom order is persisted across app launches.

### Key Components:

1. **DisplayOrder Attribute**: Added `displayOrder` attribute to the Project entity to track custom ordering.

2. **Reorderable Project List**: Created a specialized component (`ReorderableProjectList`) that handles drag-and-drop reordering.

3. **Project Reordering ViewModel**: Dedicated view model to manage project ordering operations.

4. **Persistent Storage**: Order changes are saved to Core Data with enhanced reliability.

5. **Reset Capability**: Added button to reset project order to alphabetical if desired.

## Technical Implementation

1. **Entity Extensions**:
   - Extended the CoreData model to add `displayOrder` to Project entities
   - Added utility methods to manage project order

2. **Reordering Logic**:
   - Reused the same drag-and-drop infrastructure developed for tasks
   - Implemented proper spacing (10-point increments) to allow for future insertions

3. **UI Components**:
   - ReorderableProjectList.swift - The main component that handles the UI
   - ProjectReorderingViewModel.swift - Manages the ordering logic and persistence

## Benefits

- **Improved Personalization**: Users can arrange projects in their preferred order
- **Workflow Optimization**: Most important or frequently used projects can be placed at the top
- **Consistent UX**: Same user experience as task reordering
- **Visual Organization**: Projects can be grouped logically rather than alphabetically

## Testing

To test this feature:

1. Create several projects in the app
2. Drag projects to different positions in the sidebar
3. Verify the animations are smooth and the UI updates correctly
4. Restart the app and confirm the custom order is maintained
5. Try the "Reset to Alphabetical Order" button to verify it works properly

## Future Enhancements

Potential future improvements:

- Add project grouping/folders to further organize projects
- Support keyboard shortcuts for reordering
- Add visual separator lines to allow manual grouping
- Implement "favorites" section at the top

## Related Components

- Task reordering (shares same infrastructure)
- Project entity model
- Sidebar navigation
