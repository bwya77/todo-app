# Sidebar Area Expand/Collapse Feature Implementation

## Overview

This document provides a technical overview of the implementation of the feature to always show expand/collapse icons for areas when the mouse is hovering anywhere within the sidebar of the To-Do application.

## Implementation Approach

We took a straightforward prop-passing approach for this feature:

1. **SidebarView Hover Detection**:
   - Added an `isSidebarHovered` state variable to track when the mouse enters/exits the sidebar
   - Used SwiftUI's `onHover` modifier to update this state with a smooth animation
   
2. **Prop-Passing Pattern**:
   - Passed the hover state down through the component hierarchy
   - SidebarView → ReorderableProjectList → AreaRowView
   - Each component accepts and passes the state as a simple boolean property
   
3. **Conditional UI Rendering**:
   - Modified AreaRowView to show/hide elements based on the sidebar hover state
   - Combined with existing local hover states for smooth transitions

## Key Files Modified

1. **SidebarView.swift**:
   - Added the `isSidebarHovered` state variable
   - Added hover detection to update this state
   - Passed the state to ReorderableProjectList

2. **ReorderableProjectList.swift**:
   - Added an `isSidebarHovered` parameter
   - Enhanced the init method to accept this parameter
   - Passed the parameter to each AreaRowView in the renderAreaRow method

3. **AreaRowView.swift**:
   - Added an `isSidebarHovered` parameter 
   - Updated the opacity logic for task counts and expand/collapse icons
   - Maintained existing functionality for expanded areas and areas with 0 tasks

## Testing

We created comprehensive tests to verify all expected behaviors:

- When the sidebar is hovered, expand/collapse icons are visible for all areas
- When an area is expanded, only the collapse icon is shown
- For areas with zero tasks, expand/collapse icon is always visible
- For collapsed areas with tasks, task count is shown by default when not hovering

## Benefits of Our Approach

1. **Simplicity**: Direct prop passing without complex global state management
2. **Performance**: No unnecessary observers or publishers that could cause rerenders
3. **Maintainability**: Clear component hierarchy with explicit dependencies
4. **Testability**: Easy to test with component isolation

## Future Improvements

Potential enhancements to consider:

- Add smoother transitions between task count and expand/collapse icon
- Consider adding tooltip hints for new users
- Explore keyboard shortcuts for expanding/collapsing all areas at once
