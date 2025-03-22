# Sidebar Animation Bug Fix

## Bug Description
When collapsing or expanding an area in the sidebar, the entire sidebar (including projects and other areas) would re-adjust, creating a visually jarring experience. The expected behavior is that only the direct children of the expanded/collapsed area should animate while everything else remains stable.

## Root Cause
The issue was caused by applying animations too broadly in the `ReorderableProjectList`. The `.animateExpandCollapse()` modifier was applying animation to the entire view hierarchy, causing all elements to animate when only the expanding/collapsing area elements should be animated.

## Changes Made

1. Removed global animation from the `animateExpandCollapse` extension method:
   - Changed it to be a no-op that simply passes through the view without adding any animations

2. Added targeted animation to the expandable area content:
   - Wrapped the area's child content in its own `VStack`
   - Applied animation and transition directly to this content
   - Used `.transition(.move(edge: .top).combined(with: .opacity))` for a smooth sliding effect

3. Modified area row tap handling:
   - Removed the `withAnimation` call that was animating everything
   - Added explicit `withAnimation(nil)` for selection changes to prevent unwanted animations
   - Let the view hierarchy handle the animation based on the expandedAreas state change

4. Updated drag-and-drop expansion handling:
   - Removed the `withAnimation` call from the area drop delegate
   - Let the view hierarchy handle the animation based on the expandedAreas state change

5. Removed the unnecessary `.animateExpandCollapse` modifier from the `SidebarView`

## Result
Now when expanding or collapsing an area:
- Only the projects within that area will animate in/out
- The rest of the sidebar (other areas, projects outside of areas) will remain stationary
- The animation is smooth and localized to just the elements that need to change

This creates a more natural user experience where only the directly affected elements move while the rest of the UI remains stable.
