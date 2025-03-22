# Sidebar Animation Bug Fix

## Bug Description
When collapsing or expanding an area in the sidebar, the entire sidebar (including projects and area titles) would re-adjust, creating a visually jarring experience. We wanted to limit the animation so that only the sub-items slide in/out while everything else remains stable.

## Root Cause
The issue was caused by applying animations globally to the entire view hierarchy. The `.animateExpandCollapse(using: [:])` modifier in SidebarView was affecting all elements in the view, causing everything to animate when only the expanding/collapsing area elements should be animated.

## Changes Made

1. Modified the `ReorderableProjectList` structure to apply targeted animations only where needed:
   - Changed the area's child content structure in `body` to use a nested VStack
   - Wrapped area child items in their own VStack
   - Added `.transition(.move(edge: .top).combined(with: .opacity))` only to the expanding/collapsing content
   - Applied animation modifiers only to the specific content that should animate: 
     `.animation(.easeInOut(duration: 0.25), value: expandedAreas[areaId, default: true])`

2. Modified the `renderAreaRow` tap handler to prevent global animations:
   - Removed the global `withAnimation` call
   - Added `withAnimation(nil)` specifically for selection changes to prevent them from animating

3. Updated the area drag-and-drop handling in `ProjectListAreaDropDelegate`:
   - Removed the animation from the drop handler to let the animation be controlled by the view structure

4. Modified the animation extension to be a no-op:
   - Changed the `animateExpandCollapse` extension method to simply return the view without applying any animation
   - This prevents accidental application of animations at the global level

## Result
Now when expanding or collapsing an area:
- Only the projects within that area will animate in/out with a smooth transition
- The rest of the sidebar (other areas, standalone projects, section titles) will remain stationary
- The animation is smooth and localized only to the elements that should be animated

This creates a more polished user experience where only the relevant content animates while the overall sidebar layout remains stable.
