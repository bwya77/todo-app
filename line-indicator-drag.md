# Line Indicator for Drag and Drop

## Changes Made

1. Modified the drag-and-drop interface to show line indicators instead of full project highlights:
   - Added blue line indicators where items will be placed
   - Matching task reordering visual behavior
   - More minimal, modern approach to reordering UI

2. Improved drag state management:
   - Enhanced the DragState struct with a dropTargetIndex property
   - Added animation when drag starts
   - Better state reset on drop completion

3. Separated preview from execution:
   - Changed the drop interface to show preview indicators during drag
   - Only perform the actual move on drop
   - Provides more visual feedback during the drag operation

4. Color coordination:
   - Used area colors for drop indicators within areas
   - Used consistent highlight colors for standalone projects

This approach creates a cleaner visual experience that feels more modern and is consistent with how task reordering works in the application.
